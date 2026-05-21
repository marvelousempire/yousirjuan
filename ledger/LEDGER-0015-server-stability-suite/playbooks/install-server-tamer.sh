#!/usr/bin/env bash
# install-server-tamer.sh — install/uninstall the LEDGER-0015 proactive killer.
# Runs on the VPS as root. Service runs as abrownsanta + sudo via systemd.

set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "must run as root (sudo)"; exit 1; }

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
SRC="${REPO_ROOT}/ledger/LEDGER-0015-server-stability-suite/playbooks/server-tamer.sh"
LIB_DIR="/usr/local/lib/yousirjuan"
UNIT="/etc/systemd/system/yousirjuan-server-tamer.service"
RUN_USER="${RUN_USER:-abrownsanta}"

BLUE='\033[1;34m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; RED='\033[1;31m'; NC='\033[0m'
step() { printf "${BLUE}→ %s${NC}\n" "$*"; }
ok()   { printf "${GREEN}✓ %s${NC}\n" "$*"; }
warn() { printf "${YELLOW}⚠ %s${NC}\n" "$*"; }
die()  { printf "${RED}✗ %s${NC}\n" "$*" >&2; exit 1; }

action="${1:-install}"

case "$action" in
  install)
    step "Installing server-tamer"
    command -v jq >/dev/null || die "jq missing (apt install jq)"
    command -v curl >/dev/null || die "curl missing"
    [[ -f "$SRC" ]] || die "source not found: $SRC"

    mkdir -p "$LIB_DIR" /var/lib/yousirjuan
    install -m 0755 "$SRC" "$LIB_DIR/server-tamer.sh"
    chown "$RUN_USER:$RUN_USER" /var/lib/yousirjuan
    touch /var/log/yousirjuan-server-tamer.log
    chown "$RUN_USER:$RUN_USER" /var/log/yousirjuan-server-tamer.log

    step "  writing systemd unit"
    cat > "$UNIT" <<EOF
[Unit]
Description=Yousirjuan Server Tamer — proactive OOM-prevention killer (LEDGER-0015)
After=network-online.target yousirjuan-vps-agent.service
Requires=yousirjuan-vps-agent.service

[Service]
Type=simple
User=$RUN_USER
ExecStart=/bin/bash $LIB_DIR/server-tamer.sh
Restart=on-failure
RestartSec=15
KillMode=process

# Server-tamer needs to send signals to user processes; cannot kill root.
# That's by design — root-owned offenders need operator intervention.
NoNewPrivileges=true

# Self-protection: server-tamer is on its own protected-process list inside
# the script so it cannot kill itself.

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable --now yousirjuan-server-tamer.service

    sleep 3
    if systemctl is-active --quiet yousirjuan-server-tamer.service; then
      ok "yousirjuan-server-tamer.service active"
    else
      warn "service did not become active — journalctl -u yousirjuan-server-tamer.service -n 30"
    fi
    ;;
  uninstall)
    step "Uninstalling server-tamer"
    systemctl disable --now yousirjuan-server-tamer.service 2>/dev/null || true
    rm -f "$UNIT" "$LIB_DIR/server-tamer.sh"
    systemctl daemon-reload
    ok "removed (history + log preserved at /var/lib/yousirjuan + /var/log)"
    ;;
  status)
    systemctl status yousirjuan-server-tamer.service --no-pager 2>&1 | head -15
    echo
    echo "── recent log (last 20 lines) ──"
    tail -20 /var/log/yousirjuan-server-tamer.log
    echo
    echo "── system-history.jsonl size ──"
    wc -l /var/lib/yousirjuan/system-history.jsonl 2>/dev/null || echo "(no history yet)"
    ;;
  *) die "usage: sudo bash $0 {install|uninstall|status}" ;;
esac
