#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source /etc/nas-mail-vault.env
mkdir -p "${NAS_MOUNT}"
if mountpoint -q "${NAS_MOUNT}"; then
  exit 0
fi
exec mount -t nfs4 -o _netdev,noatime,vers=4.1,hard,timeo=600,retrans=2 \
  "${NAS_HOST}:${NAS_NFS_EXPORT}" "${NAS_MOUNT}"
