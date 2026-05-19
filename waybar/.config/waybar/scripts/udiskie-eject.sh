#!/usr/bin/env bash
# Wofi picker for per-device eject of udiskie-mounted removable media.
shopt -s nullglob
mounts=(/run/media/"$USER"/*/)
[ ${#mounts[@]} -eq 0 ] && exit 0

items=()
for m in "${mounts[@]}"; do items+=("$(basename "$m")"); done
items+=("(eject all)")

choice=$(printf '%s\n' "${items[@]}" | wofi --dmenu --prompt "Eject:" --width 280 --height 240)
[ -z "$choice" ] && exit 0

if [ "$choice" = "(eject all)" ]; then
    udiskie-umount --all
else
    udiskie-umount "/run/media/$USER/$choice"
fi
