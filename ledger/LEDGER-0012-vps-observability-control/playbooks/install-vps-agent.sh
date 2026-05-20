#!/usr/bin/env bash
# install-vps-agent.sh — install/uninstall the VPS observability agent.
#
# Runs on the VPS itself. Installs:
#   1. /usr/local/lib/yousirjuan/vps-agent-server.sh  (copy of the agent)
#   2. /etc/yousirjuan/vps-agent.env                  (bearer token, chmod 600)
#   3. /etc/systemd/system/yousirjuan-vps-agent.service  (systemd unit)
#
# Idempotent. Runs as user `abrownsanta` (so kills can target abrownsanta-owned
# processes without root). docker commands work because abrownsanta is in the
# docker group.

set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "must run as root (sudo bash $0 install|uninstall|status)"; exit 1; }

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
SRC="${REPO_ROOT}/ledger/LEDGER-0012-vps-observability-control/playbooks/vps-agent-server.sh"
LIB_DIR="/usr/local/lib/yousirjuan"
ETC_DIR="/etc/yousirjuan"
UNIT="/etc/systemd/system/yousirjuan-vps-agent.service"
RUN_USER="${RUN_USER:-abrownsanta}"

BLUE='\033[1;34m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; RED='\033[1;31m'; NC='\033[0m'
step() { printf "${BLUE}→ %s${NC}\n" "$*"; }
ok()   { printf "${GREEN}✓ %s${NC}\n" "$*"; }
warn() { printf "${YELLOW}⚠ %s${NC}\n" "$*"; }
die()  { printf "${RED}✗ %s${NC}\n" "$*" >&2; exit 1; }

action="${1:-install}"

action_install() {
  step "Installing yousirjuan-vps-agent"
  command -v python3 >/dev/null || die "python3 missing"
  id "$RUN_USER" >/dev/null 2>&1 || die "user $RUN_USER does not exist"
  [[ -f "$SRC" ]] || die "source agent not found at $SRC"

  mkdir -p "$LIB_DIR" "$ETC_DIR"
  chmod 755 "$LIB_DIR"
  chmod 750 "$ETC_DIR"

  step "  copying agent to $LIB_DIR"
  install -m 0755 "$SRC" "$LIB_DIR/vps-agent-server.sh"

  step "  copying entities config to $ETC_DIR (only if absent — operator edits live there)"
  ENTITIES_SRC="${REPO_ROOT}/ledger/LEDGER-0012-vps-observability-control/artifacts/entities-default.json"
  if [[ -f "$ETC_DIR/vps-agent-entities.json" ]]; then
    ok "$ETC_DIR/vps-agent-entities.json already exists (preserving operator edits)"
  elif [[ -f "$ENTITIES_SRC" ]]; then
    install -m 0644 "$ENTITIES_SRC" "$ETC_DIR/vps-agent-entities.json"
    ok "installed default entity map"
  else
    warn "no entities-default.json found at $ENTITIES_SRC — /entities will return empty until populated"
  fi

  # Generate token only if not already present
  if [[ ! -f "$ETC_DIR/vps-agent.env" ]]; then
    token="$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")"
    cat > "$ETC_DIR/vps-agent.env" <<EOF
VPS_AGENT_TOKEN=$token
EOF
    chmod 640 "$ETC_DIR/vps-agent.env"
    chown "root:$RUN_USER" "$ETC_DIR/vps-agent.env"
    ok "generated bearer token at $ETC_DIR/vps-agent.env"
    note_token="$token"
  else
    ok "$ETC_DIR/vps-agent.env exists (reusing token)"
    note_token=""
  fi

  step "  writing systemd unit"
  cat > "$UNIT" <<EOF
[Unit]
Description=Yousirjuan VPS Observability + Control Agent (LEDGER-0012)
After=network-online.target docker.service
Wants=network-online.target

[Service]
Type=simple
User=$RUN_USER
EnvironmentFile=$ETC_DIR/vps-agent.env
ExecStart=/bin/bash $LIB_DIR/vps-agent-server.sh
Restart=on-failure
RestartSec=10
StandardOutput=append:/var/log/yousirjuan-vps-agent.log
StandardError=append:/var/log/yousirjuan-vps-agent.log

# Modest hardening — agent only needs to read /proc + call docker
ProtectSystem=full
ProtectHome=read-only
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF
  touch /var/log/yousirjuan-vps-agent.log
  chown "$RUN_USER:$RUN_USER" /var/log/yousirjuan-vps-agent.log

  step "  reloading systemd + starting"
  systemctl daemon-reload
  systemctl enable --now yousirjuan-vps-agent.service

  sleep 2
  if curl -sf -m 3 http://127.0.0.1:9878/health >/dev/null; then
    ok "agent responding on http://127.0.0.1:9878/health"
  else
    warn "agent did not respond on :9878 within 2s — check log:"
    warn "  sudo tail /var/log/yousirjuan-vps-agent.log"
  fi

  if [[ -n "${note_token:-}" ]]; then
    printf "\n${GREEN}══════════════════════════════════════════════════════════════════════${NC}\n"
    printf "${GREEN}Bearer token (paste this into DustPan's VPS panel settings):${NC}\n"
    printf "${GREEN}${note_token}${NC}\n"
    printf "${GREEN}══════════════════════════════════════════════════════════════════════${NC}\n\n"
    printf "Token is also at $ETC_DIR/vps-agent.env (mode 640, group=$RUN_USER).\n"
  fi
}

action_uninstall() {
  step "Uninstalling yousirjuan-vps-agent"
  systemctl disable --now yousirjuan-vps-agent.service 2>/dev/null || true
  rm -f "$UNIT" "$LIB_DIR/vps-agent-server.sh"
  systemctl daemon-reload
  ok "agent removed (token preserved at $ETC_DIR/vps-agent.env — delete manually if rotating)"
}

action_status() {
  step "Status"
  echo "── systemd ────────────────────────────"
  systemctl status yousirjuan-vps-agent.service --no-pager 2>&1 | head -15
  echo
  echo "── /health ────────────────────────────"
  curl -sf -m 3 http://127.0.0.1:9878/health 2>&1 || echo "(unreachable)"
  echo
  echo "── /system (head) ─────────────────────"
  curl -sf -m 3 http://127.0.0.1:9878/system 2>/dev/null | python3 -m json.tool 2>/dev/null | head -20 || echo "(unreachable)"
  echo
  echo "── recent log ─────────────────────────"
  tail -10 /var/log/yousirjuan-vps-agent.log 2>/dev/null || echo "(no log)"
}

case "$action" in
  install)   action_install ;;
  uninstall) action_uninstall ;;
  status)    action_status ;;
  *) die "usage: sudo bash $0 {install|uninstall|status}" ;;
esac
