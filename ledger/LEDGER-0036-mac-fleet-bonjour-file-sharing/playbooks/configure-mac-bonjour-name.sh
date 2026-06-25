#!/usr/bin/env bash
# Align Mac Computer Name + Local Hostname so Finder Network shows fleet tags.
set -euo pipefail

TARGET="${MAC_BONJOUR_NAME:-$(scutil --get LocalHostName 2>/dev/null || hostname -s)}"
TARGET="${TARGET%.local}"

if [[ "$(id -u)" -ne 0 ]]; then
  exec sudo MAC_BONJOUR_NAME="$TARGET" "$0" "$@"
fi

scutil --set ComputerName "$TARGET"
scutil --set LocalHostName "$TARGET"
scutil --set HostName "$TARGET.local"

echo "✓ Bonjour names:"
echo "  ComputerName:  $(scutil --get ComputerName)"
echo "  LocalHostName: $(scutil --get LocalHostName)"
echo "  HostName:      $(scutil --get HostName)"