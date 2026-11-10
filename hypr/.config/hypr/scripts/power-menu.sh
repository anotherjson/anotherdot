#!/usr/bin/env bash
# Power menu through hyprlauncher's dmenu mode (the `hyprlauncher -d` daemon from autostart must be running).
set -euo pipefail

choice=$(printf '%s\n'  \
    "  Lock"             \
    "  Suspend"          \
    "  Hibernate"        \
    "  Logout"           \
    "  Reboot"           \
    "  Shutdown"         \
    | hyprlauncher -m --quiet)

# Esc prints this on stdout and exits 0 (hyprlauncher 0.1.7), so match it, don't rely on $?.
[ -n "$choice" ] && [ "$choice" != "Exited without selection" ] || exit 0

case "${choice##* }" in
    Lock)      loginctl lock-session ;;
    Suspend)   systemctl suspend ;;
    Hibernate) systemctl hibernate ;;
    Logout)    hyprshutdown ;;
    # Close apps gracefully but stay in the session, then let logind take it down: a --post-cmd
    # would run after Hyprland exits, when a display-manager session is already closing and
    # polkit's allow_active no longer covers systemctl.
    Reboot)    hyprshutdown --no-fork --no-exit && systemctl reboot ;;
    Shutdown)  hyprshutdown --no-fork --no-exit && systemctl poweroff ;;
esac
