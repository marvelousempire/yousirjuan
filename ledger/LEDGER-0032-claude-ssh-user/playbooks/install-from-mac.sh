#!/usr/bin/env bash
# install-from-mac.sh — push create-claude-user.sh to reachable hosts from the operator Mac.
#
# Usage:
#   cp ../artifacts/operator-hosts.env.example ../artifacts/operator-hosts.env  # first time
#   bash install-from-mac.sh              # all targets
#   bash install-from-mac.sh vps dgx      # subset: vps | dgx | mt6000 | ax1800 | nas | mac
#   bash install-from-mac.sh macs         # every Mac in operator-hosts.env (local + LAN)
#   bash install-from-mac.sh onemac bigmac twomac
#
# Prereqs: operator-hosts.env filled in; SSH as admin/root already works.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
ARTIFACTS="$(cd "$ROOT/../artifacts" && pwd)"
CREATE="$ROOT/create-claude-user.sh"
MAC_CREATE="$ROOT/create-claude-user-mac.sh"
MAC_REMOTE="$ROOT/provision-macos-remote.sh"
BOOTSTRAP_LIB="$ROOT/ssh-password-bootstrap.sh"

# Unified secret loading (tower-first for protection).
# Live secrets MUST live in a protected tower.env (chmod 600, outside any AI tree).
# AI agents are strictly forbidden from reading the real tower.env or operator-hosts.env.
TOWER_ENV_FILE="${TOWER_ENV:-${HOME}/.config/tower/tower.env}"
if [[ -f "$TOWER_ENV_FILE" ]]; then
  ENV_FILE="$TOWER_ENV_FILE"
elif [[ -n "${OPERATOR_HOSTS_ENV:-}" && -f "$OPERATOR_HOSTS_ENV" ]]; then
  ENV_FILE="$OPERATOR_HOSTS_ENV"
else
  ENV_FILE="$ARTIFACTS/operator-hosts.env"
fi
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

# Usage: run_linux_simple <label> <nopasswd> <platform> [ssh argv …]  (last argv is user@host)
run_linux_simple() {
  local label=$1 nopasswd=${2:-1} platform=${3:-auto}
  shift 3
  printf '\n=== %s (%s) ===\n' "$label" "${*: -1}"
  PUBKEY=$(tr -d '\n\r' <"$PUBKEY_FILE")
  local extra_env=""
  if [[ -n "${CLAUDE_PASSWORD:-}" ]]; then
    # Pass the default password for claude (from operator-hosts.env) so it gets set on the target
    extra_env=" CLAUDE_PASSWORD='${CLAUDE_PASSWORD}'"
  fi
  ssh -o BatchMode=yes -o ConnectTimeout=12 "$@" \
    "sudo env USER_NAME=claude PUBKEY='$PUBKEY' NOPASSWD_SUDO=$nopasswd PLATFORM=$platform${extra_env} bash -s" <"$CREATE"
}

provision_mac_remote() {
  local label=$1 bootstrap=$2
  local label_upper
  label_upper=$(printf '%s' "$label" | tr '[:lower:]' '[:upper:]')
  [[ -n "$bootstrap" ]] || die "Set MAC_${label_upper}_BOOTSTRAP in $ENV_FILE (e.g. admin@192.168.8.x)"
  bash "$MAC_REMOTE" "$label" "$bootstrap"
}

TARGETS=("${@:-vps dgx mt6000 ax1800 nas mac}")

