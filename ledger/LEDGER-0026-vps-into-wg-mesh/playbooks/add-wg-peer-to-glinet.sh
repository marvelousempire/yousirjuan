#!/usr/bin/env bash
# add-wg-peer-to-glinet.sh — add a new WG peer to the GL-MT6000's wg0 server.
#
# Strictly AI-free. Idempotent: re-running with the same args is a no-op
# (existing peer detected via wg show).
#
# Usage:
#   bash add-wg-peer-to-glinet.sh --name <peer-name> --pubkey <base64-key> --wg-ip 10.0.0.X
#
# Requires: ssh access to root@192.168.8.1 (GL-MT6000 LAN admin).

set -euo pipefail

step()  { printf '\e[1;34m→\e[0m %s\n' "$*"; }
ok()    { printf '\e[1;32m✓\e[0m %s\n' "$*"; }
warn()  { printf '\e[1;33m!\e[0m %s\n' "$*"; }
die()   { printf '\e[1;31m✗\e[0m %s\n' "$*" >&2; exit 1; }

NAME=""
PUBKEY=""
WG_IP=""
SERVER_HOST="root@192.168.8.1"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name)    NAME="$2"; shift 2 ;;
    --pubkey)  PUBKEY="$2"; shift 2 ;;
    --wg-ip)   WG_IP="$2"; shift 2 ;;
    --server)  SERVER_HOST="$2"; shift 2 ;;
    --help|-h) sed -n '1,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)         die "Unknown arg: $1" ;;
  esac
done

[[ -n "$NAME" ]]   || die "--name is required"
[[ -n "$PUBKEY" ]] || die "--pubkey is required"
[[ -n "$WG_IP" ]]  || die "--wg-ip is required (e.g. 10.0.0.5)"

[[ "$PUBKEY" =~ ^[A-Za-z0-9+/]{43}=$ ]] || die "--pubkey must be a 44-char base64 WG public key"
[[ "$WG_IP" =~ ^10\.0\.0\.[0-9]+$ ]]    || die "--wg-ip must be a 10.0.0.X address"

step "Checking for existing peer on $SERVER_HOST..."
if ssh "$SERVER_HOST" "wg show wg0 | grep -q '$PUBKEY'" 2>/dev/null; then
  ok "Peer already exists in live interface — nothing to do."
  exit 0
fi

step "Adding peer to live wg0 interface..."
ssh "$SERVER_HOST" "wg set wg0 peer '$PUBKEY' allowed-ips '$WG_IP/32' persistent-keepalive 25"

step "Checking /etc/wireguard/wg0.conf for existing block..."
if ssh "$SERVER_HOST" "grep -q '$PUBKEY' /etc/wireguard/wg0.conf" 2>/dev/null; then
  ok "[Peer] block already in wg0.conf — skipping persist step."
else
  step "Appending [Peer] block to /etc/wireguard/wg0.conf..."
  ssh "$SERVER_HOST" "
    echo '' >> /etc/wireguard/wg0.conf
    echo '[Peer]' >> /etc/wireguard/wg0.conf
    echo '# $NAME' >> /etc/wireguard/wg0.conf
    echo 'AllowedIPs = $WG_IP/32' >> /etc/wireguard/wg0.conf
    echo 'PersistentKeepalive = 25' >> /etc/wireguard/wg0.conf
    K='$PUBKEY'
    echo \"PublicKey = \$K\" >> /etc/wireguard/wg0.conf
  "
fi

step "Verifying..."
ssh "$SERVER_HOST" "wg show wg0 | grep -A2 '$PUBKEY'"

ok "Peer $NAME ($WG_IP) added to GL-MT6000 wg0."
