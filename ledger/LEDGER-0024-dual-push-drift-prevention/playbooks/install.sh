#!/usr/bin/env bash
# LEDGER-0024 — installer for the sync-and-drift systemd timer on the VPS.
# Idempotent: re-running upgrades the script + units in place.
set -euo pipefail

ACTION="${1:-install}"
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

INSTALL_DIR="/opt/yousirjuan-sync"
SERVICE="/etc/systemd/system/yousirjuan-dual-push-sync.service"
TIMER="/etc/systemd/system/yousirjuan-dual-push-sync.timer"

require_root() {
  [ "$EUID" -eq 0 ] || { echo "✗ must run as root (sudo bash $0 $ACTION)"; exit 1; }
}

cmd_install() {
  require_root
  mkdir -p "$INSTALL_DIR" /var/cache/yousirjuan-sync /var/lib/yousirjuan
  install -m 0755 "$HERE/sync-and-drift.sh" "$INSTALL_DIR/sync-and-drift.sh"
  install -m 0644 "$ROOT/artifacts/tracked-repos.txt" "$INSTALL_DIR/tracked-repos.txt"
  install -m 0644 "$ROOT/artifacts/yousirjuan-dual-push-sync.service" "$SERVICE"
  install -m 0644 "$ROOT/artifacts/yousirjuan-dual-push-sync.timer" "$TIMER"
  systemctl daemon-reload
  systemctl enable --now yousirjuan-dual-push-sync.timer
  echo "✓ installed; first sync runs within 5 min"
  systemctl list-timers yousirjuan-dual-push-sync.timer
}

cmd_uninstall() {
  require_root
  systemctl disable --now yousirjuan-dual-push-sync.timer 2>/dev/null || true
  rm -f "$SERVICE" "$TIMER"
  systemctl daemon-reload
  rm -rf "$INSTALL_DIR"
  echo "✓ uninstalled (drift report at /var/lib/yousirjuan/dual-push-drift-report.json kept for forensics)"
}

cmd_status() {
  systemctl status yousirjuan-dual-push-sync.timer --no-pager 2>&1 | head -10
  echo "---"
  systemctl status yousirjuan-dual-push-sync.service --no-pager 2>&1 | head -10
  echo "---"
  echo "Last report:"
  tail -5 /var/lib/yousirjuan/dual-push-drift-report.json 2>/dev/null || echo "(no report yet)"
}

case "$ACTION" in
  install)   cmd_install ;;
  uninstall) cmd_uninstall ;;
  status)    cmd_status ;;
  *) echo "usage: sudo bash $0 {install|uninstall|status}"; exit 1 ;;
esac
