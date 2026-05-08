#!/usr/bin/env bash
# verb: screenshot
# Captures the host's screen and writes raw PNG bytes to stdout.
# The container reads the SSH stdout and saves the image.
set -euo pipefail

# macOS:
if command -v screencapture >/dev/null 2>&1; then
  exec screencapture -x -t png -
fi

# Linux (X11 / Wayland):
if command -v grim >/dev/null 2>&1; then
  exec grim -t png -
fi
if command -v scrot >/dev/null 2>&1; then
  TMP=$(mktemp --suffix=.png)
  scrot "$TMP"
  cat "$TMP"
  rm -f "$TMP"
  exit 0
fi

echo "broker: no screenshot tool found (install scrot or grim on Linux)" >&2
exit 1
