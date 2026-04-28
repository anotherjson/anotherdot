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
| `backgrounds` | Wallpapers |

Platform-specific setup quicknotes live in [`guides/`](guides/):
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

Install everything this repo configures or references (Arch):

```zsh
yay -S hyprland hyprlock hypridle hyprpaper xdg-desktop-portal-hyprland \
       waybar wofi swaync pavucontrol pipewire wireplumber \
       kitty wezterm neovim zsh starship \
       adw-gtk-theme ttf-firacode-nerd \
       stow just git
```

Clone the repo:

```zsh
git clone https://github.com/anotherjson/anotherdot.git ~/.dotfiles
```

Add the `dots` alias so you can run recipes from anywhere (already in
`zsh/.zshrc` once that package is stowed):

```zsh
alias dots="just --justfile ~/.dotfiles/justfile --working-directory ~/.dotfiles"
```

Deploy everything:

```zsh
dots deploy-all
```

This runs `stow-all` (links every stow package into `$HOME`), then
`claude-deploy` and `firefox-deploy` for the special-case configs.

## Day-to-day commands

```zsh
dots stow <pkg>      # stow a single package
dots restow <pkg>    # unstow + stow (after package changes)
dots unstow <pkg>    # remove the symlinks
dots stow-all        # stow every package (skips claude/, guides/)
dots deploy-all      # stow-all + claude-deploy + firefox-deploy
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
