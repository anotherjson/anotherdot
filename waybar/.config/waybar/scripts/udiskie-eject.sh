#!/usr/bin/env bash
# hyprlauncher picker for per-device eject of udiskie-mounted removable media.
set -euo pipefail
shopt -s nullglob
mounts=(/run/media/"$USER"/*/)
[ ${#mounts[@]} -ne 0 ] || exit 0

items=()
for m in "${mounts[@]}"; do items+=("$(basename "$m")"); done
items+=("(eject all)")

choice=$(printf '%s\n' "${items[@]}" | hyprlauncher -m --quiet)
# Esc prints this on stdout and exits 0 (hyprlauncher 0.1.7), so match it, don't rely on $?.
[ "$choice" != "Exited without selection" ] || exit 0

if [ "$choice" = "(eject all)" ]; then
    udiskie-umount --all
elif [ -d "/run/media/$USER/$choice" ]; then
    udiskie-umount "/run/media/$USER/$choice"
fi
