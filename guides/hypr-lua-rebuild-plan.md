# Hypr rebuild: Lua config + hypr-ecosystem apps

## Context
Branch `feat/update-hypr-lua` started as a straight `hyprland.conf` → Lua port. It is now a rebuild with three goals:
(1) move to Hyprland's Lua config now that hyprlang support is gone in 0.57;
(2) prefer hyprwm apps over third-party tools where one exists;
(3) a simpler config shaped the user's way: a thin entry file, topic modules, and binds kept as data.
Installed: **Hyprland 0.57.2** (planned on 0.56.2; the laptop updated on 2026-11-09). The authoritative references are
`/usr/share/hypr/hyprland.lua` and `/usr/share/hypr/stubs/hl.meta.lua`. The wiki tracks `main`, so the local stubs
win when the two disagree (e.g. use spring `dampening`, not `damping`).

**0.57 is live: hyprlang `.conf` is no longer parsed.** On the 2026-11-09 boot Hyprland ignored the stow-linked
`hyprland.conf` (`--verify-config -c hyprland.conf` → `unexpected symbol near '#'`), wrote a stock
`~/.config/hypr/hyprland.lua` (a regular file, not a symlink) and loaded that (log: `Regular config at
~/.config/hypr/hyprland.lua`). The laptop is therefore running the stock config now: stock binds, kitty/nautilus/wofi,
no waybar/hypridle/hyprpaper autostart, no lock bind. Consequences for this plan:
1. "Go back to the old `.conf`" is no longer a rollback. The fallback is the stock Lua config, which is where the
   laptop already is, so Phase 4 testing is lower-risk than when this plan was written.
2. `just stow hypr` will refuse until that generated file is moved aside (step 17).
3. The `require` findings below were tested on 0.56.2 and get re-checked on 0.57.2 in Phase 1 (same
   `--verify-config` method).
4. `--locked-cmd`, `--safe-mode` and `--verify-config` still exist in 0.57.2 (checked `Hyprland --help`), and the
   stubs still expose `hl.config`, `hl.dsp.dpms` etc.

