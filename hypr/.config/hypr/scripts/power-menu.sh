#!/usr/bin/env bash
set -euo pipefail

choice=$(printf '%s\n'  \
    "  Lock"             \
    "  Suspend"          \
    "  Hibernate"        \
    "  Logout"           \
    "  Reboot"           \
    "  Shutdown"         \
    | wofi --dmenu --prompt "power" --cache-file /dev/null)

case "${choice##* }" in
    Lock)      loginctl lock-session ;;
    Suspend)   systemctl suspend ;;
    Hibernate) systemctl hibernate ;;
    Logout)   hyprctl dispatch exit ;;
    Reboot)   systemctl reboot ;;
    Shutdown) systemctl poweroff ;;
esac
