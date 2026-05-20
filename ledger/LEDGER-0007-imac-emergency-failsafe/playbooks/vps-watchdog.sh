#!/usr/bin/env bash
#
# vps-watchdog.sh — every-3-min health probe of the VPS-hosted subdomains.
# After 3 consecutive failures on a subdomain, calls GoDaddy API to point its
# A record at the iMac's failover address. After 3 consecutive successes
# (post-swap), reverts.
#
# Triggered by launchd: ~/Library/LaunchAgents/com.yousirjuan.vps-watchdog.plist
# (StartInterval 180 = every 3 min).
#
# DRY_RUN=1 by default — logs decisions but never calls GoDaddy. Flip to 0
# after operator commits to going live (see runbook 03 — enabling-real-swap).
#
# Config (top of file):
#   - DOMAIN: the registered domain in GoDaddy
#   - TARGETS: array of "subdomain|probe-url" pairs to monitor
#   - VPS_IP / FAILOVER_IP: A-record values to swap between
#   - STRIKES_TO_SWAP / STRIKES_TO_REVERT
#   - HYSTERESIS_MIN_SECONDS: min seconds between swaps on the same subdomain
#
# State:
#   ~/Library/yousirjuan-state/vps-watchdog.json
#
# Logs:
#   ~/Library/Logs/yousirjuan-vps-watchdog.log

set -euo pipefail

# ─────────────────────────── config ───────────────────────────

DRY_RUN="${DRY_RUN:-1}"                       # default-safe: doesn't actually swap

DOMAIN="${DOMAIN:-yousirjuan.ai}"
VPS_IP="${VPS_IP:-72.167.151.251}"            # primary
# FAILOVER_IP: where to point traffic when VPS is down. Default empty so the
# watchdog refuses to actually swap until operator fills this in. Possibilities:
#   - iMac's Tailscale Funnel public IP (preferred — Tailscale terminates HTTPS)
#   - iMac's home WAN public IP (only if router port-forwards 80/443)
#   - Cloudflare Tunnel target, etc.
FAILOVER_IP="${FAILOVER_IP:-}"

# Subdomains to monitor. Each entry is "subdomain|probe-url".
# Edit this list to match the operator's actual deployed sites.
TARGETS=(
  "hello|https://hello.yousirjuan.ai/"
  "nephew|https://nephew.yousirjuan.ai/"
  "clinic|https://clinic.yousirjuan.ai/"
  "git|https://git.yousirjuan.ai/"
  "workflow|https://workflow.yousirjuan.ai/"
)

STRIKES_TO_SWAP=3                              # fail threshold before swap
STRIKES_TO_REVERT=3                            # success threshold before revert
HYSTERESIS_MIN_SECONDS=1800                    # min 30 min between swaps per sub
PROBE_TIMEOUT=10                               # seconds per HTTPS probe

STATE_DIR="$HOME/Library/yousirjuan-state"
STATE_FILE="$STATE_DIR/vps-watchdog.json"
CONF_FILE="$STATE_DIR/vps-watchdog.conf"     # LEDGER-0008: settings sourced here (JSON)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GODADDY_HELPER="$SCRIPT_DIR/godaddy-dns.sh"

