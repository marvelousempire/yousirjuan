#!/usr/bin/env bash
#
# install-standby.sh — set up the iMac warm-standby GitLab from the canonical
# artifacts. Idempotent. Actions: install / uninstall / status / start / stop /
# trigger-sync / trigger-restore / help.
#
# Prerequisites the OPERATOR handles (cannot be automated):
#   1. OrbStack (or Docker Desktop) installed and running on the iMac.
#      Recommended: `brew install --cask orbstack`
#   2. Tailscale logged in (Tailscale.app → Sign In). Standby reachability
#      assumes tailnet hostname imac-avery.tailaa31dd.ts.net resolves.
#   3. macOS Energy Saver: never sleep + wake-for-network. The standby is
#      useless if the iMac is asleep. System Settings → Battery → Options.
#
# Variables (override via env):
#   STANDBY_DIR        — where the docker-compose lives (default: $HOME/Developer/gitlab-standby)
#   STANDBY_DATA_ROOT  — host path for GitLab volumes (default: $HOME/Library/GitLab-Data)
#   VPS_HOST           — primary VPS for backup pulls (default: 72.167.151.251)
#   VPS_USER           — SSH user on the VPS (default: abrownsanta)
#   VPS_PORT           — SSH port (default: 2222)

set -euo pipefail

STANDBY_DIR="${STANDBY_DIR:-$HOME/Developer/gitlab-standby}"
STANDBY_DATA_ROOT="${STANDBY_DATA_ROOT:-$HOME/Library/GitLab-Data}"
VPS_HOST="${VPS_HOST:-72.167.151.251}"
VPS_USER="${VPS_USER:-abrownsanta}"
VPS_PORT="${VPS_PORT:-2222}"
LEDGER_LOG="$HOME/yousirjuan-ledger.log"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARTIFACTS_DIR="$SCRIPT_DIR/../artifacts"
SYNC_PLIST="$HOME/Library/LaunchAgents/com.yousirjuan.gitlab-standby-sync.plist"
RESTORE_PLIST="$HOME/Library/LaunchAgents/com.yousirjuan.gitlab-standby-restore.plist"

mkdir -p "$(dirname "$LEDGER_LOG")"
exec > >(tee -a "$LEDGER_LOG") 2>&1

