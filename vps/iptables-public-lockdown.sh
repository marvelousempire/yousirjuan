#!/usr/bin/env bash
# vps/iptables-public-lockdown.sh — Block sensitive ports from the public NIC.
#
# Background: when you bind a service to 0.0.0.0 OR publish a Docker port with
# `-p 3000:8080`, that service is exposed to the public internet by default.
# This script adds layered iptables rules to drop unwanted public traffic
# while still allowing tailnet devices (and any explicitly-allowed peer) in.
#
# Two chains are involved:
#   • INPUT chain        — for traffic going to host services (Ollama, Nydus, etc.)
#   • DOCKER-USER chain  — for traffic going to Docker containers (Open WebUI, etc.)
#                          (uses --ctorigdstport because Docker DNATs the port
#                          before the FORWARD chain sees it)
#
# Public NIC is auto-detected from the default route.
# Tailscale traffic comes in on tailscale0 — left alone.
#
# Run:   sudo bash vps/iptables-public-lockdown.sh
# Persist: handled by the iptables-persistent package which the script installs.

set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "Run as root (sudo)."; exit 1; }

# Detect the public-facing NIC (the one with the default route)
PUB_IF="$(ip route get 8.8.8.8 2>/dev/null | awk '/dev/ {for(i=1;i<=NF;i++) if($i=="dev") print $(i+1); exit}')"
[[ -n "$PUB_IF" ]] || { echo "Couldn't detect public NIC."; exit 1; }
echo "==> Public interface detected: $PUB_IF"

# Ensure iptables-persistent is installed (so rules survive reboot)
DEBIAN_FRONTEND=noninteractive apt-get install -qq -y netfilter-persistent iptables-persistent >/dev/null

# Ports to block from public (host-level services)
HOST_PORTS=(
  "11434"      # Ollama
  "2224"       # Nydus
  "8890"       # SundayApp
)

# Port ranges to block from public on Docker-published containers
DOCKER_PORTS=(
  "3000"          # Open WebUI
  "8081:8113"     # WordPress staging sites
)

echo "==> Adding INPUT-chain DROPs for host services (in via $PUB_IF only)"
for p in "${HOST_PORTS[@]}"; do
  # Idempotent: delete existing identical rule first, then re-add at top
  iptables -D INPUT -i "$PUB_IF" -p tcp --dport "$p" -j DROP 2>/dev/null || true
  iptables -I INPUT -i "$PUB_IF" -p tcp --dport "$p" -j DROP
  echo "    blocked :$p"
done

echo "==> Adding DOCKER-USER DROPs for published container ports (--ctorigdstport)"
# Make sure the chain ends with RETURN (Docker default)
iptables -F DOCKER-USER 2>/dev/null || true
iptables -A DOCKER-USER -j RETURN
for p in "${DOCKER_PORTS[@]}"; do
  iptables -I DOCKER-USER -i "$PUB_IF" -p tcp -m conntrack --ctorigdstport "$p" -j DROP
  echo "    blocked :$p"
done

# IPv6 mirror — block the same ports (all rules with v4 also need v6)
echo "==> Mirroring rules for IPv6"
for p in "${HOST_PORTS[@]}"; do
  ip6tables -D INPUT -i "$PUB_IF" -p tcp --dport "$p" -j DROP 2>/dev/null || true
  ip6tables -I INPUT -i "$PUB_IF" -p tcp --dport "$p" -j DROP
done

# Persist
echo "==> Saving rules (survive reboot via iptables-persistent)"
netfilter-persistent save >/dev/null

echo
echo "Done. Verify:"
echo "  iptables -S INPUT | head"
echo "  iptables -S DOCKER-USER"
