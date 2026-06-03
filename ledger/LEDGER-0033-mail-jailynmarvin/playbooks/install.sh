#!/usr/bin/env bash
# LEDGER-0033 — Self-hosted mail for jailynmarvin.com on clinic-vps (docker-mailserver)
set -euo pipefail

MAIL_ROOT="${MAIL_ROOT:-/opt/mail-jailynmarvin}"
PRIMARY_USER="${PRIMARY_USER:-abrownsanta@jailynmarvin.com}"
COMPOSE_URL="https://raw.githubusercontent.com/docker-mailserver/docker-mailserver/master/compose.yaml"
ENV_URL="https://raw.githubusercontent.com/docker-mailserver/docker-mailserver/master/mailserver.env"
SETUP_URL="https://raw.githubusercontent.com/docker-mailserver/docker-mailserver/master/setup.sh"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run with sudo or as root on clinic-vps." >&2
  exit 1
fi

install -d -m 0755 -o abrownsanta -g abrownsanta "$MAIL_ROOT"
cd "$MAIL_ROOT"

if [[ ! -f docker-compose.yml ]]; then
  sudo -u abrownsanta curl -fsSL "$COMPOSE_URL" -o docker-compose.yml
  sudo -u abrownsanta curl -fsSL "$ENV_URL" -o mailserver.env
  sudo -u abrownsanta curl -fsSL "$SETUP_URL" -o setup.sh
  chmod +x setup.sh
fi
sudo -u abrownsanta sed -i 's/hostname: mail\.example\.com/hostname: mail.jailynmarvin.com/' docker-compose.yml

# Lean config — ClamAV off to save RAM on 8GB VPS (append block once)
if ! grep -q 'LEDGER-0033' mailserver.env 2>/dev/null; then
  cat >>mailserver.env <<'EOF'

# --- jailynmarvin.com (LEDGER-0033) ---
OVERRIDE_HOSTNAME=mail.jailynmarvin.com
POSTMASTER_ADDRESS=postmaster@jailynmarvin.com
ENABLE_CLAMAV=0
ENABLE_SPAMASSASSIN=0
ENABLE_RSPAMD=1
ENABLE_FAIL2BAN=1
SSL_TYPE=self-signed
LOG_LEVEL=info
EOF
fi

# Outbound relay — GoDaddy often blocks port 25. Uncomment after adding a provider:
# DEFAULT_RELAY_HOST=[smtp.relay.example.com]:587
# RELAY_USER=
# RELAY_PASSWORD=

ufw allow 25/tcp comment 'SMTP inbound' || true
ufw allow 587/tcp comment 'SMTP submission' || true
ufw allow 465/tcp comment 'SMTPS' || true
ufw allow 993/tcp comment 'IMAPS' || true

sudo -u abrownsanta docker compose pull
sudo -u abrownsanta docker compose up -d

if [[ ! -f .primary-mail-password ]]; then
  openssl rand -base64 24 | tr -d '/+=' | head -c 24 >.primary-mail-password
  chmod 600 .primary-mail-password
  chown abrownsanta:abrownsanta .primary-mail-password
fi
PASS="$(cat .primary-mail-password)"

sudo -u abrownsanta ./setup.sh email add "$PRIMARY_USER" "$PASS" 2>/dev/null || \
  sudo -u abrownsanta docker exec mailserver setup email add "$PRIMARY_USER" "$PASS"

sudo -u abrownsanta ./setup.sh config dkim keysize 2048 domain jailynmarvin.com 2>/dev/null || \
  sudo -u abrownsanta docker exec mailserver setup config dkim keysize 2048 domain jailynmarvin.com

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -x "$SCRIPT_DIR/emit-dns-cutover.sh" ]]; then
  bash "$SCRIPT_DIR/emit-dns-cutover.sh" "$MAIL_ROOT"
fi

echo "Mail stack up at $MAIL_ROOT"
echo "Primary mailbox: $PRIMARY_USER"
echo "Password file: $MAIL_ROOT/.primary-mail-password (chmod 600)"
