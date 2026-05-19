#!/usr/bin/env bash
#
# cycle_audio_sink.sh — Cycle the default audio output sink,
# skipping HDMI sinks. Moves all active streams to the new sink
# and sends a desktop notification.

set -euo pipefail

get_eligible_sinks() {
    pactl list sinks short \
        | awk '{print $2}' \
        | grep -v 'HDMI'
}

get_default_sink() {
    pactl get-default-sink
}

get_sink_description() {
    local sink_name="$1"
    pactl list sinks \
        | grep -A1 "Name: ${sink_name}$" \
        | grep 'Description:' \
        | sed 's/.*Description: //'
}

move_all_streams() {
    local target_sink="$1"
    pactl list sink-inputs short \
        | awk '{print $1}' \
        | while read -r input_id; do
            pactl move-sink-input "$input_id" "$target_sink" 2>/dev/null || true
        done
}

notify() {
    local description="$1"
    notify-send \
        --app-name="Audio" \
        --urgency=low \
        --expire-time=2000 \
        --hint=string:x-canonical-private-synchronous:audio-sink \
        "Audio Output" \
        "Switched to: ${description}"
}

main() {
    local current_sink
    current_sink="$(get_default_sink)"

    local -a sinks
    mapfile -t sinks < <(get_eligible_sinks)

    local count="${#sinks[@]}"

    if (( count == 0 )); then
        notify-send --urgency=critical "Audio" "No eligible audio sinks found"
        exit 1
    fi

    if (( count == 1 )); then
        notify "$(get_sink_description "${sinks[0]}") (only device)"
        exit 0
    fi

    local current_index=-1
    for i in "${!sinks[@]}"; do
        if [[ "${sinks[$i]}" == "$current_sink" ]]; then
            current_index="$i"
            break
        fi
    done

    local next_index=$(( (current_index + 1) % count ))
    local next_sink="${sinks[$next_index]}"

    pactl set-default-sink "$next_sink"
    move_all_streams "$next_sink"

    local description
    description="$(get_sink_description "$next_sink")"
    notify "$description"
}

main "$@"
