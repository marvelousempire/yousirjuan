#!/usr/bin/env bash
# vps/apply-vps-config.sh — Stand up the public-facing piece on a fresh VPS.
#
# Pre-conditions:
#   • Ubuntu 22.04 / 24.04 / Debian 12 (other distros: untested)
#   • You can SSH in as a sudo user
#   • A public DNS A record already points your subdomain at this VPS's IP
#     (e.g. hello.yourdomain.tld → 1.2.3.4)
#
# What this script does (run on the VPS itself):
#   1. apt-installs nginx, certbot, fail2ban, iptables-persistent
#   2. Drops fail2ban SSH jail config + enables it
#   3. Drops Ollama systemd override (binds to 0.0.0.0 + custom MODELS_DIR)
#   4. Runs iptables public-port lockdown (blocks 3000, 11434, etc. from public NIC)
#   5. Renders + installs nginx vhost from the template (substituting __DOMAIN__)
#   6. Requests a Let's Encrypt cert via certbot --nginx
#   7. Reloads nginx — public HTTPS endpoint is live
#
# Usage (run on the VPS, repo cloned):
#   sudo DOMAIN=hello.yourdomain.tld EMAIL=admin@yourdomain.tld \
#     bash vps/apply-vps-config.sh
#
# To run remotely from your laptop instead:
#   ssh user@vps "DOMAIN=hello.yourdomain.tld EMAIL=admin@yourdomain.tld \
#     sudo -E bash -" < vps/apply-vps-config.sh

set -euo pipefail

[[ -n "${DOMAIN:-}" ]] || { echo "Set DOMAIN=hello.yourdomain.tld"; exit 1; }
[[ -n "${EMAIL:-}"  ]] || { echo "Set EMAIL=admin@yourdomain.tld for cert renewal notices"; exit 1; }

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VPS_DIR="$REPO_DIR/vps"

step() { printf "\n\033[1;34m==>\033[0m \033[1m%s\033[0m\n" "$*"; }
ok()   { printf "    \033[0;32m✓\033[0m %s\n" "$*"; }
die()  { printf "\n\033[0;31m✗ %s\033[0m\n" "$*"; exit 1; }

[[ $EUID -eq 0 ]] || die "Run as root (sudo)."

step "1. Install base packages"
DEBIAN_FRONTEND=noninteractive apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -qq -y \
  nginx certbot python3-certbot-nginx fail2ban netfilter-persistent iptables-persistent \
  apache2-utils dnsutils

step "2. fail2ban SSH jail"
cp "$VPS_DIR/fail2ban-sshd.local" /etc/fail2ban/jail.d/sshd.local
systemctl enable --now fail2ban
ok "fail2ban running, SSH jail active"

step "3. Ollama systemd override (bind 0.0.0.0)"
if systemctl list-unit-files | grep -q '^ollama\.service'; then
  mkdir -p /etc/systemd/system/ollama.service.d
  USER_FOR_MODELS="${SUDO_USER:-root}"
  sed "s|__USER__|$USER_FOR_MODELS|g" "$VPS_DIR/ollama-systemd-override.conf" \
    > /etc/systemd/system/ollama.service.d/override.conf
  systemctl daemon-reload
  systemctl restart ollama
  ok "Ollama bound to 0.0.0.0:11434"
else
  echo "    (Ollama not installed yet — skipping; install via installers/linux.sh first)"
fi

step "4. iptables public-port lockdown"
bash "$VPS_DIR/iptables-public-lockdown.sh"

step "5. nginx vhost for $DOMAIN"
sed "s|__DOMAIN__|$DOMAIN|g" "$VPS_DIR/nginx-vhost.conf.template" \
  > "/etc/nginx/sites-available/$DOMAIN"
ln -sf "/etc/nginx/sites-available/$DOMAIN" "/etc/nginx/sites-enabled/$DOMAIN"
# A minimal HTTP-only vhost initially so certbot can do the ACME challenge.
# Replace it with the full template after the cert exists.
TMP_VHOST="$(mktemp)"
cat > "$TMP_VHOST" <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN;
    location /.well-known/acme-challenge/ { root /var/www/html; }
    location / { return 200 'staged for $DOMAIN — waiting for cert\n'; add_header Content-Type text/plain; }
}
EOF
mv "$TMP_VHOST" "/etc/nginx/sites-available/$DOMAIN"
nginx -t && systemctl reload nginx

step "6. Let's Encrypt cert via certbot --nginx"
certbot --nginx -d "$DOMAIN" \
  --non-interactive --agree-tos -m "$EMAIL" --redirect

step "7. Install full HTTPS reverse-proxy vhost"
sed "s|__DOMAIN__|$DOMAIN|g" "$VPS_DIR/nginx-vhost.conf.template" \
  > "/etc/nginx/sites-available/$DOMAIN"
nginx -t && systemctl reload nginx

cat <<EOF

────────────────────────────────────────────────────────────────────
  VPS public endpoint live: https://$DOMAIN
────────────────────────────────────────────────────────────────────
  Cert auto-renews (certbot timer enabled by default)
  Open WebUI must be running on localhost:3000
  Sign up at https://$DOMAIN — first user becomes admin
  Then disable signups: Admin Panel → Settings → General

EOF
