#!/usr/bin/env bash
# setup-nas-dgx-storage.sh — UGOS NFS export + DGX mount (one shot from operator Mac).
#
# Usage:
#   bash setup-nas-dgx-storage.sh
#   NAS_PASSWORD='…' bash setup-nas-dgx-storage.sh   # non-interactive
#
# Requires: python3 + cryptography (pip install cryptography)

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
ARTIFACTS="$(cd "$ROOT/../artifacts" && pwd)"
ENV_FILE="${OPERATOR_HOSTS_ENV:-$ARTIFACTS/operator-hosts.env}"

if [[ -f "$ENV_FILE" ]]; then
  # shellcheck source=/dev/null
  source "$ENV_FILE"
fi

NAS_HOST="${NAS_HOST:-nasa.local}"
NAS_UGOS_API_PORT="${NAS_UGOS_API_PORT:-9443}"
NAS_SSH_USER="${NAS_SSH_USER:-abrownsanta}"
NAS_SHARE_NAME="${NAS_SHARE_NAME:-search-my-engine}"
NAS_NFS_CLIENT="${NAS_NFS_CLIENT:-192.168.8.0/24}"

die() { printf '✗ %s\n' "$*" >&2; exit 1; }

PYTHON="/usr/bin/python3"
if [[ "$(uname -s)" == Darwin ]]; then
  # Agent shells may run under Rosetta (uname -m=x86_64) while Python wheels are arm64.
  PYTHON="arch -arm64 /usr/bin/python3"
fi

if ! $PYTHON -c 'import cryptography' 2>/dev/null; then
  printf '→ Installing cryptography for UGOS API login…\n'
  $PYTHON -m pip install --user cryptography
  $PYTHON -c 'import cryptography' || die "python cryptography import failed after pip install"
fi

printf '=== Phase A — UGOS NFS export (%s) ===\n' "$NAS_SHARE_NAME"
if [[ -z "${NAS_PASSWORD:-}${UGOS_PASSWORD:-}" ]]; then
  if [[ -t 0 ]]; then
    read -r -s -p "UGOS password for ${NAS_SSH_USER}@${NAS_HOST}: " NAS_PASSWORD
    echo
    export NAS_PASSWORD
  else
    NAS_PASSWORD="$(/usr/bin/osascript 2>/dev/null <<APPLESCRIPT || true
display dialog "Enter UGOS web password for ${NAS_SSH_USER}@${NAS_HOST}" default answer "" with hidden answer with title "NAS NFS setup" buttons {"Cancel", "OK"} default button "OK"
text returned of result
APPLESCRIPT
)"
    export NAS_PASSWORD
  fi
fi
[[ -n "${NAS_PASSWORD:-}${UGOS_PASSWORD:-}" ]] || die "No UGOS password — set NAS_PASSWORD or run in Terminal for prompt"

$PYTHON "$ROOT/ugos-enable-nfs-export.py" \
  --host "$NAS_HOST" \
  --port "$NAS_UGOS_API_PORT" \
  --user "$NAS_SSH_USER" \
  --share "$NAS_SHARE_NAME" \
  --client "$NAS_NFS_CLIENT"

printf '\n=== Phase B — wait for export + mount on DGX ===\n'
bash "$ROOT/mount-nas-on-dgx.sh" --wait

printf '\nOK: NAS NFS + DGX mount complete\n'
