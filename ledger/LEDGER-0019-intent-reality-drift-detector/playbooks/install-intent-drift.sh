#!/usr/bin/env bash
# install-intent-drift.sh — install the LEDGER-0019 drift detector as a
# systemd timer that runs every 5 minutes.

set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "must run as root"; exit 1; }

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
SRC="${REPO_ROOT}/ledger/LEDGER-0019-intent-reality-drift-detector/playbooks/intent-drift-check.sh"
LIB_DIR="/usr/local/lib/yousirjuan"
SERVICE="/etc/systemd/system/yousirjuan-intent-drift.service"
TIMER="/etc/systemd/system/yousirjuan-intent-drift.timer"

BLUE='\033[1;34m'; GREEN='\033[1;32m'; NC='\033[0m'
step() { printf "${BLUE}→ %s${NC}\n" "$*"; }
ok()   { printf "${GREEN}✓ %s${NC}\n" "$*"; }

case "${1:-install}" in
  install)
    step "Installing intent-drift-check"
    mkdir -p "$LIB_DIR" /var/lib/yousirjuan
    install -m 0755 "$SRC" "$LIB_DIR/intent-drift-check.sh"

    cat > "$SERVICE" <<EOF
[Unit]
Description=Yousirjuan Intent-Reality Drift Check (LEDGER-0019)
After=network-online.target

[Service]
Type=oneshot
ExecStart=/bin/bash $LIB_DIR/intent-drift-check.sh
StandardOutput=append:/var/log/yousirjuan-intent-drift.log
StandardError=append:/var/log/yousirjuan-intent-drift.log
EOF

    cat > "$TIMER" <<EOF
[Unit]
Description=Run Yousirjuan Intent-Reality Drift Check every 5 min
Requires=yousirjuan-intent-drift.service

[Timer]
OnBootSec=2min
OnUnitActiveSec=5min
Unit=yousirjuan-intent-drift.service

[Install]
WantedBy=timers.target
EOF

    systemctl daemon-reload
    systemctl enable --now yousirjuan-intent-drift.timer
    ok "timer enabled — first check fires in ~2min, then every 5min"

    echo
    echo "── run once now to seed the report ──"
    bash "$LIB_DIR/intent-drift-check.sh" || true
    ;;
  uninstall)
    systemctl disable --now yousirjuan-intent-drift.timer 2>/dev/null || true
    rm -f "$SERVICE" "$TIMER" "$LIB_DIR/intent-drift-check.sh"
    systemctl daemon-reload
    ok "uninstalled"
    ;;
  status)
    systemctl status yousirjuan-intent-drift.timer --no-pager 2>&1 | head -10
    echo
    echo "── recent log ──"
    tail -20 /var/log/yousirjuan-intent-drift.log 2>/dev/null
    echo
    echo "── current report ──"
    cat /var/lib/yousirjuan/intent-drift-report.json 2>/dev/null | head -30
    ;;
  *) echo "usage: $0 {install|uninstall|status}";;
esac
