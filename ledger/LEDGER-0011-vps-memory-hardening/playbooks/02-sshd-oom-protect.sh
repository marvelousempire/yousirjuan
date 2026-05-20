#!/usr/bin/env bash
# 02-sshd-oom-protect.sh — make sshd effectively OOM-unkillable.
#
# Today, sshd's oom_score_adj is 0 — same as every other process. That's
# why sshd was the first process to invoke the OOM killer (it became a
# victim too). With OOMScoreAdjust=-1000 the kernel never targets sshd.
#
# The drop-in is /etc/systemd/system/ssh.service.d/50-oom-protect.conf
# so it survives ssh package upgrades.

set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "must run as root (sudo)"; exit 1; }

DROPIN_DIR="/etc/systemd/system/ssh.service.d"
DROPIN_FILE="$DROPIN_DIR/50-oom-protect.conf"

BLUE='\033[1;34m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; RED='\033[1;31m'; NC='\033[0m'
step() { printf "${BLUE}→ %s${NC}\n" "$*"; }
ok()   { printf "${GREEN}✓ %s${NC}\n" "$*"; }
warn() { printf "${YELLOW}⚠ %s${NC}\n" "$*"; }
die()  { printf "${RED}✗ %s${NC}\n" "$*" >&2; exit 1; }

action="${1:-apply}"

# Some distros use ssh.service, others sshd.service. Detect.
detect_unit() {
  for unit in ssh.service sshd.service; do
    if systemctl list-unit-files "$unit" >/dev/null 2>&1 \
       && systemctl status "$unit" >/dev/null 2>&1; then
      echo "$unit"; return 0
    fi
  done
  die "neither ssh.service nor sshd.service found"
}

apply() {
  step "Applying sshd OOM protection"
  local unit; unit=$(detect_unit)

  # Override DROPIN_DIR if unit is sshd.service
  if [[ "$unit" == "sshd.service" ]]; then
    DROPIN_DIR="/etc/systemd/system/sshd.service.d"
    DROPIN_FILE="$DROPIN_DIR/50-oom-protect.conf"
  fi

  mkdir -p "$DROPIN_DIR"

  if [[ -f "$DROPIN_FILE" ]] && grep -q "OOMScoreAdjust=-1000" "$DROPIN_FILE"; then
    ok "drop-in already present at $DROPIN_FILE"
  else
    cat > "$DROPIN_FILE" <<'EOF'
# LEDGER-0011 — make sshd effectively OOM-unkillable so the operator can
# always SSH in even when the host is under severe memory pressure.
[Service]
OOMScoreAdjust=-1000
EOF
    ok "wrote $DROPIN_FILE"
  fi

  step "Reloading systemd + restarting $unit"
  systemctl daemon-reload
  systemctl restart "$unit"
  ok "$unit restarted with OOMScoreAdjust=-1000"

  step "Verifying"
  systemctl cat "$unit" | grep -i "OOMScoreAdjust" || warn "OOMScoreAdjust not in systemctl cat"
  local pid; pid=$(pidof sshd | tr ' ' '\n' | head -1 || true)
  if [[ -n "${pid:-}" ]]; then
    local score; score=$(cat "/proc/$pid/oom_score_adj")
    if [[ "$score" == "-1000" ]]; then
      ok "running sshd (pid $pid) has oom_score_adj = -1000"
    else
      warn "running sshd has oom_score_adj = $score (expected -1000)"
    fi
  fi
}

undo() {
  step "Reverting sshd OOM protection"
  local unit; unit=$(detect_unit)

  if [[ "$unit" == "sshd.service" ]]; then
    DROPIN_DIR="/etc/systemd/system/sshd.service.d"
    DROPIN_FILE="$DROPIN_DIR/50-oom-protect.conf"
  fi

  if [[ -f "$DROPIN_FILE" ]]; then
    rm -f "$DROPIN_FILE"
    ok "removed $DROPIN_FILE"
  else
    warn "no drop-in to remove"
  fi

  rmdir "$DROPIN_DIR" 2>/dev/null || true

  systemctl daemon-reload
  systemctl restart "$unit"
  ok "$unit restarted at default OOM priority"
}

case "$action" in
  apply|--apply|"")  apply ;;
  undo|--undo)       undo ;;
  *) die "usage: $0 [apply|undo]" ;;
esac
