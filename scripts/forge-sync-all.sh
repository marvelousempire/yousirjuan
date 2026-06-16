#!/usr/bin/env bash
# Sync all tracked forge repos (LEDGER-0024 list subset on DGX/Mac).
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
LIST="${FORGE_SYNC_LIST:-$HERE/../ledger/LEDGER-0024-dual-push-drift-prevention/artifacts/tracked-repos.txt}"
PARALLEL="${PARALLEL:-3}"
fail=0

sync_one() {
  local repo="$1"
  if bash "$HERE/forge-sync.sh" "$repo"; then
    echo "✓ $repo"
  else
    echo "✗ $repo"
    return 1
  fi
}

export -f sync_one
export HERE

grep -v '^\s*#' "$LIST" | grep -v '^\s*$' | \
  xargs -n1 -P"$PARALLEL" -I{} bash -c 'sync_one "$@"' _ {} || fail=1

exit $fail
