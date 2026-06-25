#!/usr/bin/env bash
# Run ON onemac or twomac once — trust fivemac SSH key + admin-only File Sharing.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
FIVEMAC_PUB="${FIVEMAC_PUB:-ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB7PAUTyJN/3DtXL9E3gIjl3sjyIBftszxR760VZzYzM fivemac-averygoodman-2026-06-12}"
ADMIN_USER="${MAC_ADMIN_USER:-averygoodman}"

echo "==> Bootstrap $(scutil --get LocalHostName 2>/dev/null || hostname -s)"

mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
grep -qF "${FIVEMAC_PUB%% *}" "$HOME/.ssh/authorized_keys" 2>/dev/null || echo "$FIVEMAC_PUB" >> "$HOME/.ssh/authorized_keys"
chmod 600 "$HOME/.ssh/authorized_keys"

sudo MAC_ADMIN_USER="$ADMIN_USER" bash "$HERE/configure-mac-admin-file-sharing.sh"
sudo MAC_BONJOUR_NAME="$(scutil --get LocalHostName 2>/dev/null || hostname -s)" bash "$HERE/configure-mac-bonjour-name.sh"

echo "✓ Ready for fivemac SSH + SMB"