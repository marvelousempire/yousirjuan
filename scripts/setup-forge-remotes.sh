#!/usr/bin/env bash
# Canonical forge remotes — Gitea marvelousempire = master, GitHub = mirror.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"
REPO="$(basename "$(pwd)")"
FORGE_ORG="${FORGE_ORG:-marvelousempire}"
GITEA_HOST="${GITEA_HOST:-gitea-dgx}"

if git remote get-url gitea >/dev/null 2>&1; then
  git remote set-url gitea "git@${GITEA_HOST}:${FORGE_ORG}/${REPO}.git"
else
  git remote add gitea "git@${GITEA_HOST}:${FORGE_ORG}/${REPO}.git"
fi

if git remote get-url origin >/dev/null 2>&1; then
  :
else
  git remote add origin "git@github.com:${FORGE_ORG}/${REPO}.git"
fi

# Legacy alias: gitlab → same Gitea forge (Family Office convention)
if git remote get-url gitlab >/dev/null 2>&1; then
  git remote set-url gitlab "ssh://git@${GITEA_HOST}/${FORGE_ORG}/${REPO}.git"
else
  git remote add gitlab "ssh://git@${GITEA_HOST}/${FORGE_ORG}/${REPO}.git" 2>/dev/null || true
fi

git branch -u gitea/main main 2>/dev/null || git branch --set-upstream-to=gitea/main main 2>/dev/null || true

echo "✓ remotes configured:"
git remote -v
echo ""
echo "Master:  git push gitea main   (or: make forge-push)"
echo "Mirror:  GitHub push-mirror + scripts/forge-sync.sh for enterprise agent pushes"
echo ""
echo "SSH (cassette standard): bash scripts/setup-cassette-git-ssh.sh"
