#!/usr/bin/env bash
# verb: type-text <text>
# Types the given text into the frontmost application.
# macOS: via osascript. Linux: via xdotool.
# Length cap: 1000 chars (policy enforced here for v1).

set -euo pipefail

TEXT="${*:-}"
[[ -z "$TEXT" ]] && { echo "usage: type-text <text>" >&2; exit 1; }
(( ${#TEXT} > 1000 )) && { echo "broker: text too long (max 1000 chars)" >&2; exit 1; }

# macOS:
if command -v osascript >/dev/null 2>&1; then
  # Escape backslashes + double quotes for AppleScript string literal.
  ESCAPED="${TEXT//\\/\\\\}"
  ESCAPED="${ESCAPED//\"/\\\"}"
  exec osascript -e "tell application \"System Events\" to keystroke \"$ESCAPED\""
fi

# Linux:
if command -v xdotool >/dev/null 2>&1; then
  exec xdotool type --delay 20 -- "$TEXT"
fi
if command -v ydotool >/dev/null 2>&1; then
  exec ydotool type "$TEXT"
fi

echo "broker: no keystroke tool found (install xdotool or ydotool on Linux)" >&2
exit 1
