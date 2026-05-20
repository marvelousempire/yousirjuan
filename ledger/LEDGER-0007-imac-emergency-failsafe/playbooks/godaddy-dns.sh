#!/usr/bin/env bash
#
# godaddy-dns.sh — minimal GoDaddy DNS API helper for the watchdog.
#
# Reads credentials from ~/.config/yousirjuan/godaddy.env (chmod 600,
# gitignored, never committed). Format:
#
#   GODADDY_API_KEY=...
#   GODADDY_API_SECRET=...
#
# Usage:
#   godaddy-dns.sh get <domain> <subdomain>
#     → prints the current A record value (just the IP, one line)
#   godaddy-dns.sh set <domain> <subdomain> <ip> [<ttl>]
#     → updates the A record. TTL defaults to 600.
#
# Returns exit 0 on success, 1 on any API error.
# All stderr goes to caller; stdout is just the value (for `get`) or empty.
#
# This script DOES make real API calls — the watchdog's DRY_RUN flag gates
# whether the watchdog invokes us at all.

set -euo pipefail

CREDS_FILE="$HOME/.config/yousirjuan/godaddy.env"

if [ ! -f "$CREDS_FILE" ]; then
  echo "godaddy-dns.sh: creds file missing at $CREDS_FILE" >&2
  echo "create it with chmod 600 containing GODADDY_API_KEY and GODADDY_API_SECRET" >&2
  exit 1
fi

# shellcheck source=/dev/null
. "$CREDS_FILE"

if [ -z "${GODADDY_API_KEY:-}" ] || [ -z "${GODADDY_API_SECRET:-}" ]; then
  echo "godaddy-dns.sh: GODADDY_API_KEY or GODADDY_API_SECRET missing in $CREDS_FILE" >&2
  exit 1
fi

AUTH_HEADER="Authorization: sso-key ${GODADDY_API_KEY}:${GODADDY_API_SECRET}"

action="${1:-help}"

case "$action" in
  get)
    domain="${2:?need <domain>}"
    sub="${3:?need <subdomain>}"
    curl -sf -m 15 -H "$AUTH_HEADER" \
      "https://api.godaddy.com/v1/domains/${domain}/records/A/${sub}" \
      | python3 -c "import json,sys; recs=json.load(sys.stdin); print(recs[0]['data'] if recs else '')"
    ;;

  set)
    domain="${2:?need <domain>}"
    sub="${3:?need <subdomain>}"
    ip="${4:?need <ip>}"
    ttl="${5:-600}"
    body=$(python3 -c "import json,sys; print(json.dumps([{'data':'$ip','ttl':$ttl}]))")
    curl -sf -m 15 -X PUT \
      -H "$AUTH_HEADER" \
      -H "Content-Type: application/json" \
      -d "$body" \
      "https://api.godaddy.com/v1/domains/${domain}/records/A/${sub}" \
      > /dev/null
    ;;

  help|-h|--help)
    sed -n '3,25p' "$0"
    ;;

  *)
    echo "godaddy-dns.sh: unknown action: $action" >&2
    sed -n '3,25p' "$0" >&2
    exit 1
    ;;
esac
