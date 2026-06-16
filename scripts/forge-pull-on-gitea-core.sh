#!/usr/bin/env bash
# Server-side GitHub → Gitea pull for core public repos (runs on DGX).
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
LIST="$HERE/../artifacts/forge-sync-core.txt"
fail=0

while IFS= read -r repo || [[ -n "$repo" ]]; do
  [[ "$repo" =~ ^[[:space:]]*# ]] && continue
  [[ -z "${repo// }" ]] && continue
  if bash "$HERE/forge-pull-on-gitea.sh" "$repo"; then
    echo "✓ pull $repo"
  else
    echo "⚠ pull $repo"
    fail=1
  fi
done <"$LIST"

exit $fail
