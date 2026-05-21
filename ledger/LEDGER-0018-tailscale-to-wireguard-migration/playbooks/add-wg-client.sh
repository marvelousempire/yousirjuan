#!/usr/bin/env bash
# add-wg-client.sh — generate a WireGuard client config + QR code, append the
# peer block to /etc/wireguard/wg0.conf, and reload the server.
#
# Per LEDGER-0018. Run on the VPS as root.
#
# Usage:
#   sudo bash add-wg-client.sh --name <peer-name> [--ip 10.100.0.X] [--subnet 192.168.1.0/24]
#
#   --name      mandatory; used for filenames + comment
#   --ip        optional; default = next free address in 10.100.0.0/24
#   --subnet    optional; if the peer is a subnet router, its LAN CIDR
#               (added to AllowedIPs on the SERVER's view of this peer)

set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "must run as root (sudo)"; exit 1; }

NAME=""
PEER_IP=""
PEER_SUBNET=""
WG_PORT="${WG_PORT:-51820}"
WG_NET_BASE="10.100.0"
SERVER_ENDPOINT="${SERVER_ENDPOINT:-72.167.151.251}"
SERVER_CONF="/etc/wireguard/wg0.conf"
SERVER_PUB="/etc/wireguard/server-public.key"
CLIENTS_DIR="/etc/wireguard/clients"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name)    NAME="$2"; shift 2;;
    --ip)      PEER_IP="$2"; shift 2;;
    --subnet)  PEER_SUBNET="$2"; shift 2;;
    *) echo "unknown arg: $1"; exit 1;;
  esac
done

[[ -n "$NAME" ]] || { echo "--name required"; exit 1; }
[[ "$NAME" =~ ^[a-z0-9-]+$ ]] || { echo "name must match [a-z0-9-]+"; exit 1; }
[[ -f "$SERVER_CONF" ]] || { echo "$SERVER_CONF missing — run install-wg-server.sh first"; exit 1; }

mkdir -p "$CLIENTS_DIR"
chmod 700 "$CLIENTS_DIR"

# Find next free IP if not specified
if [[ -z "$PEER_IP" ]]; then
  used=$(grep -oE "${WG_NET_BASE}\.[0-9]+/32" "$SERVER_CONF" | grep -oE "[0-9]+/32" | grep -oE "^[0-9]+" || true)
  next=10
  for n in $used; do (( n >= next )) && next=$((n + 1)); done
  PEER_IP="${WG_NET_BASE}.${next}"
fi

# Generate peer keypair
peer_priv=$(wg genkey)
peer_pub=$(echo "$peer_priv" | wg pubkey)
peer_psk=$(wg genpsk)

SERVER_PUBLIC=$(cat "$SERVER_PUB")

# Compose client config
client_allowed_ips="${WG_NET_BASE}.0/24"
# Optionally route ALL traffic through tunnel (operator can edit):
# client_allowed_ips="0.0.0.0/0, ::/0"

cat > "$CLIENTS_DIR/${NAME}.conf" <<EOF
# LEDGER-0018 WireGuard client config for "${NAME}"
# Generated $(date -Iseconds)
# Server: ${SERVER_ENDPOINT}:${WG_PORT}

[Interface]
PrivateKey = ${peer_priv}
Address = ${PEER_IP}/24
DNS = 1.1.1.1, 9.9.9.9

[Peer]
PublicKey = ${SERVER_PUBLIC}
PresharedKey = ${peer_psk}
Endpoint = ${SERVER_ENDPOINT}:${WG_PORT}
AllowedIPs = ${client_allowed_ips}
PersistentKeepalive = 25
EOF
chmod 600 "$CLIENTS_DIR/${NAME}.conf"

# Append peer block to server conf
{
  echo
  echo "# peer: ${NAME} — added $(date -Iseconds)"
  echo "[Peer]"
  echo "PublicKey = ${peer_pub}"
  echo "PresharedKey = ${peer_psk}"
  echo "AllowedIPs = ${PEER_IP}/32${PEER_SUBNET:+, $PEER_SUBNET}"
} >> "$SERVER_CONF"

# Reload server config
wg syncconf wg0 <(wg-quick strip wg0)

# QR code for mobile
if command -v qrencode >/dev/null 2>&1; then
  qrencode -t ansiutf8 < "$CLIENTS_DIR/${NAME}.conf"
fi

cat <<EOF

══════════════════════════════════════════════════════════════════════
Peer "${NAME}" added.
══════════════════════════════════════════════════════════════════════
  WG IP:       ${PEER_IP}
  Subnet route: ${PEER_SUBNET:-(none)}
  Config:       $CLIENTS_DIR/${NAME}.conf

To install on the peer:
  - Mobile (iOS/Android): scan QR above OR transfer the .conf via secure channel
  - Mac/Linux:     wg-quick up <copy of .conf>
  - GL.iNet AX1800/AX600: paste .conf in VPN → WireGuard Client → New

After install, on the peer:
  ping ${WG_NET_BASE}.1     # → reachable means tunnel works
  curl -sI -m 3 http://${WG_NET_BASE}.1:9878/health    # → reaches the LEDGER-0012 agent over WG

══════════════════════════════════════════════════════════════════════
EOF
