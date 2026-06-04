#!/usr/bin/env bash
# mount-nas-on-dgx.sh — mount UGreen NFS export on DGX Spark from the operator Mac.
#
# Prereqs:
#   - UGOS NFS permission on shared folder search-my-engine for 192.168.8.0/24
#   - operator-hosts.env with DGX + NAS hostnames
#   - SSH to DGX as abrownsanta (IPv6 alias nephew-spark typical)
#
# Usage:
#   bash mount-nas-on-dgx.sh
#   bash mount-nas-on-dgx.sh --wait    # poll until export appears (after UGOS GUI)

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
ARTIFACTS="$(cd "$ROOT/../artifacts" && pwd)"
ENV_FILE="${OPERATOR_HOSTS_ENV:-$ARTIFACTS/operator-hosts.env}"

WAIT=0
[[ "${1:-}" == "--wait" ]] && WAIT=1

if [[ -f "$ENV_FILE" ]]; then
  # shellcheck source=/dev/null
  source "$ENV_FILE"
fi

NAS_HOST="${NAS_HOST:-nasa.local}"
NAS_EXPORT="${NAS_EXPORT:-/volume1/search-my-engine}"
MOUNT_POINT="${DGX_NAS_MOUNT:-/mnt/nas}"
DGX_SSH="${DGX_SSH:- -6 -i ${HOME}/.ssh/id_ed25519 abrownsanta@nephew-spark}"

die() { printf '✗ %s\n' "$*" >&2; exit 1; }

printf 'NAS export target: %s:%s\n' "$NAS_HOST" "$NAS_EXPORT"
printf 'DGX mount point:   %s\n' "$MOUNT_POINT"

if [[ "$WAIT" == 1 ]]; then
  printf 'Waiting for NFS export (enable in UGOS → search-my-engine → NFS permissions)…\n'
  for i in $(seq 1 60); do
    if showmount -e "$NAS_HOST" 2>/dev/null | grep -qF "$NAS_EXPORT"; then
      break
    fi
    sleep 5
  done
fi

if ! showmount -e "$NAS_HOST" 2>/dev/null | grep -qF "$NAS_EXPORT"; then
  die "Export not visible. In UGOS: File Manager → search-my-engine → Properties → NFS → add 192.168.8.0/24 rw. Then re-run with --wait"
fi

showmount -e "$NAS_HOST" | grep -F "$NAS_EXPORT" || true

# shellcheck disable=SC2086
ssh -o BatchMode=yes -o ConnectTimeout=15 $DGX_SSH bash -s <<REMOTE
set -euo pipefail
NAS_HOST='${NAS_HOST}'
NAS_EXPORT='${NAS_EXPORT}'
MOUNT_POINT='${MOUNT_POINT}'
FSTAB_LINE="\${NAS_HOST}:\${NAS_EXPORT} \${MOUNT_POINT} nfs rw,nofail,_netdev,x-systemd.automount 0 0"

sudo apt-get install -y nfs-common >/dev/null 2>&1 || true
sudo mkdir -p "\$MOUNT_POINT"

if mountpoint -q "\$MOUNT_POINT"; then
  echo "Already mounted: \$MOUNT_POINT"
else
  sudo mount -t nfs "\${NAS_HOST}:\${NAS_EXPORT}" "\$MOUNT_POINT"
fi

sudo touch "\${MOUNT_POINT}/.dgxprobe" && sudo rm -f "\${MOUNT_POINT}/.dgxprobe"
echo "rw probe OK on \$MOUNT_POINT"

if ! grep -qF "\${NAS_HOST}:\${NAS_EXPORT}" /etc/fstab 2>/dev/null; then
  echo "\$FSTAB_LINE" | sudo tee -a /etc/fstab >/dev/null
  echo "Added /etc/fstab entry"
else
  echo "fstab entry already present"
fi

# search-my-engine compose expects /mnt/nas-search (Plan 0048).
sudo ln -sfn "\$MOUNT_POINT" /mnt/nas-search
echo "Symlink /mnt/nas-search -> \$MOUNT_POINT"

mount | grep "\$MOUNT_POINT" || true
REMOTE

printf 'OK: DGX NFS mount at %s\n' "$MOUNT_POINT"
