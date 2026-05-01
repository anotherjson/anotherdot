# opencode

[opencode] TUI agent config. Stowed normally — drop with `dots stow opencode`
(links `.config/opencode` into `~/.config/opencode`).

[opencode]: https://opencode.ai

## Provider & model

Pinned to **`opencode/big-pickle`** — a free, no-account model from opencode's
bundled pool (Anthropic-backed, 200K context, $0). No `/connect` step needed,
no API key, no env var: opencode reaches the bundled free pool out of the
box.

Run `opencode models` to see the current free pool. The free roster rotates;
if `big-pickle` ever drops out, pick another `opencode/*` model and update
`opencode.json`.

Other free siblings as of writing: `gpt-5-nano`, `hy3-preview-free`,
`ling-2.6-flash-free`, `minimax-m2.5-free`, `nemotron-3-super-free`.

## Layout

| Path | What it is |
|------|------------|
| `.config/opencode/opencode.json` | Main config — pinned model, privacy hardening |
| `.config/opencode/tui.json` | TUI settings — theme selection |
| `.config/opencode/themes/solarized-osaka.json` | Custom Solarized Osaka theme |

## Privacy hardening

Set in `opencode.json`:

| Key | Value | Why |
|-----|-------|-----|
| `share` | `"disabled"` | No accidental `/share` uploads |
| `autoupdate` | `false` | Disabled — opencode is pacman-managed (`extra/opencode`); in-binary updates would conflict |
| `snapshot` | `false` | Skip per-session snapshots (saves disk on large repos) |

## Theme

Custom Solarized Osaka theme at
`.config/opencode/themes/solarized-osaka.json`. Palette converged to match
the rest of the desktop UI (`gtk/`, `waybar/`, `wofi/`, `swaync/`):
[Solarized Osaka]'s dark teal `#00141A` background plus the **stock
[Solarized] accent set** (`#268BD2` blue, `#2AA198` cyan, `#859900` green,
`#B58900` yellow, `#DC322F` red, `#D33682` magenta, `#6C71C4` violet).

The kitty terminal config uses brighter, more saturated variants of those
accents for ANSI text rendering — that's a separate role. UI tools across
this repo use the stock Solarized accents above for coherent surfaces and
status indicators.

`background` is set to `none` so kitty's transparency shows through,
matching nvim and the claude statusline. Surfaces (`base02 #073642`,
`base01 #586E75`) match `gtk` popover/card/sidebar tiers.

[Solarized Osaka]: https://github.com/craftzdog/solarized-osaka.nvim
[Solarized]: https://ethanschoonover.com/solarized/

## Auto-generated files (gitignored)

opencode writes `node_modules/`, `package.json`, `package-lock.json`, and
`bun.lock` into `~/.config/opencode/` for plugin loading. They live alongside
the symlinked configs but are not managed here — the top-level `.gitignore`
excludes them defensively.

Auth tokens (irrelevant for this no-account setup) would land in
`~/.local/share/opencode/auth.json`, outside the stowed tree.

## Future: Zen account

If you ever `/connect` an opencode.ai / Zen account for broader model
access, **Zen auto-reloads at $5 → $20 by default**. To stay free: keep
balance at $0 and only pick models from the free pool (`/models` shows the
current list).
