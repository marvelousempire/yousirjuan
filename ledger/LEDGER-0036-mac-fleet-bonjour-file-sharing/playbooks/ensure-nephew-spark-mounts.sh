#!/usr/bin/env bash
# Mount nephew-spark SMB shares via Bonjour hostname (not raw IP).
set -euo pipefail

SPARK_HOST="${NEPHEW_SPARK_HOST:-nephew-spark.local}"
SMB_USER="${NEPHEW_SPARK_SMB_USER:-abrownsanta}"
SMB_KEYCHAIN="${NEPHEW_SPARK_SMB_KEYCHAIN:-nephew-spark-smb}"
MOUNT_DEV="${HOME}/Volumes/nephew-developer"
MOUNT_HOME="${HOME}/Volumes/nephew-spark-home"

smb_password() {
  security find-generic-password -s "$SMB_KEYCHAIN" -a "$SMB_USER" -w 2>/dev/null || true
}

mount_share() {
  local share="$1" mount_path="$2"
  local pw url
  pw="$(smb_password)"
  mkdir -p "$mount_path"
  if mount | awk -v p="$mount_path" '$3==p && $1 ~ /nephew-spark/ {found=1} END{exit !found}'; then
    echo "✓ ${share} already mounted via ${SPARK_HOST}"
    return 0
  fi
  diskutil unmount "$mount_path" 2>/dev/null || umount "$mount_path" 2>/dev/null || true
  if [[ -n "$pw" ]]; then
    url="//${SMB_USER}:${pw}@${SPARK_HOST}/${share}"
    mount_smbfs -o nobrowse,soft "$url" "$mount_path" 2>/dev/null && { echo "✓ ${share} → ${mount_path}"; return 0; }
  fi
  url="//${SMB_USER}@${SPARK_HOST}/${share}"
  mount_smbfs -o nobrowse,soft "$url" "$mount_path" 2>/dev/null && { echo "✓ ${share} → ${mount_path}"; return 0; }
  open "smb://${SMB_USER}@${SPARK_HOST}/${share}" 2>/dev/null || true
  return 1
}

ping -c1 -t2 "$SPARK_HOST" >/dev/null || { echo "nephew-spark unreachable" >&2; exit 1; }
echo "==> nephew-spark mounts via ${SPARK_HOST}"
mount_share Developer "$MOUNT_DEV"
mount_share abrownsanta "$MOUNT_HOME" || true