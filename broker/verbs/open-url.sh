#!/usr/bin/env bash
# verb: open-url <url>
# Opens a URL in the host's default browser.
# Allowlist: enforced via policy.yaml regex (TODO: wire up).

set -euo pipefail

URL="${1:-}"
[[ -z "$URL" ]] && { echo "usage: open-url <url>" >&2; exit 1; }

# Basic safety: must be http/https and not a localhost-bypass.
case "$URL" in
  http://*|https://*) : ;;
  *) echo "broker: only http/https URLs allowed" >&2; exit 1 ;;
esac

# TODO: load policy.yaml allowlist regex; reject non-matching.

# macOS:
if command -v open >/dev/null 2>&1; then
  exec open "$URL"
fi

# Linux (xdg):
if command -v xdg-open >/dev/null 2>&1; then
  exec xdg-open "$URL"
fi

echo "broker: no URL opener found on this host" >&2
exit 1
