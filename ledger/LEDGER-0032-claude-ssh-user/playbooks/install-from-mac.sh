#!/usr/bin/env bash
# install-from-mac.sh — push create-claude-user.sh to reachable hosts from the operator Mac.
#
# Usage:
#   cp ../artifacts/operator-hosts.env.example ../artifacts/operator-hosts.env  # first time
#   bash install-from-mac.sh              # all targets
#   bash install-from-mac.sh vps dgx      # subset: vps | dgx | mt6000 | ax1800 | nas | mac
#
# Prereqs: operator-hosts.env filled in; SSH as admin/root already works.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
ARTIFACTS="$(cd "$ROOT/../artifacts" && pwd)"
CREATE="$ROOT/create-claude-user.sh"
MAC_CREATE="$ROOT/create-claude-user-mac.sh"
ENV_FILE="${OPERATOR_HOSTS_ENV:-$ARTIFACTS/operator-hosts.env}"
PUBKEY_FILE="${PUBKEY_FILE:-$HOME/.ssh/id_ed25519.pub}"

die() { printf '✗ %s\n' "$*" >&2; exit 1; }
[[ -f "$CREATE" ]] || die "Missing $CREATE"
[[ -f "$PUBKEY_FILE" ]] || die "Missing $PUBKEY_FILE"

if [[ -f "$ENV_FILE" ]]; then
  # shellcheck source=/dev/null
  source "$ENV_FILE"
else
  printf '! No %s — using LAN placeholders only; set VPS_SSH / DGX_SSH in env file.\n' "$ENV_FILE" >&2
fi

# Placeholder LAN defaults (override in operator-hosts.env)
: "${INNER_GW:=192.168.8.1}"
: "${UPSTREAM_GW:=192.168.9.1}"
: "${NAS_HOST:=192.168.8.x}"

run_linux_simple() {
  local label=$1 ssh_target=$2 nopasswd=${3:-1} platform=${4:-auto}
  printf '\n=== %s (%s) ===\n' "$label" "$ssh_target"
  PUBKEY=$(tr -d '\n\r' <"$PUBKEY_FILE")
  ssh -o BatchMode=yes -o ConnectTimeout=12 "$ssh_target" \
    "sudo env USER_NAME=claude PUBKEY='$PUBKEY' NOPASSWD_SUDO=$nopasswd PLATFORM=$platform bash -s" <"$CREATE"
}

TARGETS=("${@:-vps dgx mt6000 ax1800 nas mac}")

for t in "${TARGETS[@]}"; do
  case "$t" in
    vps)
      [[ -n "${VPS_SSH:-}" ]] || die "Set VPS_SSH in $ENV_FILE (e.g. user@host, use -p in ssh config)"
      run_linux_simple vps \
        "-p ${VPS_SSH_PORT:-2222} -i ${HOME}/.ssh/id_ed25519 ${VPS_SSH}" \
        1 linux
      ;;
    dgx)
      DGX_SSH="${DGX_SSH:--i ${HOME}/.ssh/id_ed25519 your-dgx-user@your-dgx-host}"
      run_linux_simple dgx "$DGX_SSH" 1 linux
      ;;
    mt6000|ax6000|flint)
      MT6000_SSH="${MT6000_SSH:-claude@${INNER_GW}}"
      run_linux_simple gl-mt6000 \
        "-i ${HOME}/.ssh/id_ed25519 ${MT6000_SSH}" \
        0 openwrt
      ;;
    ax1800|slate)
      AX1800_SSH="${AX1800_SSH:-root@${UPSTREAM_GW}}"
      die "Use provision-ax1800-slate.sh for Slate (password bootstrap), or install claude manually on-router. Target: $AX1800_SSH"
      ;;
    nas)
      NAS_SSH="${NAS_SSH:-admin@${NAS_HOST}}"
      echo "NAS: trying $NAS_SSH (enable SSH in UGOS first)"
      run_linux_simple ugreen-nas \
        "-i ${HOME}/.ssh/id_ed25519 ${NAS_SSH}" \
        0 linux || echo "! NAS skipped — enable SSH in UGOS"
      ;;
    mac)
      bash "$MAC_CREATE"
      ;;
    *)
      die "Unknown target: $t (use vps dgx mt6000 ax1800 nas mac)"
      ;;
  esac
done

printf '\nAll requested targets finished.\n'