# ─── LEDGER-0008: load settings from conf file if present, overriding defaults ───
# DustPan writes to this file via the watchdog-state-server's POST /settings.
# We re-read on every tick so settings changes apply within 3 min.
if [[ -f "$CONF_FILE" ]] && command -v jq >/dev/null 2>&1; then
  _conf_dry_run=$(jq -r '.dry_run // empty' "$CONF_FILE" 2>/dev/null)
  _conf_domain=$(jq -r '.domain // empty' "$CONF_FILE" 2>/dev/null)
  _conf_vps_ip=$(jq -r '.vps_ip // empty' "$CONF_FILE" 2>/dev/null)
  _conf_failover_ip=$(jq -r '.failover_ip // empty' "$CONF_FILE" 2>/dev/null)
  _conf_strikes_swap=$(jq -r '.strikes_to_swap // empty' "$CONF_FILE" 2>/dev/null)
  _conf_strikes_revert=$(jq -r '.strikes_to_revert // empty' "$CONF_FILE" 2>/dev/null)
  _conf_hyst=$(jq -r '.hysteresis_min_seconds // empty' "$CONF_FILE" 2>/dev/null)
  _conf_timeout=$(jq -r '.probe_timeout_seconds // empty' "$CONF_FILE" 2>/dev/null)
  # Only override if the conf value is non-empty (preserves env-var precedence too).
  [[ -n "$_conf_dry_run" ]]      && DRY_RUN=$([[ "$_conf_dry_run" == "true" ]] && echo 1 || echo 0)
  [[ -n "$_conf_domain" ]]       && DOMAIN="$_conf_domain"
  [[ -n "$_conf_vps_ip" ]]       && VPS_IP="$_conf_vps_ip"
  [[ -n "$_conf_failover_ip" ]]  && FAILOVER_IP="$_conf_failover_ip"
  [[ -n "$_conf_strikes_swap" ]] && STRIKES_TO_SWAP="$_conf_strikes_swap"
  [[ -n "$_conf_strikes_revert" ]] && STRIKES_TO_REVERT="$_conf_strikes_revert"
  [[ -n "$_conf_hyst" ]]         && HYSTERESIS_MIN_SECONDS="$_conf_hyst"
  [[ -n "$_conf_timeout" ]]      && PROBE_TIMEOUT="$_conf_timeout"
  # Targets: rebuild array from conf if it has any
  _conf_targets=$(jq -r '.targets[]? | "\(.sub)|\(.url)"' "$CONF_FILE" 2>/dev/null)
  if [[ -n "$_conf_targets" ]]; then
    TARGETS=()
    while IFS= read -r line; do
      [[ -n "$line" ]] && TARGETS+=("$line")
    done <<<"$_conf_targets"
  fi
fi

mkdir -p "$STATE_DIR"

# ─────────────────────────── helpers ───────────────────────────

log() {
  local ts; ts=$(date -Iseconds)
  printf "[%s] %s\n" "$ts" "$*"
}

# Read a key from the state JSON. Returns empty if missing.
state_get() {
  local key="$1"
  if [ ! -f "$STATE_FILE" ]; then echo ""; return; fi
  python3 -c "
import json, sys
with open('$STATE_FILE') as f: d = json.load(f)
keys = '$key'.split('.')
v = d
for k in keys:
    if isinstance(v, dict) and k in v: v = v[k]
    else: v = ''; break
print(v if v != '' else '')
"
}

# Atomically update a key in the state JSON.
state_set() {
  local key="$1"
  local val="$2"
  python3 -c "
import json, os
path = '$STATE_FILE'
d = {}
if os.path.exists(path):
    with open(path) as f:
        try: d = json.load(f)
        except: d = {}
keys = '$key'.split('.')
node = d
for k in keys[:-1]:
    node = node.setdefault(k, {})
node[keys[-1]] = '$val'
tmp = path + '.tmp'
with open(tmp, 'w') as f: json.dump(d, f, indent=2, sort_keys=True)
os.replace(tmp, path)
"
}

# Probe a URL. Returns 0 if the server responded with 2xx / 3xx / 4xx.
# Returns non-zero if connection failed (code=000), timed out, or got 5xx.
#
# Rationale: 4xx is a CLIENT error (bad request, unauthorized, etc.). The
# server is alive and responding. For "VPS-is-down" detection we only treat
# 5xx and connection failures as "down" — that's what failover should fire on.
probe_url() {
  local url="$1"
  local code
  code=$(curl -s -o /dev/null -w "%{http_code}" -m "$PROBE_TIMEOUT" "$url" 2>/dev/null || echo "000")
  # 000 = curl couldn't connect / DNS fail / timeout → DOWN
  # 5xx = server failed → DOWN
  # 2xx/3xx/4xx = server responding → UP
  [[ "$code" =~ ^[234][0-9][0-9]$ ]]
}

# Epoch seconds — portable enough for mac + linux.
now_epoch() { date +%s; }

# ─────────────────────────── pre-flight ───────────────────────────

if [ "$DRY_RUN" -eq 1 ]; then
  log "── dry-run tick (DRY_RUN=1; no DNS changes will be made)"
else
  log "── live tick (DRY_RUN=0; real GoDaddy API calls enabled)"
fi

if [ "$DRY_RUN" -eq 0 ] && [ -z "$FAILOVER_IP" ]; then
  log "ERROR: DRY_RUN=0 but FAILOVER_IP is empty. Refusing to swap to nothing."
  log "       Set FAILOVER_IP at the top of vps-watchdog.sh (Tailscale Funnel"
  log "       public IP, or iMac home WAN IP with router port-forward)."
  exit 1
