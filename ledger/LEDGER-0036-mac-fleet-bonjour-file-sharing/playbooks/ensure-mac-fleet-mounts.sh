#!/usr/bin/env bash
# Mount onemac/twomac shares via Bonjour hostnames; eject IP duplicates.
set -euo pipefail

SMB_USER="${MAC_FLEET_SMB_USER:-averygoodman}"
FLEET=(
  "onemac|onemac.local|SeverD|${HOME}/Volumes/onemac-severd"
  "twomac|twomac.local|Metal HD|${HOME}/Volumes/twomac-metal-hd"
)

mount_share() {
  local id="$1" host="$2" share="$3" mp="$4"
  local enc="${share// /%20}"
  ping -c1 -t2 "$host" >/dev/null 2>&1 || return 1
  mkdir -p "$mp"
  if mount | awk -v p="$mp" '$3==p && ($1 ~ host || $1 ~ id) {found=1} END{exit !found}' host="$host" id="$id"; then
    echo "✓ ${id} already mounted via ${host}"
    return 0
  fi
  diskutil unmount "$mp" 2>/dev/null || umount "$mp" 2>/dev/null || true
  mount_smbfs -o nobrowse,soft "//${SMB_USER}@${host}/${enc}" "$mp" 2>/dev/null \
    && { echo "✓ ${id} (${share}) via ${host}"; return 0; }
  open "smb://${SMB_USER}@${host}/${enc}" 2>/dev/null || true
}

echo "==> fleet Mac mounts (hostnames only)"
for row in "${FLEET[@]}"; do
  IFS='|' read -r id host share mp <<< "$row"
  mount_share "$id" "$host" "$share" "$mp" || true
done

while IFS= read -r mp; do
  [[ -z "$mp" ]] && continue
  diskutil unmount "$mp" 2>/dev/null || umount "$mp" 2>/dev/null || true
done < <(mount | awk '/\/\/.*@192\.168\.10\.(159|166)\// { gsub(/.* on /,""); gsub(/ .*/,""); print }')