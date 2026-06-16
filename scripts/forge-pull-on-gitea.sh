#!/usr/bin/env bash
# Pull GitHub main into the Gitea bare repo on DGX (master storage).
# Uses HTTPS — works for public marvelousempire repos without GitHub SSH on Mac/DGX.
#
# Usage (on nephew-spark):
#   bash scripts/forge-pull-on-gitea.sh [repo-name]
#   bash scripts/forge-pull-on-gitea.sh yousirjuan

set -euo pipefail

REPO="${1:-yousirjuan}"
FORGE_ORG="${FORGE_ORG:-marvelousempire}"
BARE="/data/git/repositories/${FORGE_ORG}/${REPO}.git"
GITHUB_URL="https://github.com/${FORGE_ORG}/${REPO}.git"
BRANCH="${BRANCH:-main}"
LOG="${LOG:-${HOME}/.local/share/yousirjuan/forge-pull.log}"

mkdir -p "$(dirname "$LOG")"
exec >>"$LOG" 2>&1
echo "=== $(date -Iseconds) forge-pull-on-gitea $FORGE_ORG/$REPO ==="

if ! command -v docker >/dev/null; then
  echo "✗ docker required (run on DGX)"
  exit 2
fi

if ! docker exec gitea-gitea-1 test -d "$BARE"; then
  echo "✗ bare repo missing: $BARE"
  exit 2
fi

if ! docker exec -u git gitea-gitea-1 git -C "$BARE" fetch --quiet "$GITHUB_URL" \
  "+refs/heads/${BRANCH}:refs/remotes/github/${BRANCH}"; then
  echo "✗ github fetch failed (private or rate-limited)"
  exit 3
fi

gitea_sha="$(docker exec -u git gitea-gitea-1 git -C "$BARE" rev-parse "refs/heads/${BRANCH}" 2>/dev/null || echo '?')"
github_sha="$(docker exec -u git gitea-gitea-1 git -C "$BARE" rev-parse "refs/remotes/github/${BRANCH}" 2>/dev/null || echo '?')"

if [[ "$gitea_sha" == "$github_sha" ]]; then
  echo "✓ aligned ${gitea_sha:0:7}"
  exit 0
fi

if docker exec -u git gitea-gitea-1 git -C "$BARE" merge-base --is-ancestor "$gitea_sha" "refs/remotes/github/${BRANCH}" 2>/dev/null; then
  echo "→ GitHub ahead; fast-forward Gitea bare main"
  docker exec -u git gitea-gitea-1 git -C "$BARE" update-ref "refs/heads/${BRANCH}" "refs/remotes/github/${BRANCH}"
  echo "✓ gitea now ${github_sha:0:7}"
  exit 0
fi

if docker exec -u git gitea-gitea-1 git -C "$BARE" merge-base --is-ancestor "refs/remotes/github/${BRANCH}" "$gitea_sha" 2>/dev/null; then
  echo "→ Gitea ahead (push-mirror catches GitHub)"
  exit 0
fi

echo "✗ DIVERGED gitea=${gitea_sha:0:7} github=${github_sha:0:7}"
exit 4
