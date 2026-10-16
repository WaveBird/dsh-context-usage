/**
 * Host half of the `@local/dsh-context-usage` bundle.
 *
 * The Client module owns everything: it contributes the `/context` command to
 * the composer menu and renders the occupancy panel. A Client-owned command
 * carries its own localized title, description, and icon, which a Host command
 * cannot (`dsh-client-ui-commands` selects Host row faces by first-party
 * identity only) — and a Host command of the same name would be both an
 * unremovable second menu row and a hard collision with the contribution.
 *
 * This half therefore registers nothing and exists only because a bundle row
 * names the package's host entry.
 */

/** Cordis plugin identity. */
export const name = 'dsh-context-usage'

/** Host half of the bundle; the Client module owns the command and its panel. */
export function apply() {}
