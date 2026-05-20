#!/usr/bin/env bash
# install-tamer.sh — install/uninstall/status for the Watchdog Tamer.
#
# Installs two launchd jobs:
#   1. com.yousirjuan.watchdog-tamer        — runs tamer-tick.sh every 15 min
#   2. com.yousirjuan.watchdog-tamer-server — runs tamer-server.sh (KeepAlive)
#
# Both auto-on (RunAtLoad=true). Mirrors LEDGER-0007 + LEDGER-0008 install shape.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
PLAYBOOK_TICK="${REPO_ROOT}/ledger/LEDGER-0009-watchdog-tamer/playbooks/tamer-tick.sh"
PLAYBOOK_SERVER="${REPO_ROOT}/ledger/LEDGER-0009-watchdog-tamer/playbooks/tamer-server.sh"
PLIST_TICK_SRC="${REPO_ROOT}/ledger/LEDGER-0009-watchdog-tamer/artifacts/com.yousirjuan.watchdog-tamer.plist"
PLIST_SERVER_SRC="${REPO_ROOT}/ledger/LEDGER-0009-watchdog-tamer/artifacts/com.yousirjuan.watchdog-tamer-server.plist"
PLIST_TICK_DEST="${HOME}/Library/LaunchAgents/com.yousirjuan.watchdog-tamer.plist"
PLIST_SERVER_DEST="${HOME}/Library/LaunchAgents/com.yousirjuan.watchdog-tamer-server.plist"

LOG_FILE="${HOME}/yousirjuan-ledger.log"
exec > >(tee -a "$LOG_FILE") 2>&1

BLUE='\033[1;34m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; RED='\033[1;31m'; DIM='\033[2m'; NC='\033[0m'
step() { printf "${BLUE}→ %s${NC}\n" "$*"; }
note() { printf "${DIM}  %s${NC}\n" "$*"; }
ok()   { printf "${GREEN}✓ %s${NC}\n" "$*"; }
warn() { printf "${YELLOW}⚠ %s${NC}\n" "$*"; }
die()  { printf "${RED}✗ %s${NC}\n" "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

action_install() {
  step "Installing Watchdog Tamer (LEDGER-0009)"
  have curl    || die "curl missing"
  have python3 || die "python3 missing"
  [[ -x "$PLAYBOOK_TICK" ]]   || die "tamer-tick.sh not executable: $PLAYBOOK_TICK"
  [[ -x "$PLAYBOOK_SERVER" ]] || die "tamer-server.sh not executable: $PLAYBOOK_SERVER"

  # Pre-flight: confirm Ollama is reachable on localhost.
  if ! curl -sf -m 3 http://127.0.0.1:11434/api/tags >/dev/null; then
    warn "Ollama API not reachable on http://127.0.0.1:11434"
    note "  Tamer will fail every tick until Ollama is up."
    note "  Install per LEDGER-0001 (~/Developer/yousirjuan/ledger/LEDGER-0001-imac-mcp-setup/)."
  else
    ok "Ollama API reachable"
  fi

  # Materialize plists from templates.
  for entry in "$PLIST_TICK_SRC:$PLIST_TICK_DEST:$PLAYBOOK_TICK" \
               "$PLIST_SERVER_SRC:$PLIST_SERVER_DEST:$PLAYBOOK_SERVER"; do
    IFS=':' read -r src dest playbook <<<"$entry"
    [[ -f "$src" ]] || die "plist source missing: $src"
    sed -e "s|__PLAYBOOK_PATH__|$playbook|g" -e "s|__HOME__|$HOME|g" "$src" > "$dest"
    launchctl unload "$dest" 2>/dev/null || true
    launchctl load -w "$dest"
    ok "loaded $(basename "$dest")"
  done

  sleep 2
  if curl -sf -m 3 http://127.0.0.1:9877/health >/dev/null; then
    ok "tamer-server responding on http://127.0.0.1:9877"
  else
    warn "tamer-server did not respond on :9877 within 2s — check log"
    note "  tail ~/Library/Logs/yousirjuan-tamer-server.log"
  fi

  note "First analysis tick will fire on next launchd interval (15 min)."
  note "Force it now with:"
  note "  bash $PLAYBOOK_TICK"
}

action_uninstall() {
  step "Uninstalling Watchdog Tamer"
  for dest in "$PLIST_TICK_DEST" "$PLIST_SERVER_DEST"; do
    if [[ -f "$dest" ]]; then
      launchctl unload "$dest" 2>/dev/null || true
      rm -f "$dest"
      ok "removed $(basename "$dest")"
    fi
  done
  note "Watchdog (LEDGER-0007) + state server (LEDGER-0008) untouched."
  note "Suggestions JSON + history preserved at ~/Library/yousirjuan-state/"
}

action_status() {
  step "Status"
  echo "── launchd ──────────────────────────────"
  launchctl list | grep -E "com.yousirjuan.watchdog-tamer" || echo "  (not loaded)"
  echo
  echo "── tamer-server /health ─────────────────"
  curl -sf -m 3 http://127.0.0.1:9877/health 2>&1 || echo "(unreachable)"
  echo
  echo "── /suggestions (head) ──────────────────"
  curl -sf -m 3 http://127.0.0.1:9877/suggestions 2>/dev/null | jq '.' 2>/dev/null | head -30 || echo "(unreachable or empty)"
  echo
  echo "── recent tamer log (last 15 lines) ─────"
  tail -15 "${HOME}/Library/Logs/yousirjuan-watchdog-tamer.log" 2>/dev/null || echo "(no log yet)"
  echo
  echo "── recent server log (last 5 lines) ─────"
  tail -5 "${HOME}/Library/Logs/yousirjuan-tamer-server.log" 2>/dev/null || echo "(no log yet)"
}

action_tick() {
  bash "$PLAYBOOK_TICK"
}

action_logs() {
  tail -f "${HOME}/Library/Logs/yousirjuan-watchdog-tamer.log"
}

action_help() {
  cat <<EOF
Usage: $(basename "$0") {install|uninstall|status|tick|logs|help}

  install    — install + load both launchd jobs (tick + server)
  uninstall  — stop + unload + remove plists (data preserved)
  status     — launchd state, /health, /suggestions head, log tails
  tick       — force a single analysis tick now (calls tamer-tick.sh directly)
  logs       — tail the tamer analysis log
  help       — this message

Both jobs run on the iMac per ADR-0001 (Ollama lives where the RAM is, not on the VPS).
EOF
}

case "${1:-help}" in
  install)   action_install ;;
  uninstall) action_uninstall ;;
  status)    action_status ;;
  tick)      action_tick ;;
  logs)      action_logs ;;
  help|*)    action_help ;;
esac
