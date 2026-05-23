#
# ~/.zlogin — sourced by zsh on login shells, after .zshrc
#

# Auto-launch Hyprland on TTY1 login. Restores the equivalent block from
# ~/.bash_profile, which became orphaned when the dotfiles bootstrap
# switched the login shell from bash to zsh (justfile chsh step). Gated
# on /dev/tty1 so it never fires in DM-launched sessions (pts), ssh
# sessions (pts), or other TTYs.
#
# If Hyprland exits (crash, manual logout), don't leave an autologged-in
# shell exposed on TTY1 — lock the VT with vlock; password required to
# release. Other TTYs stay reachable via Ctrl+Alt+F2..F6 for recovery.
if [[ "$(tty)" == "/dev/tty1" ]]; then
    # Per-session re-entry guard: if .zlogin is somehow re-sourced in the
    # same login session (pathological — shouldn't happen normally), drop
    # to a recovery shell rather than risking a tight autologin loop.
    if [[ -n "$HYPRLAND_LAUNCH_GUARD" ]]; then
        echo "Hyprland exited twice in this autologin cycle; dropping to shell for recovery."
        unset HYPRLAND_LAUNCH_GUARD
        return
    fi
    export HYPRLAND_LAUNCH_GUARD=1
    if command -v start-hyprland >/dev/null 2>&1; then
        start-hyprland
    elif command -v Hyprland >/dev/null 2>&1; then
        Hyprland
    fi
    if command -v vlock >/dev/null 2>&1; then
        exec vlock
    fi
    # Last-resort fallback: brief sleep avoids a tight loop if both
    # Hyprland and vlock are missing, then exit so getty re-runs
    # autologin (next cycle will start with a fresh env, no guard).
    sleep 2
    exit
fi
