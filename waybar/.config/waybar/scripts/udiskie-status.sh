#!/usr/bin/env bash
# Emit waybar JSON describing currently-mounted removable media under /run/media/$USER.
# Uses jq to encode newlines safely so multi-label tooltips don't break JSON parsing.
set -euo pipefail
shopt -s nullglob
mounts=(/run/media/"$USER"/*/)
count=${#mounts[@]}

if [ "$count" -eq 0 ]; then
    jq -nc \
        --arg text "" \
        --arg tooltip "No removable media mounted" \
        --arg class "empty" \
        '{text: $text, tooltip: $tooltip, class: $class}'
else
    labels=()
    for m in "${mounts[@]}"; do labels+=("$(basename "$m")"); done
    tooltip=$(printf '%s\n' "${labels[@]}")
    tooltip=${tooltip%$'\n'}
    jq -nc \
        --arg text " $count" \
        --arg tooltip "$tooltip" \
        --arg class "mounted" \
        '{text: $text, tooltip: $tooltip, class: $class}'
fi