fi

if [ "$DRY_RUN" -eq 0 ] && [ ! -x "$GODADDY_HELPER" ]; then
  log "ERROR: godaddy-dns.sh not executable at $GODADDY_HELPER"
  exit 1
fi

# ─────────────────────────── per-target loop ───────────────────────────

now=$(now_epoch)

for entry in "${TARGETS[@]}"; do
  sub="${entry%%|*}"
  url="${entry##*|}"

  # Read prior state
  fails=$(state_get "targets.$sub.consecutive_fails")
  succs=$(state_get "targets.$sub.consecutive_successes")
  status=$(state_get "targets.$sub.status")           # "vps" or "failover"
  last_swap=$(state_get "targets.$sub.last_swap_epoch")
  fails="${fails:-0}"; succs="${succs:-0}"
  status="${status:-vps}"; last_swap="${last_swap:-0}"

  # Probe
  if probe_url "$url"; then
    fails=0
    succs=$((succs + 1))
    log "  ✓ $sub  ($url)  succ=$succs  status=$status"
  else
    succs=0
    fails=$((fails + 1))
    log "  ✗ $sub  ($url)  fail=$fails  status=$status"
  fi

  # Decision logic
  decision=""
  if [ "$status" = "vps" ] && [ "$fails" -ge "$STRIKES_TO_SWAP" ]; then
    decision="SWAP_TO_FAILOVER"
  elif [ "$status" = "failover" ] && [ "$succs" -ge "$STRIKES_TO_REVERT" ]; then
    decision="REVERT_TO_VPS"
  fi

  # Hysteresis: refuse to swap more than once per HYSTERESIS_MIN_SECONDS per sub
  if [ -n "$decision" ]; then
    elapsed=$((now - last_swap))
    if [ "$last_swap" -ne 0 ] && [ "$elapsed" -lt "$HYSTERESIS_MIN_SECONDS" ]; then
      log "      [hysteresis] $sub last swap ${elapsed}s ago < ${HYSTERESIS_MIN_SECONDS}s; deferring $decision"
      decision=""
    fi
  fi

  # Execute decision
  if [ "$decision" = "SWAP_TO_FAILOVER" ]; then
    new_ip="$FAILOVER_IP"
    new_status="failover"
    log "      $sub: 3 strikes. ${DRY_RUN:+(dry-run) WOULD }SWAP A record $sub.$DOMAIN → $new_ip"
    if [ "$DRY_RUN" -eq 0 ]; then
      if "$GODADDY_HELPER" set "$DOMAIN" "$sub" "$new_ip" 60 2>>"$HOME/Library/Logs/yousirjuan-vps-watchdog.log"; then
        log "      $sub: ✓ GoDaddy A record updated to $new_ip"
        state_set "targets.$sub.status" "$new_status"
        state_set "targets.$sub.last_swap_epoch" "$now"
        fails=0; succs=0
      else
        log "      $sub: ✗ GoDaddy API call failed; will retry next tick"
      fi
    else
      # Dry-run: still record the would-be transition for state-machine consistency
      state_set "targets.$sub.would_be_status" "$new_status"
    fi
  elif [ "$decision" = "REVERT_TO_VPS" ]; then
    new_ip="$VPS_IP"
    new_status="vps"
    log "      $sub: 3 successes. ${DRY_RUN:+(dry-run) WOULD }REVERT A record $sub.$DOMAIN → $new_ip"
    if [ "$DRY_RUN" -eq 0 ]; then
      if "$GODADDY_HELPER" set "$DOMAIN" "$sub" "$new_ip" 600 2>>"$HOME/Library/Logs/yousirjuan-vps-watchdog.log"; then
        log "      $sub: ✓ GoDaddy A record reverted to $new_ip"
        state_set "targets.$sub.status" "$new_status"
        state_set "targets.$sub.last_swap_epoch" "$now"
        fails=0; succs=0
      else
        log "      $sub: ✗ GoDaddy API call failed; will retry next tick"
      fi
    else
      state_set "targets.$sub.would_be_status" "$new_status"
    fi
  fi

  # Persist counters
  state_set "targets.$sub.consecutive_fails" "$fails"
  state_set "targets.$sub.consecutive_successes" "$succs"
  state_set "targets.$sub.last_tick_epoch" "$now"
done

log "── tick complete"
