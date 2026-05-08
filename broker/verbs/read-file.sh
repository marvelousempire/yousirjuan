#!/usr/bin/env bash
# verb: read-file <path>
# Reads a file from the host and writes its contents to stdout.
# Path MUST match an allowlist entry — otherwise rejected.
# Allowlist defined in policy.yaml (TODO: real parser; for now: env var).

set -euo pipefail

PATH_REQ="${1:-}"
[[ -z "$PATH_REQ" ]] && { echo "usage: read-file <path>" >&2; exit 1; }

# Resolve to an absolute path to defeat ../ traversal.
PATH_REQ="$(cd "$(dirname "$PATH_REQ")" 2>/dev/null && printf '%s/%s' "$(pwd -P)" "$(basename "$PATH_REQ")")"
[[ -z "$PATH_REQ" ]] && { echo "broker: path resolution failed" >&2; exit 1; }

# Default-deny allowlist. Override via YOUSIRJUAN_BROKER_READ_ALLOWLIST.
# Format: colon-separated absolute path globs.
ALLOWLIST_DEFAULT="$HOME/Documents/yousirjuan-shared/*:$HOME/Public/*"
ALLOWLIST="${YOUSIRJUAN_BROKER_READ_ALLOWLIST:-$ALLOWLIST_DEFAULT}"

allowed=0
IFS=':' read -ra patterns <<< "$ALLOWLIST"
for p in "${patterns[@]}"; do
  # Use bash glob match
  if [[ "$PATH_REQ" == $p ]]; then
    allowed=1
    break
  fi
done

if (( allowed == 0 )); then
  echo "broker: read-file denied: $PATH_REQ not in allowlist" >&2
  echo "  Allowlist: $ALLOWLIST" >&2
  exit 1
fi

[[ -f "$PATH_REQ" && -r "$PATH_REQ" ]] || { echo "broker: not a readable file: $PATH_REQ" >&2; exit 1; }

# Optional: cap file size to prevent leaks of huge files
MAX_BYTES="${YOUSIRJUAN_BROKER_READ_MAX_BYTES:-1048576}"   # 1 MB default
SIZE=$(stat -f%z "$PATH_REQ" 2>/dev/null || stat -c%s "$PATH_REQ" 2>/dev/null || echo 0)
if (( SIZE > MAX_BYTES )); then
  echo "broker: file too large ($SIZE bytes > max $MAX_BYTES)" >&2
  exit 1
fi

exec cat "$PATH_REQ"
