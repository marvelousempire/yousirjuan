#!/usr/bin/env bash
# install-alert-watch.sh — install/uninstall the iMac-side macOS notification daemon.
# Runs as the user (no sudo). launchd plist persists across reboots.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
PLAYBOOK="${REPO_ROOT}/ledger/LEDGER-0015-server-stability-suite/playbooks/alert-watch.sh"
PLIST_SRC="${REPO_ROOT}/ledger/LEDGER-0015-server-stability-suite/artifacts/com.yousirjuan.alert-watch.plist"
PLIST_DEST="${HOME}/Library/LaunchAgents/com.yousirjuan.alert-watch.plist"

LOG_FILE="${HOME}/yousirjuan-ledger.log"
exec > >(tee -a "$LOG_FILE") 2>&1

BLUE='\033[1;34m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
step() { printf "${BLUE}→ %s${NC}\n" "$*"; }
ok()   { printf "${GREEN}✓ %s${NC}\n" "$*"; }
warn() { printf "${YELLOW}⚠ %s${NC}\n" "$*"; }

action="${1:-install}"
case "$action" in
  install)
    step "Installing alert-watch (LEDGER-0015 iMac side)"
    [[ -x "$PLAYBOOK" ]] || chmod +x "$PLAYBOOK"
    sed -e "s|__PLAYBOOK_PATH__|$PLAYBOOK|g" -e "s|__HOME__|$HOME|g" "$PLIST_SRC" > "$PLIST_DEST"
    launchctl unload "$PLIST_DEST" 2>/dev/null || true
    launchctl load -w "$PLIST_DEST"
    ok "loaded $(basename "$PLIST_DEST")"
    ok "polling http://vps-godaddy:9878/all every 60s"
    ok "macOS will show notifications when: mem>85% OR swap>50% OR load>16 OR any subdomain 5xx/000"
    ok "debounced 5 min per threshold"

    step "  test fire (one tick now)"
    bash "$PLAYBOOK" --once 2>&1 | head -5
    ;;
  uninstall)
    launchctl unload "$PLIST_DEST" 2>/dev/null || true
    rm -f "$PLIST_DEST"
    ok "removed alert-watch launchd job"
    ;;
  status)
    launchctl list | grep com.yousirjuan.alert-watch || echo "(not loaded)"
    echo
    echo "── recent log ──"
    tail -15 "$HOME/Library/Logs/yousirjuan-alert-watch.log" 2>/dev/null || echo "(no log yet)"
    ;;
  test)
    bash "$PLAYBOOK" --once
    ;;
  *) echo "usage: $0 {install|uninstall|status|test}"; exit 1;;
esac
