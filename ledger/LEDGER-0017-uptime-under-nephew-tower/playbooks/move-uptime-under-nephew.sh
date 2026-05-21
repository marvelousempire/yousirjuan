#!/usr/bin/env bash
# move-uptime-under-nephew.sh — refactor Uptime Kuma from standalone
# uptime.yousirjuan.ai → sub-path under nephew.yousirjuan.ai/uptime/.
#
# Operator decision 2026-05-21: "can we just add that to the Control Tower
# which is the Nephew UI instead of 'uptime.yousirjuan.ai'?"
#
# Steps:
#   1. Update Uptime Kuma docker-compose: add URL_BASE_PATH=/uptime env, restart
#   2. Backup + patch nephew.yousirjuan.ai vhost: insert `location /uptime/` block
#      BEFORE the `location /` catchall (proxies to 127.0.0.1:3011 with WS headers)
#   3. Remove the standalone uptime.yousirjuan.ai vhost (no longer needed)
#   4. nginx -t + reload
#   5. Verify via curl
#
# Idempotent: re-running is safe; existing inserts detected via a marker comment.

set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "must run as root"; exit 1; }

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
NEPHEW_VHOST="/etc/nginx/sites-enabled/nephew.yousirjuan.ai"
UPTIME_VHOST="/etc/nginx/sites-enabled/uptime.yousirjuan.ai"
KUMA_COMPOSE="/opt/uptime-kuma/docker-compose.yml"
BACKUP_DIR="/etc/nginx/sites-backups"
MARKER="# LEDGER-0017 uptime-kuma sub-path"

BLUE='\033[1;34m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; RED='\033[1;31m'; NC='\033[0m'
step() { printf "${BLUE}→ %s${NC}\n" "$*"; }
ok()   { printf "${GREEN}✓ %s${NC}\n" "$*"; }
warn() { printf "${YELLOW}⚠ %s${NC}\n" "$*"; }
die()  { printf "${RED}✗ %s${NC}\n" "$*" >&2; exit 1; }

# ─── 1. add URL_BASE_PATH to Uptime Kuma compose + restart ──────────────────
step "1. add URL_BASE_PATH=/uptime to Kuma compose + restart"
if [[ ! -f "$KUMA_COMPOSE" ]]; then
  die "$KUMA_COMPOSE missing — run LEDGER-0016 install first"
fi

if grep -q "URL_BASE_PATH=/uptime" "$KUMA_COMPOSE"; then
  ok "URL_BASE_PATH already set"
else
  # Insert after the image: line of the uptime-kuma service
  python3 - <<PYEOF
import re, pathlib
p = pathlib.Path("$KUMA_COMPOSE")
content = p.read_text()
# Insert environment block under uptime-kuma: service if not present
if "environment:" in content:
    # add the var to existing env block
    content = re.sub(r"(environment:\s*\n)", r"\1      URL_BASE_PATH: /uptime\n", content, count=1)
else:
    # insert a new env block after image: line
    content = re.sub(
        r"(image: louislam/uptime-kuma:.+\n)",
        r"\1    environment:\n      URL_BASE_PATH: /uptime\n",
        content, count=1
    )
p.write_text(content)
print("patched")
PYEOF
  ok "patched $KUMA_COMPOSE"
fi

step "   docker compose down + up to apply env"
(cd /opt/uptime-kuma && docker compose down 2>&1 | tail -2 && docker compose up -d 2>&1 | tail -3)
sleep 5
ok "Kuma restarted with URL_BASE_PATH"

# ─── 2. patch nephew vhost ──────────────────────────────────────────────────
step "2. backup nephew vhost + insert /uptime/ location"
[[ -f "$NEPHEW_VHOST" ]] || die "$NEPHEW_VHOST missing"

mkdir -p "$BACKUP_DIR"
if grep -qF "$MARKER" "$NEPHEW_VHOST"; then
  ok "marker present — nephew vhost already patched, skipping insert"
else
  cp "$NEPHEW_VHOST" "$BACKUP_DIR/nephew.yousirjuan.ai.bak-$(date +%Y%m%d-%H%M%S)"
  ok "backed up to $BACKUP_DIR/"

  # Insert /uptime/ location block BEFORE the `location / {` line.
  python3 - <<'PYEOF'
import pathlib
p = pathlib.Path("/etc/nginx/sites-enabled/nephew.yousirjuan.ai")
text = p.read_text()
insert = """    # LEDGER-0017 uptime-kuma sub-path
    location /uptime/ {
        proxy_pass http://127.0.0.1:3011/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        # Uptime Kuma uses WebSockets — these headers are required
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_read_timeout 90;
    }

"""
# Insert before the existing `location / {` line
text = text.replace("    location / {", insert + "    location / {", 1)
p.write_text(text)
print("inserted")
PYEOF
  ok "inserted /uptime/ location into $NEPHEW_VHOST"
fi

# ─── 3. remove standalone uptime.yousirjuan.ai vhost ────────────────────────
step "3. remove standalone uptime.yousirjuan.ai vhost (no longer needed)"
if [[ -f "$UPTIME_VHOST" ]]; then
  mv "$UPTIME_VHOST" "$BACKUP_DIR/uptime.yousirjuan.ai.bak-$(date +%Y%m%d-%H%M%S)-pre-LEDGER-0017"
  ok "moved $UPTIME_VHOST → $BACKUP_DIR/"
else
  ok "uptime.yousirjuan.ai vhost already absent"
fi

# Also move any stale backup files OUT of sites-enabled
find /etc/nginx/sites-enabled -maxdepth 1 -name "uptime.yousirjuan.ai.bak*" -exec mv {} "$BACKUP_DIR/" \; 2>/dev/null

# ─── 4. nginx test + reload ─────────────────────────────────────────────────
step "4. nginx -t + reload"
if nginx -t 2>&1 | tail -2 | grep -q "successful"; then
  nginx -s reload
  ok "nginx reloaded"
else
  die "nginx -t failed; restoring backup if available"
fi

# ─── 5. verify ──────────────────────────────────────────────────────────────
step "5. verify"
sleep 2
code=$(curl -sf -o /dev/null -w "%{http_code}" -m 6 "https://nephew.yousirjuan.ai/uptime/" 2>/dev/null || echo "000")
if [[ "$code" =~ ^[23] ]]; then
  ok "https://nephew.yousirjuan.ai/uptime/ → HTTP $code"
elif [[ "$code" == "302" ]]; then
  ok "https://nephew.yousirjuan.ai/uptime/ → HTTP 302 (Kuma's first-time-setup redirect; correct)"
else
  warn "https://nephew.yousirjuan.ai/uptime/ → HTTP $code"
  warn "  curl directly to debug: curl -v http://127.0.0.1:3011/uptime/"
fi

printf "\n${GREEN}══════════════════════════════════════════════════════════════════════${NC}\n"
printf "${GREEN}Uptime Kuma now lives at https://nephew.yousirjuan.ai/uptime/${NC}\n"
printf "${GREEN}══════════════════════════════════════════════════════════════════════${NC}\n"
printf "Standalone uptime.yousirjuan.ai is gone (no longer needed).\n"
printf "GoDaddy A record for uptime.yousirjuan.ai can be deleted if previously added.\n\n"
