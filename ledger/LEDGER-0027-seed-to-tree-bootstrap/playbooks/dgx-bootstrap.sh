#!/usr/bin/env bash
# dgx-bootstrap.sh — turn a fresh Ubuntu 24.04 arm64 DGX into the configured nephew-nivram.
# Strictly AI-free. Idempotent.
#
# Usage:
#   sudo bash dgx-bootstrap.sh

set -euo pipefail

step()  { printf '\e[1;34m→\e[0m %s\n' "$*"; }
ok()    { printf '\e[1;32m✓\e[0m %s\n' "$*"; }
warn()  { printf '\e[1;33m!\e[0m %s\n' "$*"; }
die()   { printf '\e[1;31m✗\e[0m %s\n' "$*" >&2; exit 1; }
have()  { command -v "$1" >/dev/null 2>&1; }

[[ $EUID -eq 0 ]] || die "Run as root: sudo bash $0"

OS=$(. /etc/os-release && echo "$ID")
[[ "$OS" == "ubuntu" ]] || die "Tested on Ubuntu only; got $OS"

REAL_USER="${SUDO_USER:-abrownsanta}"
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
[[ -n "$REAL_HOME" ]] || die "Could not resolve home dir for user $REAL_USER"

step "Install base packages..."
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
  ca-certificates curl gnupg lsb-release \
  iptables-persistent \
  net-tools dnsutils tcpdump \
  build-essential

step "Install Docker (rootful)..."
if ! have docker; then
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" \
    > /etc/apt/sources.list.d/docker.list
  apt-get update -qq
  apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  usermod -aG docker "$REAL_USER"
fi
systemctl enable --now docker
ok "docker $(docker --version)"

step "Install sysctl arp_filter rules..."
cat > /etc/sysctl.d/99-nephew-arp-filter.conf <<EOF
# Plan 0090 / LEDGER-0026 — fix dual-interface asymmetric routing.
# DGX has both enP7s7 (wired) and wlP9s9 (wifi) on 192.168.8.0/24.
# Without arp_filter, replies can exit a different interface than the request
# arrived on, breaking peers reaching the DGX over the WG mesh.
net.ipv4.conf.all.arp_filter=1
net.ipv4.conf.default.arp_filter=1
net.ipv4.conf.all.rp_filter=2
EOF
sysctl --system >/dev/null 2>&1 || sysctl -p /etc/sysctl.d/99-nephew-arp-filter.conf
ok "/etc/sysctl.d/99-nephew-arp-filter.conf written"

step "Install iptables INPUT rules for tcp/8642 (LAN + WG + loopback only)..."
# Flush existing 8642 rules first (idempotent re-run)
while iptables -L INPUT -n --line-numbers 2>/dev/null | grep -q "tcp dpt:8642"; do
  RULE_NUM=$(iptables -L INPUT -n --line-numbers | grep "tcp dpt:8642" | head -1 | awk '{print $1}')
  iptables -D INPUT "$RULE_NUM"
done
iptables -I INPUT 1 -p tcp --dport 8642 -s 127.0.0.0/8 -j ACCEPT
iptables -I INPUT 2 -p tcp --dport 8642 -s 192.168.8.0/24 -j ACCEPT
iptables -I INPUT 3 -p tcp --dport 8642 -s 10.0.0.0/24 -j ACCEPT
iptables -I INPUT 4 -p tcp --dport 8642 -j DROP
netfilter-persistent save >/dev/null
ok "8642 firewall rules installed and persisted"

step "Install hermes container..."
HERMES_DIR="$REAL_HOME/.hermes"
sudo -u "$REAL_USER" mkdir -p "$HERMES_DIR"
if [[ ! -f "$HERMES_DIR/docker-compose.yml" ]]; then
  # Copy from this ledger's artifact if available, else error
  TEMPLATE="$(dirname "$0")/../artifacts/dgx-docker-compose.yml"
  if [[ -f "$TEMPLATE" ]]; then
    cp "$TEMPLATE" "$HERMES_DIR/docker-compose.yml"
    chown "$REAL_USER:$REAL_USER" "$HERMES_DIR/docker-compose.yml"
  else
    warn "No docker-compose.yml template found at $TEMPLATE. Create it from runbook 04 before starting hermes."
  fi
fi

if [[ -f "$HERMES_DIR/docker-compose.yml" ]]; then
  cd "$HERMES_DIR"
  sudo -u "$REAL_USER" docker compose up -d 2>&1 | tail -5 || warn "hermes start failed — check logs"
fi

ok "DGX bootstrap done. Verify with:"
echo "    docker ps --format '{{.Names}}: {{.Status}}'"
echo "    sudo ss -tnlp | grep 8642"
echo '    curl -s -H "Authorization: Bearer $KEY" http://127.0.0.1:8642/v1/models'