## Status (updated 2026-11-09)
| Phase | Status | Commit | Outcome |
|---|---|---|---|
| Research & decisions | ✅ Complete | — | Hyprland Lua API, the hyprwm app inventory, bar/notification/automount alternatives, the wiki must-haves, and the system audit (UWSM, polkit, notification daemons, pipewire, Qt, fonts, GNOME leftovers) are all done. Scope settled with the user |
| 0 Sync with main, publish plan, install packages | ✅ Complete | `039d1a4` (merge), `eb50264` (plan) | origin/main merged; plan published (0c); `[user]` ran 0a + 0b on 2026-11-09 (all 14 packages present, leftovers removed, hyprlang now a dep) |
| 1 Lua port | ✅ Shipped | `8464c90` | hyprland.lua + lua/{core,extras}; monitors template + host-init; .zlogin `--locked-cmd`; hypridle Lua dispatch; CI asserts; palette fix. Static checks pass on 0.57.2 (both tiers, core-only, monitors absent/present/broken, sandbox stow + CI script) |
| 2 Hypr apps, packages, fonts (8–15b) | ✅ Shipped | `b89e5c8` | hyprlauncher/hyprshutdown/hyprpicker/hyprpwcenter/hyprpolkitagent wired in; wofi, pavucontrol and the sink-cycle script removed; `hyprtoolkit.conf`; Adwaita cursor declared; `fontconfig` package; `_pkgs_base` updated. Static checks + sandbox CI pass. No `hyprlauncher.conf`: it has no font/colour options, the theme comes from hyprtoolkit.conf |
| 3 Docs | ✅ Shipped | `5f72b3e` | README + guides/host-config.md: boot model via `--locked-cmd`, Lua layout/tiers/autostart, monitors template, waybar-only autodetect |
| 3b PR for review | ✅ Reviewed | see next commit | [PR #42](https://github.com/anotherjson/anotherdot/pull/42). `/code-review` (xhigh) returned 9 findings; 8 fixed (reboot/poweroff issued from inside the session, empty-choice guards, `HYPR_TIERS` parsing, host-init refuses a folded `~/.config/hypr`, Super+Shift+Ctrl+M → hyprshutdown, pipewire-pulse dropped as an easyeffects dep, one `config_home` helper, `u.each` in the entry file); 1 kept by decision (sans/serif → FiraCode). Ready for Phase 4 |
| 4 Test in ~/.dotfiles, then merge | ⏳ Pending | — | `[user]`: detached checkout of the reviewed branch, rollback = stock Lua; laptop stays on gdm |
| 5 Laptop gdm → autologin + hyprlock | ⏳ Pending | — | `[user]`, after merge and once Lua is stable; test `--locked-cmd` from a TTY first |
| Follow-ups (GNOME, waybar cleanup) | 🗂 Deferred | — | separate branches |

On the branch so far: the `origin/main` merge (`039d1a4`), this plan document (`eb50264`), and the Phase 1 Lua port
(`8464c90`), and the Phase 2 app/package/font work (hash recorded by the next commit). The `[user]` package steps
0a/0b are still open, Post-0a checks (2026-11-09): `hyprlauncher -m` prints `Exited without selection` (exit 0) on Esc; both pickers now
match it (`13cf7e7`). shellcheck clean on all changed scripts; `fc-match` rows all correct (CJK → Noto CJK JP,
emoji → Noto Color Emoji); hyprpolkitagent binary at `/usr/lib/hyprpolkitagent/hyprpolkitagent`; `hyprlauncher --help`
confirms `-d` and `-m` (dmenu via stdin); `hyprshutdown --post-cmd` confirmed. CI `bootstrap` job passed on PR #42; `/code-review` running.

## Recovery quick reference (if the laptop misbehaves)
Read this from another device at `guides/hypr-lua-rebuild-plan.md` on GitHub. Try these in order.
0. **Where you are today (0.57, before Phase 4):** Hyprland loads the stock `~/.config/hypr/hyprland.lua` it generated.
   It boots and has the stock binds (Super+Q kitty, Super+R wofi, Super+M exit). Nothing from this repo is active.
1. **Get a shell.** Ctrl+Alt+F3 gives a text console at any time; log in there. Nothing below needs a working desktop.
2. **Hyprland starts but the config is broken.** Hyprland adds emergency binds when no binds loaded:
   Super+Q terminal, Super+M exit. The error popup names the broken file.
3. **Load only the core tier.** From the console: `HYPR_TIERS=core start-hyprland`. This skips everything in `lua/extras/`.
4. **Hyprland's own safe mode.** `start-hyprland -- --safe-mode` starts with Hyprland's recovery config instead of this one.
5. **Check the config without starting anything.** `Hyprland --verify-config` prints `config ok` or the failing file and line.
6. **Fall back to the stock config** (the old `.conf` no longer loads on 0.57), from the console, in `~/.dotfiles`:
   1. `just unstow hypr` (also `just unstow waybar`, `just unstow fontconfig` if those misbehave)
   2. `cp /usr/share/hypr/hyprland.lua ~/.config/hypr/hyprland.lua` (Hyprland also regenerates it on its own if the
      file is missing at start)
   3. log in again through gdm
   - This is exactly the state the laptop is in on 2026-11-09, so it is known to boot.
   - To get the repo's config back after fixing it: remove that stock file, then `just stow hypr`.
7. **Login problems after Phase 5 only.** From the console: `sudo systemctl enable gdm`, then
   `sudo rm /etc/systemd/system/getty@tty1.service.d/autologin.conf`, then reboot. If the screen is stuck on hyprlock,
   Ctrl+Alt+F3 still reaches a console.
8. **Monitors wrong.** Delete or edit `~/.config/hypr/monitors.lua`; with no file, Hyprland uses its defaults.

## Decisions (user, 2026-09-30)
- **Layout:** tiered `lua/core/` + `lua/extras/` loaded by `hyprland.lua` (switch: edit the tiers string or `HYPR_TIERS=core`). **No per-host hypr files**; the only machine-specific hypr file is the local `monitors.lua`.
- **Login (user decision):** the laptop moves from gdm to the desktop's flow (TTY1 autologin → `start-hyprland` → hyprlock), **as its own Phase 5 after the Lua work is merged**. Both machines then share one boot path. Trade-off accepted: no session chooser at login; GNOME is only reachable by launching it by hand from another TTY.
- **Binds:** plain data tables plus one registering loop (functional style, no repeated `hl.bind` lines).
- **Adopt:**
  - hyprlauncher, replacing wofi
  - hyprpolkitagent
  - hyprpicker
  - hyprpwcenter, replacing pavucontrol
  - hyprshutdown
  - a `hyprtoolkit.conf` theme
- **Cursor:** stay on Adwaita (XCursor, official repos), declared explicitly. No AUR hyprcursor theme.
- **Keep:** hyprlock, hypridle, hyprpaper, xdg-desktop-portal-hyprland, waybar + swaync, udiskie (current 4-line config).
- **Skip:** hyprsunset, hyprqt6engine, hyprsysteminfo.

## Target layout (`hypr/.config/hypr/`): tiered like the nvim config (user decision)
nvim groups plugins as `plugins/{core,util,extras,lsp}` and imports each group from `lazy.lua`, so the user can drop
`extras` while troubleshooting. Hypr uses the same idea: two tiers, each a folder loaded with a wildcard `require`.
Each `require` is error-isolated, so a broken extras file never takes down core.
```
hyprland.lua        -- tier loader only (below)
.luarc.json         -- { "workspace": { "library": ["/usr/share/hypr/stubs"] } }
lua/util.lua        -- exec(cmd), bind_all(prefix, list), start_all(list) helpers
lua/theme.lua       -- FULL Solarized Osaka palette as a Lua table (mirrors solarized_osaka.conf 1:1)
lua/programs.lua    -- { terminal, files, menu, lock, bar, ... }
lua/core/env.lua        -- XCURSOR/HYPRCURSOR env, cursor theme
lua/core/input.lua      -- kb layout, touchpad, follow_mouse
lua/core/binds.lua      -- ALL binds (a bind whose app/daemon is not running just no-ops)
lua/core/autostart.lua  -- hypridle, hyprpolkitagent, swaync, hyprlauncher -d
lua/extras/look.lua     -- general/decoration/animations/dwindle/master/misc
lua/extras/rules.lua    -- window/layer rules
lua/extras/autostart.lua -- waybar, hyprpaper, udiskie, easyeffects, gsettings (theme/fonts/cursor)
hyprlock.conf hypridle.conf hyprpaper.conf hyprlauncher.conf hyprtoolkit.conf   -- hyprlang, unchanged format
solarized_osaka.conf  -- full hyprlang palette for hyprlock/hyprtoolkit; duplicate-name bug fixed, nothing removed
scripts/kitty-cwd.sh scripts/power-menu.sh scripts/ssh-idle-guard.sh
```
```lua
-- hyprland.lua
local tiers = os.getenv("HYPR_TIERS") or "core,extras"   -- edit this string, or override from the TTY
for tier in tiers:gmatch("[^,]+") do
  require("./lua/" .. tier .. "/*")   -- wildcards need the UNIX path form
end
local config_home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
pcall(require, config_home .. "/hypr/monitors")   -- machine-local, untracked (see below)
-- broken desktop? from TTY1:  HYPR_TIERS=core start-hyprland
```
Tested on 0.56.2 with `Hyprland --verify-config` against a scratch config (2026-09-30). **Re-check each point on
0.57.2 as the first task of Phase 1**, with the same scratch-config method (safe inside the live session):
- `require("./lua/core/*")` works; the dotted form `require("lua.core.*")` **fails** ("no file ..."), so use the path form.
- A tier file can `require("lua.programs")` and gets the returned table.
- A broken file in `extras/` is reported by name and does not stop the rest; `HYPR_TIERS=core` skips it.
- **Relative requires resolve from the real file, not the symlink.** With stow, `require("monitors")` looks in the
  repo, not in `~/.config/hypr`, and fails. The absolute path above works, and `pcall` makes a missing file harmless.
- **Toggle (user decision):** edit the default string (autoreload applies it), or set `HYPR_TIERS=core` at launch.
  - After dropping a tier, options it already set may persist through a plain `hyprctl reload`; use
    `hyprctl reload full-reset` or re-login. Verify this during implementation.
  - Document both switches in `guides/host-config.md`.
- **Monitors are machine-local, from a template (user decision).** Adding a monitor or a machine must not require a PR.
  - **One template (user decision):** `hosts/hypr/monitors.lua.template`.
    - The active rule is Hyprland's default: `hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })`.
    - Two commented examples sit below it:
      - **one monitor (laptop):** `eDP-1` at scale 2
      - **three monitors (desktop):** three outputs with mode@Hz, positions side by side, by name or `desc:`, and scale
    - Every machine starts on defaults and you uncomment or adapt the example that fits.
    - There are no per-profile monitor templates.
  - `just host-init` **copies** the template to `~/.config/hypr/monitors.lua` only if that file doesn't exist.
    It never overwrites, so local edits survive re-runs.
  - `hyprland.lua` loads it by absolute path with `pcall(require, ...)`, outside the tiers. If it's missing, Hyprland's
    defaults apply: `preferred`/`auto`/`auto`.
  - The monitor rule leaves the host files, which are then deleted entirely (see Login decision).
  - Guards so the local file can't land in git:
    - all stow calls in the justfile use `--no-folding` (`stow`/`restow` L105-124, `stow-bundle` L249), so
      `~/.config/hypr` is always a real directory, never a folded symlink into the repo
    - `.gitignore` gets `hypr/.config/hypr/monitors.lua`
  - nwg-displays (extra, v0.4.4) writes the same file for Lua configs. It isn't added now, but can be installed later
    as an optional GUI editor.
- **Independence:** modules inside a tier must not depend on each other's load order (wildcard order is undocumented);
  shared data comes only from `util`/`theme`/`programs`.
- **Core rationale:** core is the smallest desktop that's safe and doesn't hang apps: input, essential binds, idle+lock,
  polkit and a notification daemon (the wiki warns apps can freeze without one). All binds live in core: launching
  apps works with or without extras, compositor dispatchers always work, and binds aimed at extras daemons
  (e.g. `pkill -SIGUSR2 waybar`) silently do nothing when those daemons are off (user decision).
- **No hypr host files:** `hosts/hypr/host.conf.*` are deleted; `hosts/hypr/` keeps only `monitors.lua.template`.
  - Brightness binds go to `core/binds.lua`; on a desktop the keys don't exist and `brightnessctl` finds no device.
  - Lock-at-login comes from `.zlogin` (step 3a), so it applies to every machine that autologs in.
  - `just host-init` keeps only the waybar `host.jsonc` link and seeds `monitors.lua`.

Bind shape (in `lua/core/binds.lua`):
```lua
local p, u = require("lua.programs"), require("lua.util")
u.bind_all("SUPER", {
  { "T",       u.exec(p.terminal) },
  { "Q",       hl.dsp.window.close() },
  { "SPACE",   u.exec(p.menu) },
  { "SHIFT+Q", u.exec(p.lock) },
})
u.bind_all(nil, { { "XF86AudioRaiseVolume", u.exec("wpctl ..."), { locked = true, repeating = true } } })
-- workspaces 1..10 generated by mapping over a range, not written out by hand
```
`u.exec` wraps `hl.dsp.exec_cmd(cmd)` (the dispatcher form the stock 0.57 config uses inside binds); autostart uses
the plain `hl.exec_cmd(cmd)` inside the `hyprland.start` handler, as the stock config does.

## Steps
Commits are made per phase, in imperative mood; run the tests in **Verification** before each commit. A phase's
own hash can't be in the commit that creates it, so the Status table records each hash in the following commit.

### Phase 0 — sync with main
0. `[claude]` `git merge origin/main`. Merge rather than rebase, because the branch is already pushed to
   `origin/feat/update-hypr-lua` and a rebase would need a force-push. The branch is 1 behind and 2 ahead.
   The new commit is `38bd10f`, which switches `wezterm-git` to `wezterm` from extra. It touches only justfile L137,
   so the merge will be clean.
0c. `[claude]` **Put this plan in the remote repo as a reference document (user decision).** This is a big change
    with a real chance of leaving the laptop in a bad state, so the plan must be readable from another device.
    - Copy this file to `guides/hypr-lua-rebuild-plan.md` (not gitignored; `guides/` is where reference docs live).
    - Link it from the "guides" list in `README.md`.
    - Commit (`docs(hypr): add lua rebuild plan`) and **push** right away, before any implementation commit.
    - Keep it current: at the end of each phase, update the Status table (with commit hashes) and any step that
      changed, in both `~/.claude/plans/` and the repo copy, as part of that phase's commit and push.
    - It includes the **Recovery quick reference** section above, so the way back is on GitHub even if the laptop
      can't show it.
    - After the merge it stays in `guides/` as the record of what was done and why.
0a. `[user]` **Install the new packages up front (user decision)** so implementation can read real configs, help output
    and defaults, and tools exist for static checks. Checked against `yay -Q` on 2026-11-09: still all missing.
    - Missing, so install: `yay -S --needed hyprlauncher hyprpolkitagent hyprpicker hyprpwcenter hyprshutdown qt5-wayland noto-fonts noto-fonts-cjk shellcheck`
      - `shellcheck` is only a dev tool for **Verification**; it doesn't go into `_pkgs`.
    - Already installed but only as dependencies; mark them explicit:
      `yay -D --asexplicit qt6-wayland pipewire-pulse adwaita-cursors wl-clipboard noto-fonts-emoji`
    - Already present: `lua`/`luac` (for `luac -p`).
    - Installing doesn't change the running session. Nothing autostarts these until the new config is deployed in Phase 4.
      hyprpolkitagent's D-Bus service file may let it start on demand, which is harmless.
    - `[claude]` then confirms the behaviors the plan depends on, against the installed versions:
      - `hyprlauncher --help` (`-m`/`-d`, cancel output)
      - `hyprshutdown --help`
      - the `hyprtoolkit.conf` options
0b. `[user]` **Remove unused leftovers now (user decision: split removals).** Nothing in `main` or the branch uses these:
    - `yay -Rns hyprsysteminfo hyprsysteminfo-debug hyprwayland-scanner-git hyprwayland-scanner-git-debug hyprlang-git-debug hyprutils-git-debug`
    - `yay -D --asdeps hyprlang`
    - wofi and pavucontrol stay until after merge (step 19): the stock 0.57 config that the laptop falls back to
      uses wofi as its menu.

### Phase 1 — Lua port (behavior-equivalent)
1. `[claude]` First re-run the 0.56.2 `require` checks on 0.57.2 (scratch config + `--verify-config`), then write the
   modules above, porting every setting in `hyprland.conf`:
   - **Template comments:** drop the example boilerplate and any unused settings (e.g. the `epic-mouse-v1` device block).
   - **Variables:** delete `$paper` and `$terminal` (defined but unused).
   - **Autostart:** each `exec-once` becomes an `hl.exec_cmd` call inside an `hl.on("hyprland.start", ...)` handler in `core/autostart.lua` / `extras/autostart.lua`. Keep the hyprpaper socket-wait loop and the `systemd-cat` wrapper for hypridle.
   - **Window rules:** become `hl.window_rule{ match = {...} }`.
2. `[claude]` Fix existing bugs while porting:
   - **Super+S collision:** Super+S / Super+Shift+S stay scratchpad, and togglesplit moves to Super+O (tell the user if a different key is preferred).
   - **Bar restart:** the bind becomes `pkill -SIGUSR2 waybar` (reloads in place; no psmisc needed, and the notify call is removed).
3. `[claude]` Delete `hyprland.conf` and `hosts/hypr/host.conf.*` (git is the backup). `hosts/hypr/` then holds only `monitors.lua.template`. Brightness `bindel` lines move to `core/binds.lua`.
3a. `[claude]` **Lock at login via `.zlogin`.** In `zsh/.zlogin` (L24-25), `start-hyprland` becomes
    `start-hyprland -- --locked-cmd hyprlock`. This is Hyprland's own "launch locker on startup" flag (`Hyprland --help`).
    - It replaces `exec-once = hyprlock` from the old desktop host file and covers every autologin machine.
    - The plain `Hyprland` fallback gets the same `--locked-cmd hyprlock`.
    - Confirmed: `start-hyprland --help` says "Any arguments after -- are passed to Hyprland".
    - `vlock` on exit stays as is.
4. `[claude]` Update `hyprctl dispatch` callers to the Lua syntax:
   - `hypridle.conf` L4, L28, L29: use `hyprctl dispatch 'hl.dsp.dpms({ action = "enable"/"disable" })'`. Confirm the arg shape with `hyprctl eval` after the switch.
5. `[claude]` Update `justfile` `host-init` (L225-238):
   - drop the hypr `host.conf` link; keep the battery check only for the waybar `host.jsonc` link
   - remove a stale `~/.config/hypr/host.conf` link if one exists (left by the old host-init, now dangling)
   - copy `monitors.lua.template` → `~/.config/hypr/monitors.lua` only if it is absent
   - add `--no-folding` to every stow call
   - gitignore `hypr/.config/hypr/monitors.lua`
6. `[claude]` Update `.github/workflows/assert-bootstrap.sh`:
   - L24-25: check `hyprland.lua` instead of `hyprland.conf`
   - L40-41: remove the `host.conf` assert (the waybar `host.jsonc` assert stays)
   Also assert that `~/.config/hypr/monitors.lua` is a **regular file** (copied from `monitors.lua.template`, not a symlink)
   and that `~/.config/hypr` is a real directory (no folding).
7. `[claude]` Fix `solarized_osaka.conf` duplicate var names (L71, L83-101): the `...Alpha` variants overwrite the base
   names, so restore the intended `...Alpha` names. Keep the **full** palette, so future changes have every color
   available (user decision). `lua/theme.lua` mirrors it in full.

### Phase 2 — hypr apps
8. `[claude]` **hyprlauncher replaces wofi.**
   - **Autostart:** add `hyprlauncher -d` to autostart; it is required for `-m` to return the selection.
   - **Menu:** `programs.menu = "hyprlauncher"`.
   - **Picker scripts:** rewrite `scripts/power-menu.sh` and `waybar/.config/waybar/scripts/udiskie-eject.sh` to use `hyprlauncher -m`. Both must treat output `Exited without selection` as a cancel.
   - **Remove wofi everywhere:**
     - the `wofi/` package dir
     - `wofi` in the justfile `_pkgs_base` (L134) and `stow-bundle` (L244)
     - the CI assert (L45-47)
     - mentions in README L20/L45/L48 and `guides/host-config.md` L15
     - `gtk.css` L4
     - the `opencode/README.md` L44 mention
9. `[claude]` **hyprshutdown in the power menu:**
   - Logout = `hyprshutdown`.
   - Reboot / Shutdown = `hyprshutdown --no-fork --no-exit && systemctl reboot` / `poweroff`: apps close gracefully
     while the session is still active, then logind takes it down. (`--post-cmd` would run after Hyprland exits,
     when a gdm session is already closing and polkit's `allow_active` no longer covers systemctl — code review.)
     Phase 4 checks that a cancelled hyprshutdown dialog exits non-zero so the `&&` holds.
   - Lock and Suspend stay as they are now.
   - This removes the `hyprctl dispatch exit` call.
10. `[claude]` **Autostart policy:** start everything the desktop needs from `lua/{core,extras}/autostart.lua`, and keep systemd-started
    non-essentials to a minimum (user decision). That module holds one data list of commands, run by a single
    `hl.on("hyprland.start", ...)` loop.
    - **hyprpolkitagent:** run the binary directly with `/usr/lib/hyprpolkitagent/hyprpolkitagent`, not through `systemctl --user`.
    - **swaync:** start it explicitly with `swaync`. Today it is D-Bus-activated as `swaync.service`; once Hyprland owns
      the name first, systemd never starts it.
    - **The rest of the list:** waybar, hypridle (systemd-cat wrapper), hyprpaper (socket wait), `hyprlauncher -d`,
      udiskie, `easyeffects --service-mode`, and both gsettings lines (once per login).
    - **Left to systemd as essential infrastructure:** pipewire, pipewire-pulse and wireplumber (socket/enabled), the
      xdg portals, gvfs, dconf and gnome-keyring, all D-Bus- or socket-activated.
    - **Untouched:** nothing non-essential is enabled except `speech-dispatcher.socket` and `xdg-user-dirs.service`;
      both are socket- or one-shot-activated and left alone.
11. `[claude]` **hyprpicker:** add a bind `SUPER+SHIFT+C → hyprpicker -a`. List `wl-clipboard` explicitly as its optdep.
12. `[claude]` **hyprpwcenter replaces pavucontrol and the sink-cycle script:**
    - Swap it in `_pkgs_base`.
    - Delete `waybar/.config/waybar/scripts/cycle_audio_sink.sh`. The user decided to remove it; output switching moves to hyprpwcenter.
    - In waybar `config.jsonc` `pulseaudio` (L164-166):
      - `on-click` becomes `hyprpwcenter`.
      - Remove `on-click-right`.
      - `on-click-middle` becomes `wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle`, matching the volume keys.
13. `[claude]` **hyprtoolkit theme:** write `hyprtoolkit.conf` with Solarized Osaka colors and FiraCode Nerd Font. Check the option names against the wiki's hyprtoolkit user page first.
14. `[claude]` **Cursor: stay on Adwaita (user decision, 2026-09-30).**
    - No hyprcursor theme exists in the official repos (all are AUR), so no hyprcursor theme is added.
    - Declare the cursor explicitly instead of relying on `default`:
      - `lua/core/env.lua`: `hl.env("XCURSOR_THEME", "Adwaita")` and `hl.env("XCURSOR_SIZE", "24")`.
        Keep `HYPRCURSOR_SIZE` 24; Hyprland falls back to XCursor when no hyprcursor theme exists.
      - Autostart gsettings: `cursor-theme 'Adwaita'` and `cursor-size 24`, so GTK apps match.
    - Add `adwaita-cursors` to `_pkgs_base` explicitly. Today it's only a dependency of adwaita-icon-theme, and the config now names it.
15. `[claude]` **justfile `_pkgs_base`:** add hyprlauncher, hyprpolkitagent, hyprpicker, hyprpwcenter and hyprshutdown. List top-level packages only.
    Also add the wiki "Must-have" gaps (https://wiki.hypr.land/useful-utilities/must-have/):
    - `qt5-wayland` and `qt6-wayland`, both as the wiki recommends (user decision).
      - qt6-wayland is installed today but marked as a dependency that nothing requires.
      - qt5-wayland is new and pulls in qt5-base.
    - `noto-fonts`: a fallback only, to cover glyphs FiraCode lacks (accents, other scripts). FiraCode is the primary font (see step 15a).
    - `noto-fonts-emoji`: color emoji fallback (user decision); FiraCode has no emoji.
    - `noto-fonts-cjk`: Chinese/Japanese/Korean fallback (user decision); FiraCode and noto-fonts both lack these (U+4E2D checked).
    - Not adding Font Awesome. FiraCode Nerd Font already includes its icons; U+F015 and U+F1EB were checked with `fc-list`.
    - `pipewire-pulse`: **not listed after all** — code review found it is a hard dependency of `easyeffects`, which is
      already in `_pkgs_base`, so listing it would break the top-level-only rule. It stays installed through easyeffects.
      Verified: `pipewire-media-session` and `pulseaudio` are not installed.
    - The rest of that list is already covered: swaync (autostarted, step 10), pipewire + wireplumber, xdg-desktop-portal-hyprland,
      and polkit via hyprpolkitagent.

15a. `[claude]` **FiraCode everywhere (user decision).** Today FiraCode is set per app (kitty, wezterm, waybar,
    swaync, hyprlock, gtk-3 `settings.ini`). The generic families fall back to ghostscript's Nimbus fonts:
    `sans-serif` → Nimbus Sans, `serif` → Nimbus Roman, `monospace` → Nimbus Mono. The gsettings monospace font is `Adwaita Mono`.
    - **New stow package `fontconfig/.config/fontconfig/fonts.conf`:** maps the `sans-serif`, `serif` and `monospace`
      families to `FiraCode Nerd Font`, with `Noto Sans`/`Noto Serif` then `Noto Sans CJK`/`Noto Serif CJK` as glyph fallbacks and `Noto Color Emoji` for emoji.
      This covers Firefox, Qt apps and anything else that uses the default fonts.
      - Consequence to expect: web pages that don't ship their own fonts will render in FiraCode (monospace) in Firefox.
        If that's too much, drop the `sans-serif`/`serif` mappings and keep only `monospace`.
      - Add `fontconfig` to the `stow-bundle` base list (justfile L244) and add a CI assert for `fonts.conf`.
    - **autostart gsettings:** add `monospace-font-name 'FiraCode Nerd Font Mono 12'`. `font-name` is already FiraCode;
      set it here too so it's declared rather than living only in dconf.
    - **Hypr app configs:** `hyprtoolkit.conf` and `hyprlauncher.conf` use FiraCode Nerd Font. hyprlock already does.
    - **Verify:** `fc-match sans-serif`, `fc-match serif` and `fc-match monospace` all return FiraCode.
      `fc-match 'sans-serif:charset=4e2d'` returns Noto Sans CJK, and `fc-match 'sans-serif:charset=1f600'` returns Noto Color Emoji.

15b. **waybar on this branch: only the changes the hypr work forces.**
    - The eject picker moves to hyprlauncher (step 8).
    - The volume module's click/mute changes and the cycle-script deletion are in step 12.
    - Hyprland styling doesn't reach waybar except through layer rules; none are added (the bar is opaque).
    - Weather removal, comment cleanup and styling are out of scope here (see the follow-up list).

### Phase 3 — docs
16. `[claude]` Update `README.md` (L18-48) and `guides/host-config.md`:
    - rewrite "Boot model" (L46-63): lock-at-login now comes from `--locked-cmd hyprlock` in `.zlogin` on any machine
      without a display manager (the laptop joins that flow in Phase 5)
    - the autodetect section (L129-180) now covers waybar only, plus the monitors template
    - the autostart list
    Add a short "Lua config" note covering the layout, `.luarc.json`, the core/extras tiers + `HYPR_TIERS`, and the
    machine-local `monitors.lua` (edit locally, never commit; the template seeds new machines).
    README L47 "FiraCode Nerd Font everywhere" now refers to the `fontconfig` package. Add `fontconfig` to the package table
    and to the `base` row in `guides/host-config.md` L15.

### Phase 3b — PR for code review (user decision)
16a. `[claude]` After Phases 0–3 and all static **Verification** checks pass, push `feat/update-hypr-lua` and open a PR
    against `main` with `gh pr create`.
    - **Summary:** what changed, decisions with trade-offs (login flow, tiers, local monitors, adopted and dropped
      apps), and package additions and removals.
    - **Cutover checklist:** Phase 4 steps 17–19 and Phase 5, verbatim.
    - **Manual verification checklist:** the `[user]` items from **Verification**.
    - **Not live-tested yet:** only static checks ran. Live testing is Phase 4, before merge.
    - Ends with the attribution line.
    Wait for review before Phase 4. Review fixes are new commits on the branch. Merge happens only after Phase 4 testing passes.
    Keep the review short: the laptop is on the stock config until Phase 4 lands.

### Phase 4 — test the branch in `~/.dotfiles` after review, then merge (user decision)
The justfile deploys from `dotfiles := ~/.dotfiles` (justfile L2), so testing means checking the reviewed branch out
**in the main worktree**.
- **Detached checkout required:** git won't check out `feat/update-hypr-lua` there by name while this worktree holds
  it, so use a detached checkout of the pushed branch.
- **Partial testing works:** you can test parts of the branch by restowing only some packages, e.g. just `hypr`.
- **Risk is lower than when this was planned:** failure leaves you on the stock 0.57 Lua config, which is what the
  laptop runs today.
17. `[user]` Deploy the branch for testing. **Unstow on the old checkout, switch, then stow on the new one.**
    stow can only unlink files that exist in the checkout it runs from, so `restow` after switching would leave
    dangling links (`hyprland.conf`, `cycle_audio_sink.sh`) and can't unlink wofi at all.
    Run this from a TTY with Hyprland not running: log out to gdm, press Ctrl+Alt+F3 and log in there. Otherwise the
    running session sees its config disappear mid-swap, and what it does then is untested.
    0. **Clear the regular files that would make `just stow hypr` abort** (stow refuses a non-symlink target and then
       skips the whole package). Pre-flight on 2026-11-09 found three:
       - `mv ~/.config/hypr/hyprland.lua ~/.config/hypr/hyprland.lua.stock` (Hyprland's autogenerated stock config)
       - `rm ~/.config/swaync/config.json ~/.config/swaync/style.css` — regular copies, byte-identical to
         `hypr/.config/swaync/*` (checked with `diff`); the hypr package re-links them
       - `~/.config/wofi/{config,style.css}` are regular copies too, so `just unstow wofi` is a no-op; leave them
         (the stock-config fallback uses wofi) and delete the directory in step 19
       The `*.bak` files from 2025-06 in `~/.config/hypr` can also go; nothing reads them.
       Also: `~/.dotfiles` had an uncommitted `waybar/.config/waybar/style.css` re-indent; park or discard it first so
       the detached checkout starts clean.
    1. In `~/.dotfiles` on `main` (clean tree): `just unstow hypr`, `just unstow waybar`, `just unstow wofi`.
    2. `git -C ~/.dotfiles fetch && git -C ~/.dotfiles switch --detach origin/feat/update-hypr-lua`.
    3. `just install-deps base`. Should be a no-op after 0a; it confirms `_pkgs` matches.
    4. `just stow hypr`, `just stow waybar`, `just stow fontconfig`. `stow` runs host-init for hypr and waybar, which
       seeds `monitors.lua` and removes the stale `host.conf` link.
    5. `Hyprland --verify-config` must print `config ok`. It reads the deployed `~/.config/hypr/hyprland.lua`.
    - `.zlogin` follows the checkout immediately, through its existing zsh stow link.
    - **Rollback** if testing fails, again from a TTY. Rolling back to `main` is pointless on 0.57 (its `.conf` won't
      load), so roll back to the stock Lua config instead:
      1. Still on the branch checkout: `just unstow hypr`, `just unstow waybar`, `just unstow fontconfig`.
      2. `mv ~/.config/hypr/hyprland.lua.stock ~/.config/hypr/hyprland.lua` (or copy `/usr/share/hypr/hyprland.lua`).
      3. `git -C ~/.dotfiles switch main`, then `just stow waybar` and `just stow wofi` so the bar and the stock
         config's wofi menu work. Do **not** `just stow hypr` on main; that would only link the dead `.conf` files.
      4. `rm ~/.config/hypr/monitors.lua` is optional; `main` ignores the file.
      - The packages installed in 0a can stay.
    - Fixes found while testing go on the branch in this worktree. Push, then in `~/.dotfiles` run
      `git fetch && git switch --detach origin/feat/update-hypr-lua`. Restow only if files were added or removed.
18. `[user]` Log back in to Hyprland through gdm and check everything in **Verification** except the **Boot** items
    (those belong to Phase 5).
18b. `[user]` When testing passes: merge the PR, then `git -C ~/.dotfiles switch main && git -C ~/.dotfiles pull`.
    The content is identical to what was tested, so no restow is needed. After that, remove this worktree with
    `git worktree remove ~/.dotfiles-feat-update-hypr-lua`, and delete `~/.config/hypr/hyprland.lua.stock`.
19. `[user]` **After merge (18b):** `yay -Rns wofi pavucontrol`. The stock-config fallback no longer needs wofi once
    the repo config is proven.
    - Every package this plan adds is from `extra`. After the merge, the only AUR package left in `_pkgs` is `arch-update`.
    - wezterm on this machine has already been switched to extra (done by the user).

### Phase 5 — laptop login: gdm → TTY autologin + hyprlock (user decision: deferred until Lua is merged and stable)
This is a separate, later phase. Through Phases 0–4 the laptop keeps logging in through gdm. No repo changes are
needed here: the `--locked-cmd` `.zlogin` (step 3a) is already merged, and it only takes effect on a TTY1 autologin.
20. `[user]` **Test the lock flag without changing the boot path.** Log out to gdm, press Ctrl+Alt+F3, log in, and run
    `start-hyprland -- --locked-cmd hyprlock`. Hyprland must come up already locked by hyprlock, with no desktop
    visible first. Unlock, then exit Hyprland. If this fails, stop here and fix it on a new branch.
21. `[user]` **Switch.**
    1. `sudo systemctl disable gdm`. Not `--now`, because that would kill the running session.
    2. `just enable-tty-autologin`. It skipped before because gdm was enabled; now it writes the tty1 override.
    3. Reboot. Expect the LUKS passphrase, then hyprlock, then the desktop.
    - **Rollback:** `sudo systemctl enable gdm`, then
      `sudo rm /etc/systemd/system/getty@tty1.service.d/autologin.conf`, then reboot.
22. `[user]` Check the **Boot** items in **Verification**.
- **Desktop machine:** it already uses TTY autologin, and this branch replaces its `exec-once = hyprlock` with the
  `.zlogin` flag. Run step 20 on the laptop **before** deploying the merged `main` to the desktop, so the flag is
  proven before a machine depends on it. On the desktop, run the same step-20 test from a second TTY right after deploying.
  If the desktop has also moved to 0.57 it is on the stock config too; its step-17 deploy needs the same step 0.

## Out of scope: follow-up tasks
- **GNOME leftovers:** `pacman -S gnome` was run on 2025-06-05 and almost all 58 group packages are still installed,
  including gnome-shell, orca and speech-dispatcher. gdm is disabled in Phase 5 but stays installed.
  The follow-up should:
  - decide whether to uninstall gdm (only after Phase 5 has disabled it)
  - keep nautilus, gvfs, gnome-keyring and xdg-user-dirs-gtk
  - remove the rest from a reviewed list
  This branch doesn't touch it (user decision).
- **waybar cleanup (user decision: separate pass):**
  - Remove the `custom/weather` block (`config.jsonc` L192-198) and `scripts/get_weather.sh`. They're not in any
    module list, so they never ran.
  - Remove ~119 dead comment lines in `config.jsonc`: example blocks, fake `hyprland/mode`/`hyprland/scratchpad`
    sway leftovers, and stale inline alternates.
  - Styling in `style.css`:
    - undefined `@font` color (L13 → `@text`)
    - unitless `#window` padding
    - unused selectors (keep the full `solarized-osaka.css` palette)

## Verification
- `[claude]` Before every commit, run `Hyprland --verify-config -c hypr/.config/hypr/hyprland.lua` (from the worktree).
  It must print `config ok`. This executes the Lua (confirmed: it reports runtime errors per file), and it's safe to run
  inside the live session (re-confirmed on 0.57.2, 2026-11-09).
- `[claude]` Also verify core alone: `HYPR_TIERS=core Hyprland --verify-config -c hypr/.config/hypr/hyprland.lua` must pass,
  which proves core doesn't depend on extras.
- `[claude]` Run `luac -p` (or `lua-language-server --check`) over `hypr/.config/hypr/**/*.lua`, plus `shellcheck` on the changed scripts.
- `[claude]` Run `just install-deps-list all | xargs yay -Si >/dev/null`; every package name must resolve, as CI requires.
- `[user]` After cutover, check by hand:
  - **Core-only mode:** set the tiers string to `"core"`, then `hyprctl reload full-reset`. Check that the desktop is
    usable (all binds, polkit prompt, notifications), with no bar, animations or wallpaper.
    Then restore it.
  - **Monitors:** host-init created `~/.config/hypr/monitors.lua` as a regular file from the template, with defaults active.
    - Uncomment the one-monitor example. `hyprctl monitors` should show eDP-1 at 2880x1920@120 and scale 2, applied by
      auto-reload.
    - `git -C ~/.dotfiles status` stays clean.
    - Re-run `just host-init` and confirm the local file is untouched.
  - **Boot (Phase 5 only, after step 21):**
    - After the LUKS passphrase, Hyprland comes up already locked by hyprlock, with no desktop frame visible first.
    - `loginctl show-session $XDG_SESSION_ID -p TTY -p Service` shows `tty1` and no `gdm-password`.
    - Exiting Hyprland drops to `vlock`.
  - **Binds:** every bind works, including Super+S (scratchpad), Super+O (togglesplit), media keys while locked, and laptop brightness.
  - **Autostart:** each autostart process is running (`pgrep` for waybar, swaync, hypridle, hyprpaper, hyprlauncher, udiskie, hyprpolkitagent, easyeffects).
  - **Power menu:** opens and Cancel exits cleanly. Logout goes through hyprshutdown. Reboot/Shutdown: confirm the
    hyprshutdown dialog appears first; if it offers a cancel, cancelling must **not** reboot (exit code gates the `&&`).
  - **Eject picker:** opens from the waybar disk icon.
  - **Idle:** `hyprctl dispatch 'hl.dsp.dpms({ action = "disable" })'` turns the screen off. hypridle's dpms on/off fires on idle.
  - **Polkit:** a polkit prompt appears (e.g. `pkexec true`).
  - **Theme:** hyprlauncher, hyprpwcenter and hyprshutdown show the Solarized theme.
  - **Cursor:** the Adwaita cursor looks the same over Hyprland surfaces, GTK apps (nautilus) and XWayland windows.
