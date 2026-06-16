#!/usr/bin/env bash
# Install systemd user timer on DGX (or Mac) — GitHub enterprise pushes → Gitea every 5 min.
set -euo pipefail

UNIT_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SYNC_SCRIPT="$REPO_ROOT/scripts/forge-sync.sh"
ALL_SCRIPT="$REPO_ROOT/scripts/forge-sync-all.sh"

mkdir -p "$UNIT_DIR"

cat >"$UNIT_DIR/yousirjuan-forge-sync.service" <<EOF
[Unit]
Description=Gitea master ↔ GitHub mirror sync (yousirjuan forge)
After=network-online.target

[Service]
Type=oneshot
ExecStart=$ALL_SCRIPT
Environment=PATH=/usr/local/bin:/usr/bin:/bin
WorkingDirectory=$REPO_ROOT
EOF

cat >"$UNIT_DIR/yousirjuan-forge-sync.timer" <<'EOF'
[Unit]
Description=Every 5 min — reconcile GitHub agent pushes into Gitea master

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
echo "✓ forge-sync timer active (user systemd)"
