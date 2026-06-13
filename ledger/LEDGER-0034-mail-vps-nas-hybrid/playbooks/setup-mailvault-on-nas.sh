#!/usr/bin/env bash
# Run ON the UGreen NAS (SSH shell) as admin — creates mailvault + NFS export for VPS WG.
set -euo pipefail

SHARE_NAME="${SHARE_NAME:-mailvault}"
VPS_WG_IP="${VPS_WG_IP:-10.0.0.5}"
LAN_CIDR="${LAN_CIDR:-192.168.8.0/24}"

echo "=== UGreen mailvault setup (LEDGER-0034) ==="

# Discover volume root (UGOS typical paths)
VOL=""
for d in /volume1 /volume2 /mnt/@usb/sda1; do
  [[ -d "$d" ]] && VOL="$d" && break
done
[[ -n "$VOL" ]] || { echo "No volume found under /volume1 or /volume2" >&2; exit 1; }

SHARE_PATH="${VOL}/${SHARE_NAME}"
sudo mkdir -p "${SHARE_PATH}/backup" "${SHARE_PATH}/live"
sudo chown -R "$(whoami):$(id -gn)" "${SHARE_PATH}" 2>/dev/null || true
echo "Share path: ${SHARE_PATH}"

# NFS exports — merge into /etc/exports if present
EXPORTS_FILE="/etc/exports"
if [[ -f "$EXPORTS_FILE" ]]; then
  sudo cp -a "$EXPORTS_FILE" "${EXPORTS_FILE}.bak.$(date +%Y%m%d%H%M%S)"
  if ! grep -qF "${SHARE_PATH}" "$EXPORTS_FILE" 2>/dev/null; then
    {
      echo "${SHARE_PATH} ${LAN_CIDR}(rw,sync,no_subtree_check,no_root_squash)"
      echo "${SHARE_PATH} ${VPS_WG_IP}(rw,sync,no_subtree_check,no_root_squash)"
    } | sudo tee -a "$EXPORTS_FILE" >/dev/null
    echo "Appended NFS rules to ${EXPORTS_FILE}"
  else
    echo "NFS export for ${SHARE_PATH} already in ${EXPORTS_FILE}"
  fi
  if command -v exportfs >/dev/null; then
    sudo exportfs -ra 2>/dev/null || sudo systemctl restart nfs-server 2>/dev/null || sudo systemctl restart nfs-kernel-server 2>/dev/null || true
  fi
else
  echo "y· No ${EXPORTS_FILE} — enable NFS in UGOS GUI for folder ${SHARE_NAME}"
  echo "   Clients: ${LAN_CIDR} and ${VPS_WG_IP}"
fi

# Show status
echo "---"
ls -la "${SHARE_PATH}" || true
command -v exportfs >/dev/null && sudo exportfs -v 2>/dev/null | grep -F "${SHARE_NAME}" || true
echo "NAS_NFS_EXPORT=${SHARE_PATH}"
echo "Done. On VPS set: NAS_NFS_EXPORT=${SHARE_PATH} then re-run install-nas-hybrid.sh"
