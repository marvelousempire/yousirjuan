#!/usr/bin/env bash
# LEDGER-0035 — family SSO stack smoke (read-only probes)
set -euo pipefail

fail=0

check_port() {
  local port="$1" name="$2"
  if lsof -nP -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1; then
    echo "✓ $name listening on :$port"
  else
    echo "✗ $name NOT listening on :$port"
    fail=1
  fi
}

check_port 8088 "tower-api"
check_port 8781 "tape-server"
check_port 8782 "family gateway"

if curl -sf 'http://127.0.0.1:8088/healthz' >/dev/null 2>&1; then
  echo "✓ tower-api healthz"
else
  echo "✗ tower-api healthz failed"
  fail=1
fi

dt="$(curl -s 'http://127.0.0.1:8088/api/v1/auth/door-ticket?target=http://hello.localhost/' 2>/dev/null || echo '{}')"
if echo "$dt" | grep -q 'not_signed_in'; then
  echo "✓ door-ticket route alive (not_signed_in when logged out)"
elif echo "$dt" | grep -q 'not_found'; then
  echo "✗ door-ticket not_found — restart tower-api"
  fail=1
else
  echo "? door-ticket unexpected: $dt"
  fail=1
fi

code="$(curl -s -o /dev/null -w '%{http_code}' 'http://pockit.localhost/signin' 2>/dev/null || echo 000)"
if [[ "$code" == "200" ]]; then
  echo "✓ pockit.localhost/signin HTTP 200"
else
  echo "✗ pockit.localhost/signin HTTP $code (expect 200)"
  fail=1
fi

if [[ "$fail" -eq 0 ]]; then
  echo ""
  echo "SSO stack smoke passed — sign in at http://pockit.localhost/signin if not already."
  exit 0
fi

echo ""
echo "SSO stack smoke FAILED — see runbooks/01-triage-stack.md and 02-recover-local-stack.md"
exit 1
