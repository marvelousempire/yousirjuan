#!/usr/bin/env bash
# verify-end-to-end.sh — run the 8-gate smoke test of the family AI stack.
# Read-only; safe to run anytime.
#
# Usage:
#   bash verify-end-to-end.sh

set -uo pipefail

KEY="${NEPHEW_HERMES_KEY:-v7pQ40f8zgfW-O7xy9y_vMgmy5LAzoZdr-pEOC1UjZI}"
DOMAIN="${NEPHEW_DOMAIN:-nephew.yousirjuan.ai}"
VPS_HOST="${NEPHEW_VPS:-clinic-vps}"
DGX_HOST="${NEPHEW_DGX:-nephew-nivram}"
DGX_IP="${NEPHEW_DGX_IP:-192.168.8.249}"

passed=0
failed=0
pass() { printf '\e[1;32m✓\e[0m %s\n' "$*"; passed=$((passed+1)); }
fail() { printf '\e[1;31m✗\e[0m %s\n' "$*"; failed=$((failed+1)); }

echo "=== Nephew Family AI Stack — End-to-End Verification ==="
echo

# 1. VPS WG handshake recent
echo -n "[1/8] VPS WG handshake               ... "
HANDSHAKE_AGO=$(ssh -o ConnectTimeout=5 "$VPS_HOST" 'sudo wg show wg0 latest-handshakes 2>/dev/null | head -1 | awk "{print \$2}"' 2>/dev/null || echo 0)
NOW=$(date +%s)
AGE=$((NOW - HANDSHAKE_AGO))
if [[ "$HANDSHAKE_AGO" -gt 0 && "$AGE" -lt 120 ]]; then
  pass "ok (latest ${AGE}s)"
else
  fail "stale or missing (last: ${AGE}s ago)"
fi

# 2. VPS → DGX ping over WG
echo -n "[2/8] VPS → DGX ping over WG         ... "
if ssh -o ConnectTimeout=5 "$VPS_HOST" "ping -c 2 -W 2 $DGX_IP >/dev/null 2>&1"; then
  AVG=$(ssh "$VPS_HOST" "ping -c 3 -W 2 $DGX_IP 2>&1 | tail -1 | cut -d= -f2 | cut -d/ -f2")
  pass "ok (${AVG}ms avg)"
else
  fail "no response from $DGX_IP"
fi

# 3. VPS → DGX hermes /v1/models
echo -n "[3/8] VPS → DGX hermes /v1/models     ... "
RESP=$(ssh "$VPS_HOST" "curl -s -m 8 -H 'Authorization: Bearer $KEY' http://$DGX_IP:8642/v1/models" 2>/dev/null || true)
if echo "$RESP" | grep -q '"id"'; then
  MODEL=$(echo "$RESP" | grep -oE '"id":"[^"]+"' | head -1 | cut -d'"' -f4)
  pass "ok ($MODEL listed)"
else
  fail "no model list returned"
fi

# 4. VPS tower-api local /status
echo -n "[4/8] VPS tower-api local /status    ... "
STATUS=$(ssh "$VPS_HOST" "curl -s -m 6 http://127.0.0.1:8088/api/agents/nephew-chat/status" 2>/dev/null || true)
if echo "$STATUS" | grep -q '"ok":true' && echo "$STATUS" | grep -q '"tunnel":"direct-url"'; then
  pass "ok (tunnel: direct-url)"
else
  fail "not ok: $(echo "$STATUS" | head -c 200)"
fi

# 5. Domain HTTPS + valid cert
echo -n "[5/8] $DOMAIN HTTPS     ... "
CERT_EXP=$(echo | openssl s_client -servername "$DOMAIN" -connect "$DOMAIN":443 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
if curl -fsI "https://$DOMAIN/" >/dev/null 2>&1; then
  pass "ok (valid until $CERT_EXP)"
else
  fail "request failed"
fi

# 6. Production /api/agents/nephew-chat/status
echo -n "[6/8] production /api/agents/.../status ... "
PROD=$(curl -s -m 8 "https://$DOMAIN/api/agents/nephew-chat/status" 2>/dev/null || true)
if echo "$PROD" | grep -q '"ok":true' && echo "$PROD" | grep -q '"api":"connected"'; then
  pass "ok"
else
  fail "$(echo "$PROD" | head -c 200)"
fi

# 7. /chat HTML renders
echo -n "[7/8] /chat renders                   ... "
CHAT=$(curl -fs "https://$DOMAIN/chat" 2>/dev/null || true)
if echo "$CHAT" | grep -qE '<div id="root"|<title>'; then
  pass "ok"
else
  fail "no HTML returned"
fi

# 8. DGX hermes container up
echo -n "[8/8] DGX hermes container up         ... "
HERMES=$(ssh -o ConnectTimeout=5 "$DGX_HOST" 'docker ps --filter name=hermes --format "{{.Status}}"' 2>/dev/null || echo "")
if echo "$HERMES" | grep -q '^Up '; then
  pass "ok ($HERMES)"
else
  fail "not up: ${HERMES:-(SSH failed)}"
fi

echo
if [[ $failed -eq 0 ]]; then
  printf '\e[1;32m✅ All %d gates passed — Family AI stack is live.\e[0m\n' $passed
  exit 0
else
  printf '\e[1;31m❌ %d/%d gates failed — see runbook 09 troubleshooting table.\e[0m\n' $failed $((passed+failed))
  exit 1
fi
