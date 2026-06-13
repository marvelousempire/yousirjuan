#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
source /etc/nas-mail-vault.env 2>/dev/null || {
  NAS_HOST=192.168.8.204
  NAS_NFS_EXPORT=/volume1/mailvault
  NAS_MOUNT=/mnt/nasmailvault
}

ok=0
fail=0

check() {
  local label="$1"
  shift
  if "$@"; then
    echo "g· ${label}"
    ok=$((ok + 1))
  else
    echo "r· ${label}"
    fail=$((fail + 1))
  fi
}

echo "=== Mail NAS hybrid preflight ==="
check "ping NAS ${NAS_HOST}" ping -c 1 -W 3 "${NAS_HOST}"
check "NFS port 2049" nc -z -w 3 "${NAS_HOST}" 2049
if systemctl is-active --quiet wg-quick@wg0 2>/dev/null || ip link show wg0 2>/dev/null | grep -q UP; then
  echo "g· WireGuard wg0"
  ok=$((ok + 1))
else
  echo "r· WireGuard wg0"
  fail=$((fail + 1))
fi
if mountpoint -q "${NAS_MOUNT}"; then
  echo "g· mountpoint ${NAS_MOUNT}"
  ok=$((ok + 1))
else
  echo "r· mountpoint ${NAS_MOUNT}"
  fail=$((fail + 1))
fi

echo "--- ${ok} passed, ${fail} failed ---"
[[ "${fail}" -eq 0 ]]
