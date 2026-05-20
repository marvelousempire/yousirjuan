#!/usr/bin/env bash
# install-state-server.sh — install/uninstall the watchdog state server as a launchd job
#
# Mirrors the shape of LEDGER-0007's install-watchdog.sh. Idempotent.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
PLAYBOOK="${REPO_ROOT}/ledger/LEDGER-0008-watchdog-control-surface/playbooks/watchdog-state-server.sh"
PLIST_SRC="${REPO_ROOT}/ledger/LEDGER-0008-watchdog-control-surface/artifacts/com.yousirjuan.watchdog-state-server.plist"
PLIST_DEST="${HOME}/Library/LaunchAgents/com.yousirjuan.watchdog-state-server.plist"
TOKEN_FILE="${HOME}/.config/yousirjuan/watchdog-server.env"

LOG_FILE="${HOME}/yousirjuan-ledger.log"
exec > >(tee -a "$LOG_FILE") 2>&1

BLUE='\033[1;34m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; RED='\033[1;31m'; DIM='\033[2m'; NC='\033[0m'
step() { printf "${BLUE}→ %s${NC}\n" "$*"; }
note() { printf "${DIM}  %s${NC}\n" "$*"; }
ok()   { printf "${GREEN}✓ %s${NC}\n" "$*"; }
warn() { printf "${YELLOW}⚠ %s${NC}\n" "$*"; }
die()  { printf "${RED}✗ %s${NC}\n" "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

label="com.yousirjuan.watchdog-state-server"

action_install() {
  step "Installing watchdog-state-server launchd job"
  have python3 || die "python3 not available — required for the state server"
  [[ -x "$PLAYBOOK" ]] || die "playbook not found / not executable: $PLAYBOOK"
  [[ -f "$PLIST_SRC" ]] || die "plist artifact not found: $PLIST_SRC"

  # Generate bearer token on first install only.
  if [[ ! -f "$TOKEN_FILE" ]]; then
    mkdir -p "$(dirname "$TOKEN_FILE")"
    chmod 700 "$(dirname "$TOKEN_FILE")"
    token="$(python3 -c 'import secrets; print(secrets.token_urlsafe(32))')"
    printf 'WATCHDOG_TOKEN=%s\n' "$token" > "$TOKEN_FILE"
    chmod 600 "$TOKEN_FILE"
    ok "generated bearer token at $TOKEN_FILE (chmod 600)"
    note "use this token in DustPan settings: WATCHDOG_TOKEN=$token"
  else
    note "$TOKEN_FILE already exists; reusing existing token"
  fi

  # Substitute repo path into plist (allows operator clone to a non-default location).
  sed -e "s|__PLAYBOOK_PATH__|$PLAYBOOK|g" \
      -e "s|__HOME__|$HOME|g" \
      "$PLIST_SRC" > "$PLIST_DEST"
  ok "wrote $PLIST_DEST"

  # Load (unload first to be idempotent).
  launchctl unload "$PLIST_DEST" 2>/dev/null || true
  launchctl load -w "$PLIST_DEST"
  ok "loaded (KeepAlive=true; RunAtLoad=true)"

  sleep 2
  if curl -sf -m 3 "http://127.0.0.1:9876/health" >/dev/null; then
    ok "server responding on http://127.0.0.1:9876/health"
  else
    warn "server did not respond on :9876 within 2s — check log"
    note "  tail ~/Library/Logs/yousirjuan-watchdog-server.log"
  fi
}

action_uninstall() {
  step "Uninstalling watchdog-state-server launchd job"
  if [[ -f "$PLIST_DEST" ]]; then
    launchctl unload "$PLIST_DEST" 2>/dev/null || true
    rm -f "$PLIST_DEST"
    ok "removed $PLIST_DEST"
  else
    note "plist not present, nothing to remove"
  fi
  note "watchdog itself (LEDGER-0007) is independent and still running"
  note "bearer token at $TOKEN_FILE preserved; remove manually if desired"
}

action_status() {
  step "Status"
  echo "── launchd ──────────────────────────────"
  launchctl list | grep "$label" || echo "  (not loaded)"
  echo
  echo "── /health ──────────────────────────────"
  curl -sf -m 3 "http://127.0.0.1:9876/health" 2>&1 || echo "(unreachable)"
  echo
  echo "── /state (head) ────────────────────────"
  curl -sf -m 3 "http://127.0.0.1:9876/state" 2>/dev/null | head -20 || echo "(unreachable)"
  echo
  echo "── /settings (head) ─────────────────────"
  curl -sf -m 3 "http://127.0.0.1:9876/settings" 2>/dev/null | head -20 || echo "(unreachable)"
  echo
  echo "── recent log (last 10 lines) ───────────"
  tail -10 "${HOME}/Library/Logs/yousirjuan-watchdog-server.log" 2>/dev/null || echo "(no log yet)"
}

action_logs() {
  tail -f "${HOME}/Library/Logs/yousirjuan-watchdog-server.log"
}

action_help() {
  cat <<EOF
Usage: $(basename "$0") {install|uninstall|status|logs|help}

  install    — generate token (first run), install + load launchd job
  uninstall  — stop + unload + remove plist (token preserved)
  status     — show launchd state + /health + /state head + log tail
  logs       — tail the server log
  help       — this message
EOF
}

case "${1:-help}" in
  install)   action_install ;;
  uninstall) action_uninstall ;;
  status)    action_status ;;
  logs)      action_logs ;;
  help|*)    action_help ;;
esac
