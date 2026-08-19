# Host config

Two orthogonal mechanisms keep one repo working across multiple machines:
typed bootstrap (chooses *what* to install) and host autodetect (chooses
*which laptop-vs-desktop bits* to wire up).

## Typed bootstrap

```zsh
just bootstrap <base|production|gaming|all>
```

| Type         | System packages                                                | Stow packages                          |
|--------------|----------------------------------------------------------------|----------------------------------------|
| `base`       | Hyprland WM stack, terminals, editor, shell, audio, theme/font | hypr, waybar, wofi, kitty, wezterm, nvim, zsh, starship, gtk, udiskie, backgrounds |
| `production` | `base` + firefox, nautilus, darktable, opencode                | base + gemini, opencode                |
| `gaming`     | `base` + steam (strict — no firefox/claude/gemini/opencode)    | base                                   |
| `all`        | union of production + gaming                                   | base + gemini, opencode                |

`just bootstrap` with no argument defaults to `base`.

`production` and `all` additionally run `install-claude` (curl installer),
`claude-deploy` (copy claude/ config), and `firefox-deploy` (symlink
chrome/ into the firefox profile).

Firefox itself needs a one-time manual step: launch firefox interactively
once from inside Hyprland so it seeds a `default-release` profile, then
re-run `just firefox-deploy` to install the userChrome symlink. Bootstrap
intentionally doesn't try to headless-init the profile — Firefox 67+'s
profile-per-install lock rejects empty `-CreateProfile` dirs on first
launch, and `--headless` first-run has been flaky across versions.

`gaming` and `all` require the `[multilib]` repo enabled in
`/etc/pacman.conf` (steam pulls lib32-* dependencies). `_preflight` checks
this before any install.

A few packages in the `base` bundle are load-bearing for the shipped
shell + login flow rather than incidental tooling — removing them from
`_pkgs_base` will break the corresponding alias or security guarantee:

- `eza` — backs the `ls` alias in `.zshrc`
- `arch-update` — backs the `update` / `news` aliases in `.zshrc`
- `vlock` — locks TTY1 if Hyprland exits, preventing exposure of the
  autologged-in shell (see `~/.zlogin`)

## Boot model (no display manager)

On hosts without a display manager (`sddm`/`gdm`/`greetd`/`ly`/`lightdm`),
bootstrap wires up a single-auth boot flow via three coordinated pieces:

1. `just enable-tty-autologin` writes
   `/etc/systemd/system/getty@tty1.service.d/autologin.conf` so TTY1 boots
   straight to a logged-in shell. Skipped if a display manager is enabled
   (DM owns the boot path). Refuses to run as root to prevent baking
   `--autologin root` into the override.
2. `~/.zlogin` (zsh login-shell hook) gates on `/dev/tty1` and execs
   `start-hyprland`. On Hyprland exit it execs `vlock` to lock the VT so
   the autologged-in shell isn't exposed. A `HYPRLAND_LAUNCH_GUARD` env
   prevents a tight loop in the pathological case where both Hyprland and
   vlock are missing.
3. `hosts/hypr/host.conf.desktop` sets `exec-once = hyprlock` so the
   desktop boots straight into a locked screen — hyprlock becomes the
   single auth gate.

## System-level config

`deploy` is user-level only and never needs root. Anything requiring sudo
lives in `just sync-system`, which `bootstrap` also calls. **After pulling
changes that touch system config, run `just sync-system`** — otherwise an
already-provisioned host never picks them up.

Today `sync-system` runs `harden-sshd`, which drops
`10-dotfiles-hardening.conf` into `/etc/ssh/sshd_config.d/`:

| Directive | Value | Why |
| --- | --- | --- |
| `PasswordAuthentication` | `no` | keys only |
| `PubkeyAuthentication` | `yes` | explicit, not inherited |
| `PermitRootLogin` | `prohibit-password` | no root password login |
| `ClientAliveInterval` | `60` | probe idle clients |
| `ClientAliveCountMax` | `3` | reap a dead link after ~3min |

The **`10-` prefix matters**. sshd takes the *first* value it obtains for
each keyword, so a drop-in sorting later loses — a `99-` file was shadowed
by Arch's own `99-archlinux.conf`. Sorting early is what makes these
directives take effect. The recipe writes to a tempfile in the include
directory (so `sshd -t` validates it in context), `mv`s it into place, then
asserts the *effective* value with `sshd -T`, because `sshd -t` only checks
syntax and passes happily on a fully shadowed drop-in. It reloads sshd only
when it is already running, so a sync never starts a daemon you stopped.

## Idle suspend with ssh sessions

hypridle counts only Wayland input as activity, so ssh work never resets its
idle timer and a remote session would be suspended out from under you. Two
listeners in `hypr/.config/hypr/hypridle.conf` handle this:

- **30 min** — `systemctl suspend-then-hibernate`, gated by a hypridle
  `condition_cmd`. `hypr/.config/hypr/scripts/ssh-idle-guard.sh` exits 1
  while any logind session has `Remote=yes`, which defers the suspend;
  hypridle re-runs it every 60 s and drops the pending retry by itself the
  moment real input arrives.
- **2.5 h** — an unconditioned hard ceiling. A permanently-connected `-N`
  tunnel or VS Code Remote-SSH would otherwise defer forever.

So a connected ssh session holds the machine awake until it disconnects or
the ceiling hits. There is no "quiet session" grace: an idle-but-connected
shell rides to the ceiling.

`ClientAliveInterval`/`ClientAliveCountMax` above are **load-bearing here** —
they bound how long a dead session keeps the box awake, since the guard keys
off logind sessions and those persist until sshd reaps them.

The guard is fail-safe: if it is missing, non-executable, or broken it exits
0 and the suspend proceeds, because never being able to suspend is the worse
failure. That means **a lost executable bit silently disables the feature** —
`ssh-idle-guard.sh` must stay mode `0755`.

To watch it work:

```
journalctl -t hypridle -t ssh-idle-guard -f
```

`$idle` in `hyprland.conf` runs hypridle under `systemd-cat` for exactly this
reason; Hyprland otherwise sends `exec-once` children's output to `/dev/null`,
which would hide both the retry messages and any config parse error.

## Per-host autodetect

`just host-init` (also run automatically as part of `deploy`) detects
whether the machine is a laptop by checking for `/sys/class/power_supply/BAT*`
and symlinks the matching variant from `hosts/`:

```
hosts/
├── hypr/
│   ├── host.conf.laptop     # eDP-1 monitor, brightness keybinds
│   └── host.conf.desktop    # exec-once = hyprlock (lock-at-boot for no-DM hosts)
└── waybar/
    ├── host.jsonc.laptop    # modules-right with battery + backlight
    └── host.jsonc.desktop   # modules-right without battery/backlight
```

Output goes to `~/.config/hypr/host.conf` and `~/.config/waybar/host.jsonc`.
The main Hyprland config sources the first; the main waybar config
includes the second.

`just stow hypr`, `just stow waybar` (and their `restow` counterparts)
also chain `host-init` automatically, so single-package stows don't leave
the include target dangling. Other packages aren't affected.

The laptop branch is exercised only by manual runs on a laptop; CI covers
the desktop branch and the symlink mechanics.

CI tests the `base` type only. Production-specific recipes (`claude-deploy`,
`firefox-deploy`, `install-claude`) are exercised manually via
`just bootstrap production` on real hardware — see the verification section
of any change that touches them.

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
