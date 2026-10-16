# Pack this bundle into an npm-style tarball for a copy-based install:
# `plugin_manager install_bundle` with the .tgz path installs an extracted copy
# into the profile, so this folder may then be deleted or moved freely.
#
# Prefers pnpm (PATH, then $env:DSH_PNPM, then the DeepSeek Harness install) and
# falls back to a tar with the npm-required `package/` prefix.
#
# Usage: powershell -File scripts\pack.ps1   (pwsh -File works too)

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$packageDir = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$manifest = Get-Content (Join-Path $packageDir 'package.json') -Raw | ConvertFrom-Json
# pnpm's own naming for a scoped package: `@local/dsh-context-usage` -> `local-dsh-context-usage`.
$bareName = $manifest.name -replace '^@', '' -replace '/', '-'
$tarball = Join-Path $packageDir ('{0}-{1}.tgz' -f $bareName, $manifest.version)

if (Test-Path $tarball) { Remove-Item -LiteralPath $tarball -Force }

$pnpm = $null
$candidates = @(
  (Get-Command pnpm -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Source -ErrorAction SilentlyContinue),
  $env:DSH_PNPM,
  (Join-Path $env:LOCALAPPDATA 'Programs\DeepSeek Harness\resources\runtime\pnpm\bin\pnpm.mjs')
)
foreach ($candidate in $candidates) {
  if ($candidate -and (Test-Path -LiteralPath $candidate)) { $pnpm = $candidate; break }
}

if ($pnpm) {
  Write-Host "pack: using $pnpm"
  Push-Location $packageDir
  try {
    if ($pnpm.EndsWith('.mjs')) { & node $pnpm pack }
    else { & $pnpm pack }
  }
  finally { Pop-Location }
}

if (-not (Test-Path -LiteralPath $tarball)) {
  $tar = Get-Command tar -ErrorAction SilentlyContinue
  if (-not $tar) { throw "pack: neither pnpm nor tar could produce $tarball" }
  Write-Host 'pack: falling back to tar'
  $stage = Join-Path ([System.IO.Path]::GetTempPath()) ('dsh-pack-' + [Guid]::NewGuid().ToString('N'))
  $inner = Join-Path $stage 'package'
  New-Item -ItemType Directory -Path $inner -Force | Out-Null
  try {
    foreach ($entry in $manifest.files) {
      foreach ($item in Get-ChildItem -Path (Join-Path $packageDir $entry) -Force) {
        Copy-Item -LiteralPath $item.FullName -Destination $inner -Recurse -Force
      }
    }
    & tar -czf $tarball -C $stage package
    if ($LASTEXITCODE -ne 0) { throw "pack: tar exited with $LASTEXITCODE" }
  }
  finally { Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue }
}

Write-Host "pack: wrote $tarball"
Write-Host "pack: install it with plugin_manager install_bundle target=$tarball"
