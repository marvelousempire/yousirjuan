#!/usr/bin/env bash
# Push to Gitea master first; GitHub follows via push-mirror (or explicit origin push).
#
# Usage:
#   bash scripts/forge-push.sh [branch]
#   make forge-push

set -euo pipefail

BRANCH="${1:-$(git rev-parse --abbrev-ref HEAD)}"
ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

GITEA_REMOTE="${GITEA_REMOTE:-gitea}"
ORIGIN_REMOTE="${ORIGIN_REMOTE:-origin}"

if ! git remote get-url "$GITEA_REMOTE" >/dev/null 2>&1; then
  echo "✗ no '$GITEA_REMOTE' remote — run: bash scripts/setup-forge-remotes.sh"
  exit 1
fi

echo "→ verify"
node scripts/yousirjuan-verify.mjs

echo "→ push Gitea (master) branch=$BRANCH"
git push "$GITEA_REMOTE" "$BRANCH"

# Push mirror on Gitea syncs GitHub within seconds; optional explicit origin for certainty.
if git remote get-url "$ORIGIN_REMOTE" >/dev/null 2>&1; then
  echo "→ push GitHub (mirror lane) branch=$BRANCH"
  if git push "$ORIGIN_REMOTE" "$BRANCH" 2>&1; then
    echo "✓ GitHub updated"
  else
    echo "⚠ GitHub push failed — Gitea push-mirror may still sync; run: bash scripts/forge-sync.sh"
  fi
fi

echo "✓ forge-push complete"
