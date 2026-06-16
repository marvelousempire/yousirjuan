#!/usr/bin/env bash
# Bidirectional Gitea (master) ↔ GitHub (mirror) sync for one repo.
# Logic from LEDGER-0024 sync_one — fast-forward Gitea when GitHub is ahead;
# fast-forward GitHub when Gitea is ahead (via push mirror or direct push).
#
# Usage:
#   bash scripts/forge-sync.sh [repo-name]   # default: yousirjuan
#   FORGE_ORG=marvelousempire bash scripts/forge-sync.sh nephew
#
# Env:
#   GITEA_SSH   ssh://git@gitea-dgx/marvelousempire  (or 10.1.0.5:2424 over WG)
#   GITHUB_SSH  git@github.com:marvelousempire
#   WORK_DIR    ~/.cache/yousirjuan-forge-sync

set -euo pipefail

REPO="${1:-yousirjuan}"
FORGE_ORG="${FORGE_ORG:-marvelousempire}"
GITEA_SSH="${GITEA_SSH:-git@gitea-dgx:${FORGE_ORG}}"
GITHUB_SSH="${GITHUB_SSH:-git@github.com:${FORGE_ORG}}"
WORK_DIR="${WORK_DIR:-${HOME}/.cache/yousirjuan-forge-sync}"
BRANCH="${BRANCH:-main}"
LOG="${LOG:-${HOME}/.local/share/yousirjuan/forge-sync.log}"

mkdir -p "$WORK_DIR" "$(dirname "$LOG")"
exec >>"$LOG" 2>&1
echo "=== $(date -Iseconds) forge-sync $FORGE_ORG/$REPO ==="

d="$WORK_DIR/$REPO"
if [[ ! -d "$d/.git" ]]; then
  git clone --bare --quiet "${GITHUB_SSH}/${REPO}.git" "$d"
fi

cd "$d"
git remote set-url origin "${GITHUB_SSH}/${REPO}.git"
git remote get-url gitea >/dev/null 2>&1 \
  || git remote add gitea "${GITEA_SSH}/${REPO}.git"
git remote set-url gitea "${GITEA_SSH}/${REPO}.git"

git fetch --quiet origin "+refs/heads/${BRANCH}:refs/remotes/origin/${BRANCH}" \
  || { echo "✗ origin fetch failed"; exit 2; }
git fetch --quiet gitea "+refs/heads/${BRANCH}:refs/remotes/gitea/${BRANCH}" \
  || { echo "✗ gitea fetch failed"; exit 3; }

origin_sha="$(git rev-parse "origin/${BRANCH}" 2>/dev/null || echo '?')"
gitea_sha="$(git rev-parse "gitea/${BRANCH}" 2>/dev/null || echo '?')"
action=none
result=ok

if [[ "$origin_sha" == "$gitea_sha" ]]; then
  echo "✓ aligned ${origin_sha:0:7}"
  exit 0
fi

if git merge-base --is-ancestor "$gitea_sha" "$origin_sha" 2>/dev/null; then
  action=fast-forward-gitea
  echo "→ GitHub ahead; fast-forward Gitea"
  if git push gitea "origin/${BRANCH}:refs/heads/${BRANCH}" --quiet; then
    gitea_sha="$origin_sha"
    echo "✓ gitea now ${gitea_sha:0:7}"
  else
    result=gitea-ff-push-failed
    echo "✗ gitea ff push failed"
  fi
elif git merge-base --is-ancestor "$origin_sha" "$gitea_sha" 2>/dev/null; then
  action=fast-forward-github
  echo "→ Gitea ahead; push GitHub (mirror backup)"
  if git push origin "gitea/${BRANCH}:refs/heads/${BRANCH}" --quiet; then
    origin_sha="$gitea_sha"
    echo "✓ origin now ${origin_sha:0:7}"
  else
    result=origin-ff-push-failed
    echo "✗ origin ff push failed"
  fi
else
  action=diverged-needs-human
  result=diverged
  echo "✗ DIVERGED origin=${origin_sha:0:7} gitea=${gitea_sha:0:7} — merge manually"
  exit 4
fi

printf '{"repo":"%s","origin":"%s","gitea":"%s","action":"%s","result":"%s"}\n' \
  "$REPO" "$origin_sha" "$gitea_sha" "$action" "$result"

[[ "$result" == ok ]] || exit 5
