#!/usr/bin/env bash
#
# install-watchdog.sh — install / uninstall / control the VPS watchdog launchd
# job on this iMac. Idempotent. Defaults to dry-run; flip to live via
# runbook 03.
#
# Actions:
#   install        copy plist + load launchd job (starts in DRY_RUN mode)
#   uninstall      unload + remove plist
#   status         show launchd state + last few log lines + state file
#   trigger        run one tick out-of-schedule (uses current DRY_RUN value)
#   logs           tail the watchdog log
#   help           print this

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARTIFACT="$SCRIPT_DIR/../artifacts/com.yousirjuan.vps-watchdog.plist"
PLIST_DST="$HOME/Library/LaunchAgents/com.yousirjuan.vps-watchdog.plist"
LOG_FILE="$HOME/Library/Logs/yousirjuan-vps-watchdog.log"
STATE_FILE="$HOME/Library/yousirjuan-state/vps-watchdog.json"
LEDGER_LOG="$HOME/yousirjuan-ledger.log"
LABEL="com.yousirjuan.vps-watchdog"

mkdir -p "$(dirname "$LEDGER_LOG")"
exec > >(tee -a "$LEDGER_LOG") 2>&1

BLUE='\033[1;34m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; RED='\033[1;31m'; NC='\033[0m'
step() { printf "${BLUE}→ %s${NC}\n" "$*"; }
ok()   { printf "${GREEN}  ✓ %s${NC}\n" "$*"; }
warn() { printf "${YELLOW}  ⚠ %s${NC}\n" "$*"; }
die()  { printf "${RED}  ✗ %s${NC}\n" "$*" >&2; exit 1; }

action_install() {
  step "Installing watchdog launchd job"
  [ -f "$ARTIFACT" ] || die "missing artifact at $ARTIFACT"
  mkdir -p "$(dirname "$PLIST_DST")" "$(dirname "$LOG_FILE")" "$(dirname "$STATE_FILE")"
  cp "$ARTIFACT" "$PLIST_DST"
  ok "wrote $PLIST_DST"

  launchctl unload "$PLIST_DST" 2>/dev/null || true
  launchctl load -w "$PLIST_DST"
  ok "loaded (StartInterval 180s; RunAtLoad fires once now)"

  echo ""
  warn "Default: DRY_RUN=1. Watchdog will probe + log but NOT call GoDaddy."
  warn "To go live, edit ledger/LEDGER-0007-imac-emergency-failsafe/playbooks/vps-watchdog.sh"
  warn "and set DRY_RUN=\"\${DRY_RUN:-0}\" (or run: DRY_RUN=0 launchctl ...)."
  warn "See runbook 03 — enabling-real-swap."
  echo ""
  step "Logs (give it a few seconds to fire once)…"
  sleep 5
  if [ -f "$LOG_FILE" ]; then
    tail -10 "$LOG_FILE"
  else
    warn "no log entries yet; try: bash $(basename "$0") logs"
  fi
}

action_uninstall() {
  step "Uninstalling watchdog"
  launchctl unload "$PLIST_DST" 2>/dev/null || true
  rm -f "$PLIST_DST"
  ok "removed $PLIST_DST"
  ok "state file preserved at $STATE_FILE (delete manually if desired)"
}

action_status() {
  echo "── launchd ──────────────────────────────"
  if launchctl list | grep -q "$LABEL"; then
    launchctl list | grep "$LABEL"
  else
    echo "  ✗ $LABEL not loaded"
  fi
  echo ""
  echo "── recent log (last 20 lines) ───────────"
  if [ -f "$LOG_FILE" ]; then
    tail -20 "$LOG_FILE"
  else
    echo "  (no log file yet)"
  fi
  echo ""
  echo "── state ─────────────────────────────────"
  if [ -f "$STATE_FILE" ]; then
    python3 -m json.tool < "$STATE_FILE" 2>/dev/null || cat "$STATE_FILE"
  else
    echo "  (no state file yet — will appear after first tick)"
  fi
}

action_trigger() {
  step "Running watchdog once (out of schedule)"
  launchctl start "$LABEL"
  sleep 3
  step "Latest log lines:"
  tail -15 "$LOG_FILE" 2>/dev/null || true
}

action_logs() { tail -f "$LOG_FILE" 2>&1; }

action_help() {
  cat <<EOF
Usage: $0 <action>
  install        copy plist + load launchd (starts in DRY_RUN)
  uninstall      unload + remove plist (state preserved)
  status         launchd state + tail log + state JSON
  trigger        run one tick out-of-schedule
  logs           tail -f the log
  help           this
EOF
}

case "${1:-help}" in
  install)        action_install ;;
  uninstall)      action_uninstall ;;
  status)         action_status ;;
  trigger)        action_trigger ;;
  logs)           action_logs ;;
  help|-h|--help) action_help ;;
  *) echo "Unknown action: $1" >&2; action_help; exit 1 ;;
esac
