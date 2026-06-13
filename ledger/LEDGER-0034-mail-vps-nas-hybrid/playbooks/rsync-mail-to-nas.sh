#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
source /etc/nas-mail-vault.env

if ! mountpoint -q "${NAS_MOUNT}"; then
  echo "NAS not mounted — skip rsync" >&2
  exit 0
fi

install -d -m 0750 "${BACKUP_DEST}"
RSYNC_OPTS=(-aH --delete-delay --numeric-ids)
if command -v flock >/dev/null; then
  exec flock -n /var/lock/mail-rsync-to-nas.lock \
    rsync "${RSYNC_OPTS[@]}" "${MAIL_SRC}/" "${BACKUP_DEST}/"
fi
exec rsync "${RSYNC_OPTS[@]}" "${MAIL_SRC}/" "${BACKUP_DEST}/"
