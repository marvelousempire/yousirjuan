#!/usr/bin/env bash
# Sync core forge repos only (public GitHub + master on Gitea).
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
export FORGE_SYNC_LIST="$HERE/../artifacts/forge-sync-core.txt"
exec bash "$HERE/forge-sync-all.sh"
