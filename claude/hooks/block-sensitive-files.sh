#!/bin/bash
INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

case "$FILE" in
  *.env|*.env.*|*credentials*|*secret*|*.pem|*.key)
    echo "BLOCKED: refusing to modify sensitive file: $FILE" >&2
    exit 2
    ;;
esac

exit 0
