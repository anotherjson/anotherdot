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
just bootstrap                  # defaults to type=base
just bootstrap type=production  # base + firefox/nautilus/darktable + claude/gemini/opencode
just bootstrap type=gaming      # base + steam (strict — no firefox/claude/gemini)
just bootstrap type=all         # everything
```

| Type         | What's installed                                                                                                                  |
|--------------|-----------------------------------------------------------------------------------------------------------------------------------|
| `base`       | Hyprland WM stack, terminals, editor, shell, audio, theme/font, dotfile tooling. Minimal usable Hyprland desktop.                 |
| `production` | `base` + firefox, nautilus, darktable, opencode. Stows gemini + opencode configs. Runs claude/firefox deploys.                    |
| `gaming`     | `base` + steam. Requires `[multilib]` enabled in `/etc/pacman.conf`. Intentionally strict — no AI/browser tooling.                |
| `all`        | Union of `production` + `gaming`. Multilib required.                                                                              |

`just bootstrap` runs three recipes: `_preflight` (validates required
commands and, for gaming/all, multilib), `install-deps` (`yay -S --needed`
for the bundle), and `deploy-all` (stows the relevant packages, runs
`host-init` to symlink laptop-vs-desktop config variants, and for
production/all runs the Claude and Firefox special-case deploys). At the
end it prints any manual steps remaining — notably setting zsh as the
default shell and reloading Hyprland.

`host-init` autodetects laptop vs. desktop via `/sys/class/power_supply/BAT*`
and links the right variant from `hosts/`. See
[`guides/host-config.md`](guides/host-config.md) for details and how to
force-override.

To inspect what `install-deps` will install for a given type:

```zsh
just install-deps-list <type>
```

## Day-to-day commands

```zsh
dots stow <pkg>            # stow a single package
dots restow <pkg>          # unstow + stow (after package changes)
dots unstow <pkg>          # remove the symlinks
dots stow-all [type]       # stow the packages for the given type (default: base)
dots deploy-all [type]     # host-init + stow-all + (production: claude + firefox)
dots host-init             # re-detect laptop/desktop and refresh host.{conf,jsonc}
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
