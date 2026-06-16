#!/usr/bin/env bash
# Print Gitea vs GitHub SHA alignment for this repo.
set -euo pipefail

REPO="${1:-yousirjuan}"
FORGE_ORG="${FORGE_ORG:-marvelousempire}"
GITEA_SSH="${GITEA_SSH:-git@gitea-dgx:${FORGE_ORG}}"
GITHUB_SSH="${GITHUB_SSH:-git@github.com:${FORGE_ORG}}"

echo "=== $FORGE_ORG/$REPO forge status ==="
for remote in gitea origin; do
  url=""
  case "$remote" in
    gitea)  url="${GITEA_SSH}/${REPO}.git" ;;
    origin) url="${GITHUB_SSH}/${REPO}.git" ;;
  esac
  sha="$(git ls-remote "$url" refs/heads/main 2>/dev/null | awk '{print $1}' || echo '?')"
  echo "  $remote/main  ${sha:0:7}"
done

if command -v ssh >/dev/null && ssh -o ConnectTimeout=5 nephew-spark true 2>/dev/null; then
  echo ""
  echo "Gitea push-mirror last_error (marvelousempire/$REPO):"
  ssh nephew-spark "docker exec gitea-gitea-1 sqlite3 /data/gitea/gitea.db \
    \"SELECT substr(last_error,1,100) FROM push_mirror pm JOIN repository r ON pm.repo_id=r.id \
    JOIN user u ON r.owner_id=u.id WHERE u.name='marvelousempire' AND r.name='$REPO';\"" 2>/dev/null \
    || echo "  (no push_mirror row)"
fi
