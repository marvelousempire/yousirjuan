#!/usr/bin/env bash
# 03-double-swap.sh — resize /swapfile from 4 GB to 8 GB.
#
# Idempotent: skips if /swapfile is already ≥ 8 GB.
# Reversible: --undo shrinks back to 4 GB.
#
# More swap is not a license to thrash. Swap thrash is bad. But running out
# of swap during a memory spike is WORSE — that's when OOM-killer fires
# and kills sshd / dbus / GitLab workers. 8 GB gives the kernel more room
# to dehydrate idle pages before resorting to kills.

set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "must run as root (sudo)"; exit 1; }

SWAPFILE="/swapfile"
TARGET_GB=8

BLUE='\033[1;34m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; RED='\033[1;31m'; NC='\033[0m'
step() { printf "${BLUE}→ %s${NC}\n" "$*"; }
ok()   { printf "${GREEN}✓ %s${NC}\n" "$*"; }
warn() { printf "${YELLOW}⚠ %s${NC}\n" "$*"; }
die()  { printf "${RED}✗ %s${NC}\n" "$*" >&2; exit 1; }

action="${1:-apply}"

current_size_gb() {
  if [[ ! -f "$SWAPFILE" ]]; then echo 0; return; fi
  local bytes; bytes=$(stat -c '%s' "$SWAPFILE")
  echo $(( bytes / 1024 / 1024 / 1024 ))
}

resize() {
  local target_gb="$1"
  step "Resizing $SWAPFILE to ${target_gb} GB"

  # Check disk free.
  local free_gb; free_gb=$(df -BG --output=avail / | tail -1 | tr -d 'G ')
  local need_gb=$(( target_gb + 5 ))   # 5 GB margin for safety
  if [[ "$free_gb" -lt "$need_gb" ]]; then
    die "not enough free space on / : need ${need_gb}G, have ${free_gb}G"
  fi

  step "  swapoff"
  swapoff "$SWAPFILE" 2>&1 | head -3 || true

  step "  allocating new swapfile (this writes ${target_gb} GB; takes ~30-60s)"
  rm -f "$SWAPFILE"
  fallocate -l "${target_gb}G" "$SWAPFILE" || \
    dd if=/dev/zero of="$SWAPFILE" bs=1M count=$(( target_gb * 1024 )) status=progress
  chmod 600 "$SWAPFILE"

  step "  mkswap + swapon"
  mkswap "$SWAPFILE" >/dev/null
  swapon "$SWAPFILE"

  # Ensure /etc/fstab has the entry.
  if ! grep -q "^${SWAPFILE}" /etc/fstab; then
    echo "${SWAPFILE} none swap sw 0 0" >> /etc/fstab
    ok "added to /etc/fstab"
  fi

  ok "swap resized; new state:"
  free -h | grep -i swap
}

apply() {
  step "Checking current swap size"
  local current; current=$(current_size_gb)
  ok "current $SWAPFILE = ${current} GB; target = ${TARGET_GB} GB"

  if [[ "$current" -ge "$TARGET_GB" ]]; then
    ok "already ${current} GB — no change needed (idempotent)"
    return 0
  fi

  resize "$TARGET_GB"
}

undo() {
  step "Reverting swap to 4 GB"
  local current; current=$(current_size_gb)
  if [[ "$current" -le 4 ]]; then
    warn "already at ${current} GB — no change"
    return 0
  fi
  resize 4
}

case "$action" in
  apply|--apply|"")  apply ;;
  undo|--undo)       undo ;;
  *) die "usage: $0 [apply|undo]" ;;
esac
