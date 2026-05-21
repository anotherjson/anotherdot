# anotherdot

Dotfiles for an Arch Linux + Hyprland desktop, themed [Solarized Osaka].
Managed with [GNU Stow], with a few special-case deploys (Claude, Firefox)
driven by [`just`].

[Solarized Osaka]: https://github.com/craftzdog/solarized-osaka.nvim
[GNU Stow]: https://www.gnu.org/software/stow/manual/
[`just`]: https://github.com/casey/just

## Layout

Each top-level directory is a stow package mirroring its target path inside
`$HOME`.

| Package | Configures |
|---|---|
| `hypr` | Hyprland window manager — keybinds, idle/lock, scripts |
| `waybar` | Status bar |
| `wofi` | App launcher / power menu |
| `kitty` | Terminal (primary) |
| `wezterm` | Terminal (alternate) |
| [`nvim`](nvim/README.md) | Neovim |
| `zsh` | `.zshrc`, aliases |
| `starship` | Shell prompt |
| `gtk` | GTK 3/4 + libadwaita theming |
| `firefox` | userChrome / userContent (symlink-based — see below) |
| [`claude`](claude/README.md) | Claude Code config (copy-based) |
| `gemini` | Gemini CLI config |
| [`opencode`](opencode/README.md) | opencode TUI agent (bundled free model, no account) |
| `backgrounds` | Wallpapers |

Platform-specific setup quicknotes live in [`guides/`](guides/):
- [`guides/host-config.md`](guides/host-config.md) — typed bootstrap +
  per-host autodetect
- [`guides/arch.md`](guides/arch.md) — Arch nvim/pyenv quicknotes
- [`guides/macbook-air-ubuntu.md`](guides/macbook-air-ubuntu.md) — legacy
  MacBook Air on Ubuntu

## Theming

All apps share the [Solarized Osaka] palette — pinned upstream by
`craftzdog/solarized-osaka.nvim` for nvim, mirrored by hand into kitty, wezterm,
waybar, wofi, swaync, gtk, and firefox userChrome. Window transparency is set
via Hyprland `windowrule = opacity` (not per-app rgba), since most apps don't
composite alpha through to the desktop. Font is FiraCode Nerd Font everywhere
for glyph parity in waybar/wofi/kitty.

## Bootstrap

Requires `git`, `just`, and an AUR helper (`yay`) already installed. Clone the
repo, then bootstrap from inside it:

```zsh
git clone https://github.com/anotherjson/anotherdot.git ~/.dotfiles
cd ~/.dotfiles
just bootstrap
```

`just bootstrap` runs `_preflight`, `install-deps` (`yay -S --needed` for
the system-package list), and `deploy` (stows packages, runs host-init for
laptop-vs-desktop config variants, and for production/all runs the Claude
and Firefox special-case deploys). At the end it prints any manual steps
remaining — notably setting zsh as the default shell and reloading Hyprland.

Pass `type=...` to select a bundle — see
[`guides/host-config.md`](guides/host-config.md).

## Day-to-day commands

```zsh
dots stow <pkg>      # stow a single package
dots restow <pkg>    # unstow + stow (after package changes)
dots unstow <pkg>    # remove the symlinks
dots stow-bundle     # stow every package for the given type
dots deploy          # stow-bundle + host-init + (production: claude + firefox)
```

## Firefox config

Firefox uses `userChrome.css` for Solarized Osaka UI theming. It can't be
stowed because the profile path contains a random ID, so it's symlink-based.

**One-time setup** — enable custom stylesheets in `about:config`:

```
toolkit.legacyUserProfileCustomizations.stylesheets = true
```

**Deploy** — link `firefox/chrome/` into your active profile:

```zsh
dots firefox-deploy
```

Restart Firefox to apply.
