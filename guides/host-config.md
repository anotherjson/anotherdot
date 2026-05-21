# Host config

Two orthogonal mechanisms keep one repo working across multiple machines:
typed bootstrap (chooses *what* to install) and host autodetect (chooses
*which laptop-vs-desktop bits* to wire up).

## Typed bootstrap

```zsh
just bootstrap type=<base|production|gaming|all>
```

| Type         | System packages                                                | Stow packages                          |
|--------------|----------------------------------------------------------------|----------------------------------------|
| `base`       | Hyprland WM stack, terminals, editor, shell, audio, theme/font | hypr, waybar, wofi, kitty, wezterm, nvim, zsh, starship, gtk, udiskie, backgrounds |
| `production` | `base` + firefox, nautilus, darktable, opencode                | base + gemini, opencode                |
| `gaming`     | `base` + steam (strict — no firefox/claude/gemini/opencode)    | base                                   |
| `all`        | union of production + gaming                                   | base + gemini, opencode                |

`just bootstrap` with no argument defaults to `base`.

`production` and `all` additionally run `install-claude` (curl installer),
`claude-deploy` (copy claude/ config), `firefox-profile-init` (launch
firefox headless once to seed a default profile), and `firefox-deploy`
(symlink chrome/ into the profile).

`gaming` and `all` require the `[multilib]` repo enabled in
`/etc/pacman.conf` (steam pulls lib32-* dependencies). `_preflight` checks
this before any install.

## Per-host autodetect

`just host-init` (also run automatically as part of `deploy`) detects
whether the machine is a laptop by checking for `/sys/class/power_supply/BAT*`
and symlinks the matching variant from `hosts/`:

```
hosts/
├── hypr/
│   ├── host.conf.laptop     # eDP-1 monitor, brightness keybinds
│   └── host.conf.desktop    # empty (catch-all monitor= already covers it)
└── waybar/
    ├── host.jsonc.laptop    # modules-right with battery + backlight
    └── host.jsonc.desktop   # modules-right without battery/backlight
```

Output goes to `~/.config/hypr/host.conf` and `~/.config/waybar/host.jsonc`.
The main Hyprland config sources the first; the main waybar config
includes the second.

The laptop branch is exercised only by manual runs on a laptop; CI covers
the desktop branch and the symlink mechanics.

CI tests the `base` type only. Production-specific recipes (`claude-deploy`,
`firefox-deploy`, `install-claude`, `firefox-profile-init`) are exercised
manually via `just bootstrap type=production` on real hardware — see the
verification section of any change that touches them.

## Force-overriding the autodetect

If you want to e.g. run laptop config on a desktop, re-link by hand after
`host-init` (or in place of it):

```zsh
ln -sfn "$HOME/.dotfiles/hosts/hypr/host.conf.laptop"    ~/.config/hypr/host.conf
ln -sfn "$HOME/.dotfiles/hosts/waybar/host.jsonc.laptop" ~/.config/waybar/host.jsonc
```

Then reload: `hyprctl reload` and `killall waybar && waybar &`.

## Adding a new host bit

1. Add the snippet to both `hosts/hypr/host.conf.{laptop,desktop}` and/or
   `hosts/waybar/host.jsonc.{laptop,desktop}` — keep the file structure
   parallel so the autodetect just works.
2. Commit.
3. On each machine: `just host-init` to refresh the symlink, then
   `hyprctl reload` / restart waybar.
