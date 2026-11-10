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
| `base`       | Hyprland WM stack, terminals, editor, shell, audio, theme/font | hypr, waybar, fontconfig, kitty, wezterm, nvim, zsh, starship, gtk, udiskie, backgrounds |
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
bootstrap wires up a single-auth boot flow via two coordinated pieces:

1. `just enable-tty-autologin` writes
   `/etc/systemd/system/getty@tty1.service.d/autologin.conf` so TTY1 boots
   straight to a logged-in shell. Skipped if a display manager is enabled
   (DM owns the boot path). Refuses to run as root to prevent baking
   `--autologin root` into the override.
2. `~/.zlogin` (zsh login-shell hook) gates on `/dev/tty1` and runs
   `start-hyprland -- --locked-cmd hyprlock`, so Hyprland comes up already
   locked and hyprlock is the single auth gate (the TTY password was skipped
   by autologin). On Hyprland exit it execs `vlock` to lock the VT so the
   autologged-in shell isn't exposed. A `HYPRLAND_LAUNCH_GUARD` env prevents
   a tight loop in the pathological case where both Hyprland and vlock are
   missing.

Nothing in the Hyprland config is host-specific here: `--locked-cmd` only
takes effect on the autologin path, so a machine that still logs in through
a display manager (the laptop, until it is switched over) is unaffected.
The switch itself and its rollback are written up in
[`hypr-lua-rebuild-plan.md`](hypr-lua-rebuild-plan.md), Phase 5.

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

`programs.idle` in `hypr/.config/hypr/lua/programs.lua` runs hypridle under
`systemd-cat` for exactly this reason; Hyprland otherwise sends autostarted
children's output to `/dev/null`, which would hide both the retry messages
and any config parse error.

## Hyprland Lua config

Hyprland 0.57 dropped hyprlang configs, so `hypr/.config/hypr/hyprland.lua`
is the entry point. It only loads tiers; everything else is a module:

```
hypr/.config/hypr/
├── hyprland.lua          # loads the tiers, then ~/.config/hypr/monitors.lua
├── .luarc.json           # lua-language-server → /usr/share/hypr/stubs
├── lua/util.lua          # exec / bind_all / start_all helpers
├── lua/programs.lua      # every external command, by role
├── lua/theme.lua         # Solarized Osaka palette (mirrors solarized_osaka.conf)
├── lua/core/             # env, input, ALL binds, essential autostart
├── lua/extras/           # look (general/decoration/animations), window rules,
│                         # nice-to-have autostart (waybar, hyprpaper, udiskie, …)
├── hyprtoolkit.conf      # theme for hyprlauncher / hyprpwcenter / hyprshutdown / polkit agent
└── hyprlock.conf hypridle.conf hyprpaper.conf solarized_osaka.conf   # still hyprlang
```

**Tiers.** `hyprland.lua` requires `lua/core/*` and `lua/extras/*`
(each file is error-isolated, so a broken extras module never takes core
down). To troubleshoot with the minimal desktop, either set the default
string in `hyprland.lua` to `"core"` (autoreload applies it) or start from a
TTY with `HYPR_TIERS=core start-hyprland`. All binds live in core on
purpose: binds aimed at an extras daemon just do nothing when it isn't
running. After switching tiers in a live session use
`hyprctl reload full-reset`, because a plain reload keeps options the
dropped tier already set.

**Autostart.** Everything the desktop needs starts from the two
`autostart.lua` files (one `hl.on("hyprland.start", …)` loop each), not from
systemd user units: hypridle, hyprpolkitagent (run as its binary),
swaync, `hyprlauncher -d` in core; waybar, hyprpaper, udiskie, easyeffects
and the gsettings lines in extras. pipewire/wireplumber, the portals, gvfs
and gnome-keyring stay socket- or D-Bus-activated.

**Checking a change.** `Hyprland --verify-config` runs the Lua without
starting a compositor and prints `config ok` or the failing file and line;
it is safe inside a live session. `hyprctl dispatch` now takes Lua, e.g.
`hyprctl dispatch 'hl.dsp.dpms({ action = "disable" })'`.

## Per-host autodetect

`just host-init` (also run automatically as part of `deploy`, and chained
by `just stow hypr` / `just stow waybar`) does two things:

1. **Monitors (machine-local, not in git).** If `~/.config/hypr/monitors.lua`
   does not exist it copies `hosts/hypr/monitors.lua.template` there. The
   template's active rule is Hyprland's default (`preferred`, `auto`,
   `auto`); below it are commented examples for one laptop panel at scale 2
   and for three desktop monitors side by side. Edit the local copy — it is
   gitignored, `host-init` never overwrites it, and Hyprland reloads it on
   save. Adding a monitor or a machine therefore never needs a commit.
   `hyprland.lua` loads the file by absolute path; without it Hyprland's
   defaults apply.
2. **waybar.** It detects a laptop by `/sys/class/power_supply/BAT*` and
   symlinks the matching variant from `hosts/waybar/`:

```
hosts/
├── hypr/
│   └── monitors.lua.template   # seeds ~/.config/hypr/monitors.lua once
└── waybar/
    ├── host.jsonc.laptop       # modules-right with battery + backlight
    └── host.jsonc.desktop      # modules-right without battery/backlight
```

Output goes to `~/.config/waybar/host.jsonc`, which the main waybar config
includes. Brightness keys are bound unconditionally in `lua/core/binds.lua`;
on a desktop they simply never fire.

Every stow call uses `--no-folding`, so `~/.config/hypr` is always a real
directory of per-file links and the local `monitors.lua` can never end up
inside the repo. CI asserts both.

The laptop branch is exercised only by manual runs on a laptop; CI covers
the desktop branch and the symlink mechanics.

CI tests the `base` type only. Production-specific recipes (`claude-deploy`,
`firefox-deploy`, `install-claude`) are exercised manually via
`just bootstrap production` on real hardware — see the verification section
of any change that touches them.

## Force-overriding the autodetect

Monitors: edit `~/.config/hypr/monitors.lua` (or delete it to get the
defaults back). waybar: re-link by hand after `host-init` (or in place of
it), then reload the bar:

```zsh
ln -sfn "$HOME/.dotfiles/hosts/waybar/host.jsonc.laptop" ~/.config/waybar/host.jsonc
pkill -SIGUSR2 waybar
```

## Adding a new host bit

1. For waybar, add the snippet to both `hosts/waybar/host.jsonc.{laptop,desktop}`
   — keep the file structure parallel so the autodetect just works. For
   monitors, extend the examples in `hosts/hypr/monitors.lua.template`; the
   local copies on existing machines are untouched.
2. Commit.
3. On each machine: `just host-init` to refresh the symlink, then
   `pkill -SIGUSR2 waybar`.
