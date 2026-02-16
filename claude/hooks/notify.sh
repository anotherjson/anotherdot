#!/bin/bash
INPUT=$(cat)
MESSAGE=$(echo "$INPUT" | jq -r '.message // "Attention needed"')
notify-send --urgency=normal --icon=dialog-information "Claude Code" "$MESSAGE"
exit 0
