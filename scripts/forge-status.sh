#!/usr/bin/env bash
# Print Gitea vs GitHub SHA alignment for this repo.
set -euo pipefail

REPO="${1:-yousirjuan}"
FORGE_ORG="${FORGE_ORG:-marvelousempire}"
GITEA_SSH="${GITEA_SSH:-git@gitea-dgx:${FORGE_ORG}}"
GITHUB_SSH="${GITHUB_SSH:-git@github.com:${FORGE_ORG}}"
GITHUB_HTTPS="https://github.com/${FORGE_ORG}/${REPO}.git"

sha_for() {
  local url="$1"
  git ls-remote "$url" refs/heads/main 2>/dev/null | awk '{print $1}' || echo '?'
}

echo "=== $FORGE_ORG/$REPO forge status ==="
gitea_sha="$(sha_for "${GITEA_SSH}/${REPO}.git")"
origin_sha="$(sha_for "${GITHUB_SSH}/${REPO}.git")"
if [[ "$origin_sha" == '?' ]]; then
  origin_sha="$(sha_for "$GITHUB_HTTPS")"
  [[ "$origin_sha" != '?' ]] && echo "  (origin via HTTPS — no GitHub SSH on this host)"
fi
echo "  gitea/main  ${gitea_sha:0:7}"
echo "  origin/main ${origin_sha:0:7}"
if [[ "$gitea_sha" != '?' && "$origin_sha" != '?' && "$gitea_sha" == "$origin_sha" ]]; then
  echo "  ✓ aligned"
elif [[ "$gitea_sha" != '?' && "$origin_sha" != '?' ]]; then
  echo "  ⚠ drift"
fi

if command -v ssh >/dev/null && ssh -o ConnectTimeout=5 nephew-spark true 2>/dev/null; then
  echo ""
  echo "Gitea push-mirror last_error (marvelousempire/$REPO):"
  err="$(ssh nephew-spark "docker exec gitea-gitea-1 sqlite3 /data/gitea/gitea.db \
    \"SELECT COALESCE(substr(last_error,1,100),'(none)') FROM push_mirror pm JOIN repository r ON pm.repo_id=r.id \
    JOIN user u ON r.owner_id=u.id WHERE u.name='marvelousempire' AND r.name='$REPO';\"" 2>/dev/null || echo "  (no push_mirror row)")"
  echo "  $err"
fi
