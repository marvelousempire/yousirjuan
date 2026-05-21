#!/usr/bin/env bash
# install.sh — deploy Uptime Kuma on the VPS.
#
# Runs on the VPS as root. Idempotent. Reversible via uninstall.
#
# Steps:
#   1. Create persistent data dir at /var/lib/yousirjuan/uptime-kuma (chowned 1000:1000 = uptime-kuma container default)
#   2. Copy docker-compose.yml into /opt/uptime-kuma/ on the host
#   3. docker compose up -d
#   4. Install nginx vhost (uptime.yousirjuan.ai → 127.0.0.1:3011)
#   5. nginx -t + reload
#   6. Verify container healthy
#
# Operator follow-ups (not in this script):
#   - Add A record uptime.yousirjuan.ai → 72.167.151.251 in GoDaddy DNS
#   - certbot --nginx -d uptime.yousirjuan.ai (one-time, after DNS propagates)
#   - Initial Uptime Kuma admin setup via the web UI (set password, add monitors)

set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "must run as root (sudo)"; exit 1; }

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
COMPOSE_SRC="${REPO_ROOT}/ledger/LEDGER-0016-uptime-kuma-monitoring/artifacts/docker-compose.yml"
VHOST_SRC="${REPO_ROOT}/ledger/LEDGER-0016-uptime-kuma-monitoring/artifacts/uptime.yousirjuan.ai"
INSTALL_DIR="/opt/uptime-kuma"
DATA_DIR="/var/lib/yousirjuan/uptime-kuma"
VHOST_DEST="/etc/nginx/sites-enabled/uptime.yousirjuan.ai"

BLUE='\033[1;34m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; RED='\033[1;31m'; NC='\033[0m'
step() { printf "${BLUE}→ %s${NC}\n" "$*"; }
ok()   { printf "${GREEN}✓ %s${NC}\n" "$*"; }
warn() { printf "${YELLOW}⚠ %s${NC}\n" "$*"; }
die()  { printf "${RED}✗ %s${NC}\n" "$*" >&2; exit 1; }

action="${1:-install}"

case "$action" in
  install)
    step "Installing Uptime Kuma"
    command -v docker >/dev/null || die "docker missing"
    docker compose version >/dev/null 2>&1 || die "docker compose plugin missing"

    mkdir -p "$INSTALL_DIR" "$DATA_DIR"
    chown -R 1000:1000 "$DATA_DIR"
    install -m 0644 "$COMPOSE_SRC" "$INSTALL_DIR/docker-compose.yml"
    ok "wrote $INSTALL_DIR/docker-compose.yml"

    step "  docker compose up -d"
    (cd "$INSTALL_DIR" && docker compose up -d 2>&1 | tail -5)

    step "  waiting up to 30s for Uptime Kuma to become healthy"
    for i in $(seq 1 30); do
      if curl -sf -m 2 http://127.0.0.1:3011/ >/dev/null 2>&1; then
        ok "Uptime Kuma responding on http://127.0.0.1:3011/"
        break
      fi
      sleep 1
    done

    step "  installing nginx vhost"
    if [[ -f "$VHOST_DEST" ]]; then
      mkdir -p /etc/nginx/sites-backups
      mv "$VHOST_DEST" "/etc/nginx/sites-backups/uptime.yousirjuan.ai.bak-$(date +%Y%m%d-%H%M%S)"
      ok "  backed up existing vhost"
    fi
    install -m 0644 "$VHOST_SRC" "$VHOST_DEST"

    step "  nginx -t + reload"
    if nginx -t 2>&1 | tail -2 | grep -q "successful"; then
      nginx -s reload
      ok "nginx reloaded"
    else
      die "nginx -t failed"
    fi

    printf "\n${GREEN}══════════════════════════════════════════════════════════════════════${NC}\n"
    printf "${GREEN}Uptime Kuma installed.${NC}\n"
    printf "${GREEN}══════════════════════════════════════════════════════════════════════${NC}\n"
    printf "1. Add A record: ${YELLOW}uptime.yousirjuan.ai → 72.167.151.251${NC} in GoDaddy DNS\n"
    printf "2. Wait for DNS to propagate (~2 min)\n"
    printf "3. Get TLS cert: ${YELLOW}sudo certbot --nginx -d uptime.yousirjuan.ai${NC}\n"
    printf "4. Visit ${YELLOW}https://uptime.yousirjuan.ai/${NC} and complete the admin setup wizard\n"
    printf "5. Add monitors (see runbook 02 for the recommended seed list)\n\n"
    ;;
  uninstall)
    step "Uninstalling Uptime Kuma"
    (cd "$INSTALL_DIR" && docker compose down 2>&1 | tail -3) || true
    rm -f "$VHOST_DEST"
    nginx -t >/dev/null 2>&1 && nginx -s reload
    warn "preserved data at $DATA_DIR (delete manually if rotating)"
    ok "uninstalled"
    ;;
  status)
    docker ps --filter "name=uptime-kuma" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo
    curl -sf -m 3 http://127.0.0.1:3011/ -o /dev/null -w "Local: HTTP %{http_code}\n"
    curl -sf -m 3 https://uptime.yousirjuan.ai/ -o /dev/null -w "Public: HTTP %{http_code}\n" || true
    ;;
  *) die "usage: sudo bash $0 {install|uninstall|status}";;
esac