for t in "${TARGETS[@]}"; do
  case "$t" in
    vps)
      [[ -n "${VPS_SSH:-}" ]] || die "Set VPS_SSH in $ENV_FILE (e.g. user@host, use -p in ssh config)"
      run_linux_simple vps 1 linux \
        -p "${VPS_SSH_PORT:-2222}" -i "${HOME}/.ssh/id_ed25519" "${VPS_SSH}"
      ;;
    dgx)
      DGX_SSH="${DGX_SSH:--i ${HOME}/.ssh/id_ed25519 your-dgx-user@your-dgx-host}"
      # shellcheck disable=SC2086
      run_linux_simple dgx 1 linux $DGX_SSH
      ;;
    mt6000|ax6000|flint)
      MT6000_SSH="${MT6000_SSH:-claude@${INNER_GW}}"
      run_linux_simple gl-mt6000 0 openwrt \
        -i "${HOME}/.ssh/id_ed25519" "${MT6000_SSH}"
      ;;
    ax1800|slate)
      AX1800_SSH="${AX1800_SSH:-root@${UPSTREAM_GW}}"
      die "Use provision-ax1800-slate.sh for Slate (password bootstrap), or install claude manually on-router. Target: $AX1800_SSH"
      ;;
    nas|nasa)
      # shellcheck source=ssh-password-bootstrap.sh
      source "$BOOTSTRAP_LIB"
      NAS_SSH_USER="${NAS_SSH_USER:-admin}"
      NAS_SSH="${NAS_SSH:-${NAS_SSH_USER}@${NAS_HOST}}"
      if [[ ! -t 0 || ! -t 1 ]]; then
        die "Interactive Terminal required for NAS bootstrap. Run: bash install-from-mac.sh nas"
      fi
      printf '\n=== ugreen-nas (%s) ===\n' "$NAS_SSH"
      printf 'UGOS SSH user must match your *web login* username (Control Panel → Terminal → SSH ON).\n'
      printf 'If password fails, fix NAS_SSH_USER in operator-hosts.env — it is often NOT literally "admin".\n'
      printf 'Preflight: ssh -o PubkeyAuthentication=no %s   OR (if key works) ssh %s\n' "$NAS_SSH" "$NAS_SSH"
      PUBKEY=$(tr -d '\n\r' <"$PUBKEY_FILE")
      PUBKEY_ESC=${PUBKEY//\'/\'\\\'\'}
      if ssh_can_batch "${NAS_SSH}"; then
        printf '→ NAS accepts your Mac SSH key as %s — only sudo password needed.\n' "$NAS_SSH_USER"
        ssh_key_bootstrap "${NAS_SSH}" "$CREATE" \
          "sudo env USER_NAME=claude PUBKEY='${PUBKEY_ESC}' NOPASSWD_SUDO=0 PLATFORM=linux bash" \
          || printf '! NAS failed at sudo — enter UGOS password when prompted\n'
        if ssh -o BatchMode=yes -o ConnectTimeout=8 -i "${HOME}/.ssh/id_ed25519" "claude@${NAS_HOST}" 'whoami' 2>/dev/null | grep -q claude; then
          printf 'OK: claude@%s\n' "$NAS_HOST"
        else
          printf '! Re-run: bash install-from-mac.sh nas (UGOS may need claude in admin group — script updated)\n'
        fi
      else
        ssh_password_bootstrap "${NAS_SSH}" "$CREATE" \
          "sudo env USER_NAME=claude PUBKEY='${PUBKEY_ESC}' NOPASSWD_SUDO=0 PLATFORM=linux bash" \
          || {
            printf '! NAS failed — wrong NAS_SSH_USER/password, SSH off in UGOS, or account locked.\n'
            printf '  Test: ssh -o PubkeyAuthentication=no %s\n' "$NAS_SSH"
          }
      fi
      ;;
    mac|onemac)
      bash "$MAC_CREATE"
      ;;
    bigmac)
      provision_mac_remote bigmac "${MAC_BIGMAC_BOOTSTRAP:-}" || printf '! bigmac bootstrap failed\n'
      ;;
    twomac)
      provision_mac_remote twomac "${MAC_TWOMAC_BOOTSTRAP:-}" || printf '! twomac bootstrap failed\n'
      ;;
    macs)
      bash "$MAC_CREATE"
      [[ -n "${MAC_BIGMAC_BOOTSTRAP:-}" ]] && provision_mac_remote bigmac "$MAC_BIGMAC_BOOTSTRAP" || echo "! bigmac skipped — set MAC_BIGMAC_BOOTSTRAP"
      [[ -n "${MAC_TWOMAC_BOOTSTRAP:-}" ]] && provision_mac_remote twomac "$MAC_TWOMAC_BOOTSTRAP" || echo "! twomac skipped — set MAC_TWOMAC_BOOTSTRAP"
      ;;
    *)
      die "Unknown target: $t (use vps dgx mt6000 ax1800 nas nasa mac onemac bigmac twomac macs)"
      ;;
  esac
done

printf '\nAll requested targets finished.\n'

# Optional: batch Members (human accounts) using the new add-member.sh
# Define in operator-hosts.env: MEMBERS="avery bobby ..."
if [[ -n "${MEMBERS:-}" ]]; then
  printf '\n=== MEMBERS list detected: %s ===\n' "$MEMBERS"
  for m in $MEMBERS; do
    printf '→ Adding member %s via add-member.sh (dgx vps by default)\n' "$m"
    bash "$ROOT/add-member.sh" "$m" dgx vps || printf ' ! %s failed (check pubkey/bootstrap)\n' "$m"
  done
fi
