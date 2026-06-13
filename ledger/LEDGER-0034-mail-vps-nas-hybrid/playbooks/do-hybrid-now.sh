#!/usr/bin/env bash
# Run from Mac on home LAN (nasa.local must resolve).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="${OPERATOR_HOSTS_ENV:-$(cd "$ROOT/../../LEDGER-0032-claude-ssh-user/artifacts" && pwd)/operator-hosts.env}"
[[ -f "$ENV_FILE" ]] && source "$ENV_FILE"

NAS_SSH="${NAS_SSH:-abrownsanta@nasa.local}"
VPS_SSH="${VPS_SSH:-clinic-vps}"
SHARE_PATH="${NAS_NFS_EXPORT:-/volume1/mailvault}"

die() { printf 'r· %s\n' "$*" >&2; exit 1; }

printf '=== LEDGER-0034 do-hybrid-now ===\n'

printf '\n[1/4] NAS mailvault + NFS…\n'
if ssh -o ConnectTimeout=15 -o BatchMode=yes "${NAS_SSH}" 'echo ok' 2>/dev/null; then
  ssh "${NAS_SSH}" 'bash -s' <"${ROOT}/setup-mailvault-on-nas.sh"
else
  printf 'y· Cannot SSH to %s from this Mac (off-LAN or mDNS).\n' "${NAS_SSH}"
  printf '   In your OPEN NAS shell (DXP4800PRO), run:\n'
  printf '   scp %s@%s:%s /tmp/ && bash /tmp/setup-mailvault-on-nas.sh\n' \
    "$(whoami)" "${MAC_PULL_HOST:-192.168.8.205}" "${ROOT}/setup-mailvault-on-nas.sh"
  printf '   Then enable NFS for mailvault in UGOS if the script warns.\n'
fi

printf '\n[2/4] Wait for NFS export…\n'
for i in $(seq 1 24); do
  if showmount -e nasa.local 2>/dev/null | grep -q mailvault; then
    break
  fi
  sleep 5
done
showmount -e nasa.local 2>/dev/null | grep -i mail || showmount -e nasa.local 2>/dev/null || true

printf '\n[3/4] VPS hybrid install…\n'
scp "${ROOT}/install-nas-hybrid.sh" "${ROOT}/preflight-nas-mail.sh" "${ROOT}/rsync-mail-to-nas.sh" \
  "${VPS_SSH}:/tmp/ledger-0034-mail-nas/"
ssh "${VPS_SSH}" "sudo NAS_NFS_EXPORT='${SHARE_PATH}' bash /tmp/ledger-0034-mail-nas/install-nas-hybrid.sh"

printf '\n[4/4] VPS preflight…\n'
ssh "${VPS_SSH}" 'sudo bash /opt/mail-jailynmarvin/playbooks/preflight-nas-mail.sh' || true

printf '\nDone.\n'
