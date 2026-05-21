#!/usr/bin/env bash
# install-wg-server.sh — Phase 1 of LEDGER-0018: install WireGuard server
# on the VPS alongside Tailscale (no Tailscale disruption).
#
# Generates:
#   /etc/wireguard/server-private.key      (chmod 600)
#   /etc/wireguard/server-public.key       (chmod 644 — share with clients)
#   /etc/wireguard/wg0.conf                (the server config; reload-on-edit)
#   systemd unit: wg-quick@wg0.service     (enabled + started)
#
# Server listens on UDP/51820 — operator must port-forward this on the WAN
# if the VPS provider's firewall blocks it (GoDaddy VPS panel: Firewall →
# inbound rule UDP 51820 from anywhere). The script reminds at the end.

set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "must run as root (sudo)"; exit 1; }

WG_PORT="${WG_PORT:-51820}"
WG_NET="${WG_NET:-10.100.0.0/24}"
WG_SERVER_IP="${WG_SERVER_IP:-10.100.0.1/24}"
WG_INTERFACE="${WG_INTERFACE:-wg0}"
PUBLIC_WAN_IFACE="${PUBLIC_WAN_IFACE:-eth0}"

BLUE='\033[1;34m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; RED='\033[1;31m'; NC='\033[0m'
step() { printf "${BLUE}→ %s${NC}\n" "$*"; }
ok()   { printf "${GREEN}✓ %s${NC}\n" "$*"; }
warn() { printf "${YELLOW}⚠ %s${NC}\n" "$*"; }
die()  { printf "${RED}✗ %s${NC}\n" "$*" >&2; exit 1; }

step "Phase 1: install WireGuard server on VPS (parallel to Tailscale)"

# 1. install wireguard
if ! command -v wg >/dev/null 2>&1; then
  apt-get update -qq && apt-get install -y wireguard wireguard-tools qrencode
  ok "installed wireguard + wireguard-tools + qrencode"
else
  ok "wireguard already installed"
fi

# 2. enable IP forwarding (required for subnet routing later)
if ! grep -q "^net.ipv4.ip_forward=1" /etc/sysctl.conf; then
  echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
fi
sysctl -p >/dev/null
ok "IP forwarding enabled"

# 3. generate server keys (only if not already present)
mkdir -p /etc/wireguard
cd /etc/wireguard
umask 077
if [[ ! -f server-private.key ]]; then
  wg genkey | tee server-private.key | wg pubkey > server-public.key
  chmod 600 server-private.key
  chmod 644 server-public.key
  ok "generated server keypair"
else
  ok "server keypair already exists"
fi

SERVER_PRIVATE=$(cat server-private.key)
SERVER_PUBLIC=$(cat server-public.key)

# 4. write wg0.conf
if [[ ! -f /etc/wireguard/${WG_INTERFACE}.conf ]]; then
  cat > /etc/wireguard/${WG_INTERFACE}.conf <<EOF
# WireGuard server — LEDGER-0018 VPS-anchored mesh
# Add new peers via:
#   sudo bash add-wg-client.sh --name <peer-name>

[Interface]
PrivateKey = $SERVER_PRIVATE
Address = $WG_SERVER_IP
ListenPort = $WG_PORT
SaveConfig = false

# NAT outgoing traffic from the WG mesh to the public internet (so clients can
# reach the wider web through the VPS if they want — optional but standard)
PostUp   = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o $PUBLIC_WAN_IFACE -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o $PUBLIC_WAN_IFACE -j MASQUERADE

# ─── peers go below (one [Peer] block per device) ─────────────────────────
# Use add-wg-client.sh to append new peers; do NOT hand-edit lightly.
EOF
  chmod 600 /etc/wireguard/${WG_INTERFACE}.conf
  ok "wrote /etc/wireguard/${WG_INTERFACE}.conf"
else
  warn "/etc/wireguard/${WG_INTERFACE}.conf already exists — leaving alone"
fi

# 5. enable + start systemd unit
systemctl enable --now wg-quick@${WG_INTERFACE}.service
sleep 2
if systemctl is-active --quiet wg-quick@${WG_INTERFACE}.service; then
  ok "wg-quick@${WG_INTERFACE}.service active"
else
  die "wg-quick@${WG_INTERFACE}.service failed — check: journalctl -u wg-quick@${WG_INTERFACE}.service -n 30"
fi

# 6. show state
echo
step "Current state:"
wg show

# 7. operator follow-ups
printf "\n${GREEN}══════════════════════════════════════════════════════════════════════${NC}\n"
printf "${GREEN}Phase 1 done. WireGuard server is up on UDP %s.${NC}\n" "$WG_PORT"
printf "${GREEN}══════════════════════════════════════════════════════════════════════${NC}\n"
printf "1. Open UDP %s on the GoDaddy VPS panel Firewall (inbound from anywhere)\n" "$WG_PORT"
printf "2. Server public key (share with clients):\n"
printf "   ${YELLOW}%s${NC}\n" "$SERVER_PUBLIC"
printf "3. Add your first client (test phone):\n"
printf "   ${YELLOW}sudo bash add-wg-client.sh --name test-phone --ip 10.100.0.30${NC}\n"
printf "4. Tailscale is still running. Do not stop until Phase 5 verification passes.\n\n"
