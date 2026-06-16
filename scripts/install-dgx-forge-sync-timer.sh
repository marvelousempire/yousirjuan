#!/usr/bin/env bash
# Install systemd user timer on DGX — GitHub enterprise pushes → Gitea every 5 min.
set -euo pipefail

UNIT_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PULL_SCRIPT="$REPO_ROOT/scripts/forge-pull-on-gitea-core.sh"

mkdir -p "$UNIT_DIR"

cat >"$UNIT_DIR/yousirjuan-forge-sync.service" <<EOF
[Unit]
Description=GitHub mirror → Gitea master pull (core forge repos)
After=network-online.target

[Service]
Type=oneshot
ExecStart=$PULL_SCRIPT
Environment=PATH=/usr/local/bin:/usr/bin:/bin
WorkingDirectory=$REPO_ROOT
EOF

cat >"$UNIT_DIR/yousirjuan-forge-sync.timer" <<'EOF'
[Unit]
Description=Every 5 min — pull GitHub agent pushes into Gitea master

[Timer]
OnBootSec=2min
OnUnitActiveSec=5min
Persistent=true

[Install]
WantedBy=timers.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now yousirjuan-forge-sync.timer
systemctl --user list-timers yousirjuan-forge-sync.timer --no-pager | head -5
echo "✓ forge-pull timer active (user systemd, core repos)"
