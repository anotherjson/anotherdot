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
[ "$choice" != "Exited without selection" ] || exit 0

case "${choice##* }" in
    Lock)      loginctl lock-session ;;
    Suspend)   systemctl suspend ;;
    Hibernate) systemctl hibernate ;;
    Logout)    hyprshutdown ;;
    Reboot)    hyprshutdown --post-cmd 'systemctl reboot' ;;
    Shutdown)  hyprshutdown --post-cmd 'systemctl poweroff' ;;
esac