BLUE='\033[1;34m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; RED='\033[1;31m'; DIM='\033[2m'; NC='\033[0m'
step() { printf "${BLUE}→ %s${NC}\n" "$*"; }
note() { printf "${DIM}  %s${NC}\n" "$*"; }
ok()   { printf "${GREEN}  ✓ %s${NC}\n" "$*"; }
warn() { printf "${YELLOW}  ⚠ %s${NC}\n" "$*"; }
die()  { printf "${RED}  ✗ %s${NC}\n" "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

check_prereqs() {
  local missing=0
  have docker        || { warn "docker not on PATH (install OrbStack: brew install --cask orbstack)"; missing=1; }
  have rsync         || { warn "rsync not on PATH (install via brew or it's likely already there)"; missing=1; }
  if have tailscale; then
    tailscale status 2>/dev/null | grep -q "imac-avery" || warn "tailscale logged out or imac-avery hostname not set"
  else
    have /Applications/Tailscale.app/Contents/MacOS/Tailscale || warn "tailscale not installed"
  fi
  [ $missing -eq 0 ]
}

action_install() {
  step "Installing GitLab warm-standby on this iMac"
  check_prereqs || die "Prerequisites missing — see operator checklist at top of this script"

  step "Creating directories"
  mkdir -p "$STANDBY_DIR"
  mkdir -p "$STANDBY_DATA_ROOT"/{config,data,logs,data/backups}
  ok "$STANDBY_DIR + $STANDBY_DATA_ROOT layout ready"

  step "Copying canonical docker-compose.yml from ledger"
  if [ ! -f "$ARTIFACTS_DIR/docker-compose.yml" ]; then
    die "canonical compose missing at $ARTIFACTS_DIR/docker-compose.yml"
  fi
  cp "$ARTIFACTS_DIR/docker-compose.yml" "$STANDBY_DIR/docker-compose.yml"
  ok "wrote $STANDBY_DIR/docker-compose.yml"

  step "Installing LaunchAgent plists"
  mkdir -p "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"
  cp "$ARTIFACTS_DIR/com.yousirjuan.gitlab-standby-sync.plist" "$SYNC_PLIST"
  cp "$ARTIFACTS_DIR/com.yousirjuan.gitlab-standby-restore.plist" "$RESTORE_PLIST"
  launchctl unload "$SYNC_PLIST" 2>/dev/null || true
  launchctl unload "$RESTORE_PLIST" 2>/dev/null || true
  launchctl load -w "$SYNC_PLIST"
  launchctl load -w "$RESTORE_PLIST"
  ok "launchd plists installed + loaded"

  step "Starting GitLab standby container (first run pulls ~2 GB)"
  (cd "$STANDBY_DIR" && docker compose pull && docker compose up -d)
  ok "container starting; first boot takes 3-5 min for Puma + Postgres init"
  note "watch progress: docker logs -f gitlab-standby"
  note "verify ready:  curl -sI http://localhost:8929/"

  echo ""
  ok "Standby install complete. Next: wait for first nightly backup sync (08:00 UTC) + restore (09:00 UTC)."
}

action_uninstall() {
  step "Stopping container"
  (cd "$STANDBY_DIR" && docker compose down) 2>/dev/null || true
  step "Unloading LaunchAgents"
  launchctl unload "$SYNC_PLIST" 2>/dev/null || true
  launchctl unload "$RESTORE_PLIST" 2>/dev/null || true
  rm -f "$SYNC_PLIST" "$RESTORE_PLIST"
  ok "unloaded + removed plists"
  note "Data preserved at $STANDBY_DATA_ROOT — delete manually if you want a clean wipe:"
  note "  rm -rf $STANDBY_DATA_ROOT"
}

action_status() {
  echo "── prerequisites ────────────────────────"
  check_prereqs || true
  echo "── standby container ────────────────────"
  if docker ps --format '{{.Names}} {{.Status}}' | grep -q '^gitlab-standby'; then
    docker ps --format '  ✓ {{.Names}} {{.Status}} → {{.Ports}}' | grep gitlab-standby
  else
    echo "  ✗ gitlab-standby container not running"
  fi
  echo "── standby HTTP ─────────────────────────"
  if curl -sI -m 5 http://localhost:8929/ 2>/dev/null | head -1 | grep -q "HTTP"; then
    echo "  ✓ localhost:8929 responding"
  else
    echo "  ✗ localhost:8929 not responding"
  fi
  echo "── launchd agents ───────────────────────"
  for label in com.yousirjuan.gitlab-standby-sync com.yousirjuan.gitlab-standby-restore; do
    if launchctl list | grep -q "$label"; then
      echo "  ✓ $label loaded"
    else
      echo "  ✗ $label not loaded"
    fi
  done
  echo "── latest backup synced ─────────────────"
  ls -lh "$STANDBY_DATA_ROOT/data/backups/"*.tar 2>/dev/null | tail -1 || echo "  ✗ no backups synced yet"
  echo "── tailnet ──────────────────────────────"
  /Applications/Tailscale.app/Contents/MacOS/Tailscale status 2>&1 | grep -E "imac-avery|Logged out" | head -3 || true
}

action_start()           { (cd "$STANDBY_DIR" && docker compose up -d); }
action_stop()            { (cd "$STANDBY_DIR" && docker compose down); }
action_trigger_sync()    { launchctl start com.yousirjuan.gitlab-standby-sync; ok "sync triggered (out-of-schedule)"; }
action_trigger_restore() { launchctl start com.yousirjuan.gitlab-standby-restore; ok "restore triggered (out-of-schedule)"; }

action_help() {
  cat <<EOF
Usage: $0 <action>
  install           full setup (compose + launchd + container up)
  uninstall         tear down (preserves data)
  status            show state of every piece
  start | stop      docker compose up/down
  trigger-sync      run the backup-sync now (out of schedule)
  trigger-restore   run the restore now (DESTRUCTIVE on standby)
  help              this
EOF
}

case "${1:-help}" in
  install)          action_install ;;
  uninstall)        action_uninstall ;;
  status)           action_status ;;
  start)            action_start ;;
  stop)             action_stop ;;
  trigger-sync)     action_trigger_sync ;;
  trigger-restore)  action_trigger_restore ;;
  help|-h|--help)   action_help ;;
  *) echo "Unknown action: $1" >&2; action_help; exit 1 ;;
esac
