#!/usr/bin/env bash
# Enable Gitea Actions in live app.ini + optional act_runner deploy.
# Run on nephew-spark as operator with docker access.
set -euo pipefail

GITEA_CTR="${GITEA_CTR:-gitea-gitea-1}"
APP_INI="/data/gitea/conf/app.ini"

echo "→ Enable [actions] in Gitea app.ini"
docker exec "$GITEA_CTR" sh -c "
  if grep -q '^\[actions\]' $APP_INI; then
    sed -i 's/^ENABLED = .*/ENABLED = true/' $APP_INI 2>/dev/null || true
  else
    cat >> $APP_INI <<'EOF'

[actions]
ENABLED = true
DEFAULT_ACTIONS_URL = github
EOF
  fi
"

echo "→ Restart Gitea"
docker restart "$GITEA_CTR"
sleep 5

if docker exec -u git "$GITEA_CTR" gitea admin actions generate-runner-token 2>/dev/null; then
  echo "✓ Runner token generated — register act_runner:"
  echo "  cd deploy/gitea && GITEA_RUNNER_TOKEN=<token> docker compose -f act-runner-compose.yml up -d"
else
  echo "⚠ Generate runner token in Gitea UI:"
  echo "  Site Administration → Actions → Runners → Create new Runner"
fi

echo "✓ Gitea Actions enabled"
