#!/usr/bin/env bash
# vps-bootstrap.sh — turn a fresh Ubuntu VPS into the configured clinic-vps.
# Strictly AI-free. Idempotent: re-running is a no-op if already configured.
#
# Usage:
#   sudo bash vps-bootstrap.sh

set -euo pipefail

step()  { printf '\e[1;34m→\e[0m %s\n' "$*"; }
ok()    { printf '\e[1;32m✓\e[0m %s\n' "$*"; }
warn()  { printf '\e[1;33m!\e[0m %s\n' "$*"; }
die()   { printf '\e[1;31m✗\e[0m %s\n' "$*" >&2; exit 1; }
have()  { command -v "$1" >/dev/null 2>&1; }

[[ $EUID -eq 0 ]] || die "Run as root: sudo bash $0"

OS=$(. /etc/os-release && echo "$ID")
[[ "$OS" == "ubuntu" ]] || warn "Tested on Ubuntu; running on $OS — proceed with caution"

step "Install base packages..."
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
  wireguard-tools nginx iptables-persistent certbot python3-certbot-nginx \
  curl ca-certificates gnupg lsb-release git build-essential

step "Install Node.js 20.x..."
if ! have node || [[ "$(node -v 2>/dev/null)" != v20* ]]; then
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
  apt-get install -y -qq nodejs
fi
ok "node $(node -v)"

step "Install pnpm..."
if ! have pnpm; then
  npm install -g pnpm@9
fi
ok "pnpm $(pnpm -v)"

step "Clone marvelousempire/nephew to /opt/nephew..."
if [[ ! -d /opt/nephew/.git ]]; then
  git clone https://github.com/marvelousempire/nephew.git /opt/nephew
fi
chown -R "${SUDO_USER:-$USER}:${SUDO_USER:-$USER}" /opt/nephew
ok "/opt/nephew ready"

step "Install operator-side ~/.nephew (env, runs, witness)..."
if [[ -n "${SUDO_USER:-}" ]]; then
  HOME_DIR=$(getent passwd "$SUDO_USER" | cut -d: -f6)
  sudo -u "$SUDO_USER" mkdir -p "$HOME_DIR/.nephew/runs"
  if [[ ! -f "$HOME_DIR/.nephew/tower.env" ]]; then
    cat > "$HOME_DIR/.nephew/tower.env" <<EOF
# Populated by the operator — see LEDGER-0027 runbook 02.
# NEPHEW_OPERATOR_NAME=...
# NEPHEW_OPERATOR_EMAIL=...
# NEPHEW_HERMES_KEY=...
EOF
    chown "$SUDO_USER:$SUDO_USER" "$HOME_DIR/.nephew/tower.env"
    chmod 600 "$HOME_DIR/.nephew/tower.env"
  fi
fi

step "Install tower-api systemd user unit..."
USER_HOME=$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)
USER_SYSTEMD="$USER_HOME/.config/systemd/user"
sudo -u "${SUDO_USER:-$USER}" mkdir -p "$USER_SYSTEMD"
cat > "$USER_SYSTEMD/nephew-tower-api.service" <<EOF
[Unit]
Description=Nephew Tower API
After=network-online.target

[Service]
Type=simple
WorkingDirectory=/opt/nephew
ExecStart=/usr/bin/node /opt/nephew/bin/nephew-tower-api
Environment=NEPHEW_ROOT=/opt/nephew
Environment=NEPHEW_TOWER_HOST=127.0.0.1
Environment=NEPHEW_TOWER_PORT=8088
Restart=on-failure
RestartSec=3

[Install]
WantedBy=default.target
EOF
chown -R "${SUDO_USER:-$USER}:${SUDO_USER:-$USER}" "$USER_SYSTEMD"
sudo -u "${SUDO_USER:-$USER}" XDG_RUNTIME_DIR="/run/user/$(id -u "${SUDO_USER:-$USER}")" \
  systemctl --user daemon-reload || true
ok "tower-api unit installed"

step "Install nginx site config..."
LEDGER_DIR=$(dirname "$0")/..
NGINX_TEMPLATE="$LEDGER_DIR/artifacts/vps-nginx-agents.conf"
if [[ -f "$NGINX_TEMPLATE" ]]; then
  # nginx site is templated/managed elsewhere; this just ensures /api/agents/ block is present
  warn "Reminder: ensure /etc/nginx/sites-enabled/nephew.yousirjuan.ai includes the /api/agents/ block from artifacts/vps-nginx-agents.conf BEFORE the /api/ catch-all (see runbook 07)."
fi

step "Enable user lingering so tower-api starts on boot without operator login..."
loginctl enable-linger "${SUDO_USER:-$USER}" || true

ok "VPS bootstrap done. Next steps:"
echo
echo "  1. Populate ~/.nephew/tower.env with operator name + email + hermes key"
echo "  2. Add WG peer + write /etc/wireguard/wg0.conf (runbook 05)"
echo "  3. Add NEPHEW_HERMES_DIRECT_URL drop-in (runbook 08)"
echo "  4. cd /opt/nephew && make deploy   (from operator's Mac)"
echo "  5. certbot --nginx -d nephew.yousirjuan.ai"
echo
