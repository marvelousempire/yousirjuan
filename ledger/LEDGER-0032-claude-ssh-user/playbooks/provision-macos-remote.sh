#!/usr/bin/env bash
# provision-macos-remote.sh — create local `claude` user on another Mac on the LAN.
#
# Usage:
#   bash provision-macos-remote.sh <label> <bootstrap_ssh>
#   bash provision-macos-remote.sh bigmac abrownsanta@bigmac.local
#
# Prereqs on the target Mac:
#   - System Settings → General → Sharing → Remote Login ON
#   - You can SSH as an admin user (password prompt is normal)
#
# Skips if `claude@<host>` already accepts your operator ed25519 key.

set -euo pipefail

LABEL="${1:?label (e.g. bigmac)}"
BOOTSTRAP="${2:?bootstrap_ssh (e.g. admin@bigmac.local)}"
HOST="${BOOTSTRAP#*@}"

ROOT="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=ssh-password-bootstrap.sh
source "$ROOT/ssh-password-bootstrap.sh"
MAC_CREATE="$ROOT/create-claude-user-mac.sh"
PUBKEY_FILE="${PUBKEY_FILE:-$HOME/.ssh/id_ed25519.pub}"

die() { printf '✗ %s\n' "$*" >&2; exit 1; }
[[ -f "$MAC_CREATE" ]] || die "Missing $MAC_CREATE"
[[ -f "$PUBKEY_FILE" ]] || die "Missing $PUBKEY_FILE"

PUBKEY=$(tr -d '\n\r' <"$PUBKEY_FILE")
PUBKEY_ESC=${PUBKEY//\'/\'\\\'\'}

if [[ ! -t 0 || ! -t 1 ]]; then
  die "Interactive Terminal required (password + sudo prompts). Run: bash ledger/LEDGER-0032-claude-ssh-user/playbooks/install-from-mac.sh ${LABEL}"
fi

printf '\n=== %s (%s) ===\n' "$LABEL" "$HOST"

if ssh -o BatchMode=yes -o ConnectTimeout=8 -o AddressFamily=inet -i "$HOME/.ssh/id_ed25519" "claude@${HOST}" 'whoami' 2>/dev/null | grep -q claude; then
  printf 'OK: claude@%s already has key access\n' "$HOST"
  exit 0
fi

printf 'Bootstrap via %s …\n' "$BOOTSTRAP"
ssh_password_bootstrap "$BOOTSTRAP" "$MAC_CREATE" \
  "sudo env USER_NAME=claude PUBKEY='${PUBKEY_ESC}' bash"

if ssh -o BatchMode=yes -o ConnectTimeout=8 -o AddressFamily=inet -i "$HOME/.ssh/id_ed25519" "claude@${HOST}" 'whoami' 2>/dev/null | grep -q claude; then
  printf 'OK: %s\n' "$LABEL"
else
  printf '! %s: claude user may exist but key login failed — try: ssh -o AddressFamily=inet claude@%s\n' "$LABEL" "$HOST"
  printf '  On %s: Remote Login ON; re-run or check /Users/claude/.ssh/authorized_keys\n' "$HOST"
  exit 1
fi
