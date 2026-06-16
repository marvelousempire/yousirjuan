#!/usr/bin/env bash
# Sync all tracked forge repos (LEDGER-0024 list subset on DGX/Mac).
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
LIST="${FORGE_SYNC_LIST:-$HERE/../artifacts/forge-sync-core.txt}"
PARALLEL="${PARALLEL:-3}"
STRICT="${FORGE_SYNC_STRICT:-0}"
fail=0

sync_one() {
  local repo="$1"
  if FORGE_SYNC_STRICT="$STRICT" bash "$HERE/forge-sync.sh" "$repo"; then
    echo "✓ $repo"
  else
    local code=$?
    if [[ "$STRICT" == "1" ]]; then
      echo "✗ $repo"
      return 1
    fi
    echo "⚠ $repo (exit $code, non-strict)"
    return 0
  fi
}

export -f sync_one
export HERE

if [[ ! -f "$LIST" ]]; then
  echo "✗ forge sync list missing: $LIST"
  exit 1
fi

grep -v '^\s*#' "$LIST" | grep -v '^\s*$' | \
  xargs -n1 -P"$PARALLEL" -I{} bash -c 'sync_one "$@"' _ {} || fail=1

echo "forge-sync-all list=$LIST strict=$STRICT fail=$fail"
exit $fail
