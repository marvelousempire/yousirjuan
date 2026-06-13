#!/usr/bin/env bash
# LEDGER-0034 — VPS mail hybrid: WG NFS mount + rsync backup to NAS
set -euo pipefail

MAIL_ROOT="${MAIL_ROOT:-/opt/mail-jailynmarvin}"
PLAYBOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

NAS_HOST="${NAS_HOST:-192.168.8.204}"
NAS_NFS_EXPORT="${NAS_NFS_EXPORT:-/volume1/mailvault}"
NAS_MOUNT="${NAS_MOUNT:-/mnt/nasmailvault}"
MAIL_SRC="${MAIL_SRC:-${MAIL_ROOT}/docker-data/dms/mail-data}"
BACKUP_DEST="${BACKUP_DEST:-${NAS_MOUNT}/backup/jailynmarvin-mail}"
LIVE_MAIL_ON_NAS="${LIVE_MAIL_ON_NAS:-0}"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run with sudo on clinic-vps." >&2
  exit 1
fi

apt-get install -y -qq nfs-common rsync >/dev/null 2>&1 || true

install -d -m 0755 "${NAS_MOUNT}"
install -d -m 0755 "${MAIL_ROOT}/playbooks"

for f in preflight-nas-mail.sh rsync-mail-to-nas.sh nas-mail-mount.sh; do
  install -m 0755 "${PLAYBOOK_DIR}/${f}" "${MAIL_ROOT}/playbooks/${f}"
done

cat >/etc/nas-mail-vault.env <<EOF
NAS_HOST=${NAS_HOST}
NAS_NFS_EXPORT=${NAS_NFS_EXPORT}
NAS_MOUNT=${NAS_MOUNT}
MAIL_SRC=${MAIL_SRC}
BACKUP_DEST=${BACKUP_DEST}
EOF
chmod 0644 /etc/nas-mail-vault.env

cat >/etc/systemd/system/nas-mail-mount.service <<'EOF'
[Unit]
Description=Mount UGreen mailvault NFS over WireGuard
After=network-online.target wg-quick@wg0.service
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
EnvironmentFile=/etc/nas-mail-vault.env
ExecStart=/opt/mail-jailynmarvin/playbooks/nas-mail-mount.sh
ExecStop=/bin/umount /mnt/nasmailvault

[Install]
WantedBy=multi-user.target
EOF

cat >/etc/systemd/system/mail-rsync-to-nas.service <<'EOF'
[Unit]
Description=Rsync jailynmarvin mail-data to NAS backup
After=nas-mail-mount.service
Requires=nas-mail-mount.service

[Service]
Type=oneshot
EnvironmentFile=/etc/nas-mail-vault.env
ExecStart=/opt/mail-jailynmarvin/playbooks/rsync-mail-to-nas.sh
EOF

cat >/etc/systemd/system/mail-rsync-to-nas.timer <<'EOF'
[Unit]
Description=Hourly mail backup to NAS

[Timer]
OnCalendar=hourly
Persistent=true
RandomizedDelaySec=300

[Install]
WantedBy=timers.target
EOF

systemctl disable nas-mail-vault.mount 2>/dev/null || true
rm -f /etc/systemd/system/nas-mail-vault.mount
systemctl daemon-reload
systemctl enable nas-mail-mount.service

if ! mountpoint -q "${NAS_MOUNT}"; then
  systemctl start nas-mail-mount.service 2>/dev/null || true
fi

install -d -m 0755 "${BACKUP_DEST}" 2>/dev/null || true

systemctl enable mail-rsync-to-nas.timer
if mountpoint -q "${NAS_MOUNT}"; then
  systemctl start mail-rsync-to-nas.timer
  systemctl start mail-rsync-to-nas.service || true
  echo "g· NAS mount up — rsync timer enabled"
else
  systemctl stop mail-rsync-to-nas.timer 2>/dev/null || true
  echo "y· NAS mount not up — timer installed but not started (finish UGOS NFS first)"
fi

if [[ "${LIVE_MAIL_ON_NAS}" == "1" ]]; then
  if ! mountpoint -q "${NAS_MOUNT}"; then
    echo "r· LIVE_MAIL_ON_NAS=1 but ${NAS_MOUNT} not mounted — aborting live move" >&2
    exit 1
  fi
  LIVE_DIR="${NAS_MOUNT}/live/mail-data"
  install -d -m 0750 "${LIVE_DIR}"
  if [[ -d "${MAIL_SRC}" ]] && [[ -z "$(ls -A "${LIVE_DIR}" 2>/dev/null)" ]]; then
    echo "Migrating mail-data to NAS (one-time copy)…"
    rsync -aH "${MAIL_SRC}/" "${LIVE_DIR}/"
  fi
  if [[ ! -L "${MAIL_SRC}" ]]; then
    mv "${MAIL_SRC}" "${MAIL_SRC}.vps-bak.$(date +%Y%m%d)"
    ln -sfn "${LIVE_DIR}" "${MAIL_SRC}"
    cd "${MAIL_ROOT}" && docker compose up -d --force-recreate
    echo "g· Live mail-data now on NAS via symlink"
  fi
fi

echo "Done. Preflight: sudo bash ${MAIL_ROOT}/playbooks/preflight-nas-mail.sh"
