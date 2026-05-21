#!/usr/bin/env bash
# audit-vhost-upstreams.sh — for every nginx vhost, report whether its
# upstream is actually listening. Pure read-only.
#
# Output: a table.
#   VHOST  EXT_HTTP  PROXY_PASS  UPSTREAM_LIVE  (listening | ✗ DOWN | ?)
#
# Use weekly. Pair with LEDGER-0012's /sites endpoint for continuous monitoring.
# Run as root (sudo) so it can read /etc/nginx/sites-enabled/.

set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "must run as root (sudo)"; exit 1; }

SITES_DIR="${SITES_DIR:-/etc/nginx/sites-enabled}"
PROBE_TIMEOUT="${PROBE_TIMEOUT:-3}"

printf "%-32s %-9s %-26s %s\n" "VHOST" "EXT_HTTP" "PROXY_PASS" "UPSTREAM"
printf -- "─%.0s" {1..78}; echo
DOWN_COUNT=0

for f in "$SITES_DIR"/*; do
  [[ -f "$f" ]] || continue
  vhost=$(basename "$f")
  server_name=$(grep -m1 -E "^\s*server_name" "$f" | awk '{print $2}' | tr -d ';' || true)
  proxy_pass=$(grep -m1 -E "^\s*proxy_pass" "$f" | awk '{print $2}' | tr -d ';' || true)

  # External probe — only if server_name looks like a real DNS name
  ext=""
  if [[ "$server_name" =~ \. ]]; then
    ext=$(curl -s -o /dev/null -w '%{http_code}' -m "$PROBE_TIMEOUT" "https://$server_name/" 2>/dev/null || echo "000")
  fi

  # Upstream-port liveness
  up_status="?"
  port=""
  if [[ -n "$proxy_pass" ]]; then
    port=$(echo "$proxy_pass" | sed -E 's|.*:([0-9]+).*|\1|')
    if [[ -n "$port" && "$port" =~ ^[0-9]+$ ]] && ss -tln 2>/dev/null | grep -q ":$port "; then
      up_status="listening"
    else
      up_status="✗ DOWN"
      ((DOWN_COUNT++)) || true
    fi
  fi

  printf "%-32s %-9s %-26s %s\n" \
    "${vhost:0:32}" "${ext:-—}" "${proxy_pass:-—}" "$up_status"
done

echo
printf "Total vhosts: %d  |  Dead upstreams: %d\n" \
  "$(ls "$SITES_DIR" 2>/dev/null | wc -l)" "$DOWN_COUNT"
