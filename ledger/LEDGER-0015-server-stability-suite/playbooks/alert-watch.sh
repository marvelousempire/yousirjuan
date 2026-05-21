#!/usr/bin/env bash
# alert-watch.sh — macOS notification daemon.
#
# Polls the LEDGER-0012 VPS agent every 60s. Fires osascript native notification
# when any threshold crosses. Debounced 5 min per threshold so you don't get spammed.
#
# Triggers:
#   - mem_pct_used > 85
#   - swap_pct_used > 50
#   - load_1m > (cpus * 4)  — assumes 4 CPUs by default; override CPUS env
#   - any subdomain returns HTTP 5xx or 000
#
# Override env vars: AGENT_URL, MEM_THRESHOLD, SWAP_THRESHOLD, LOAD_PER_CPU, CPUS

set -uo pipefail

AGENT_URL="${AGENT_URL:-http://vps-godaddy:9878}"
MEM_THRESHOLD="${MEM_THRESHOLD:-85}"
SWAP_THRESHOLD="${SWAP_THRESHOLD:-50}"
LOAD_PER_CPU="${LOAD_PER_CPU:-4}"
CPUS="${CPUS:-4}"
DEBOUNCE_SECONDS="${DEBOUNCE_SECONDS:-300}"

STATE_DIR="$HOME/.local/share/yousirjuan"
DEBOUNCE_FILE="$STATE_DIR/alert-debounce.json"
LOG_FILE="$HOME/Library/Logs/yousirjuan-alert-watch.log"

mkdir -p "$STATE_DIR" "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"
[[ -f "$DEBOUNCE_FILE" ]] || echo '{}' > "$DEBOUNCE_FILE"

ts() { date '+%Y-%m-%dT%H:%M:%S%z'; }
log() { printf "[%s] %s\n" "$(ts)" "$*" >> "$LOG_FILE"; }

should_fire() {
  local topic="$1"
  local now last
  now=$(date +%s)
  last=$(python3 -c "import json;d=json.load(open('$DEBOUNCE_FILE'));print(d.get('$topic',0))" 2>/dev/null || echo 0)
  (( now - last >= DEBOUNCE_SECONDS ))
}

mark_fired() {
  local topic="$1"
  python3 -c "
import json
d = json.load(open('$DEBOUNCE_FILE'))
d['$topic'] = $(date +%s)
json.dump(d, open('$DEBOUNCE_FILE', 'w'))
"
}

notify() {
  local title="$1" subtitle="$2" message="$3"
  # Escape double-quotes for AppleScript
  title=$(printf '%s' "$title" | sed 's/"/\\"/g')
  subtitle=$(printf '%s' "$subtitle" | sed 's/"/\\"/g')
  message=$(printf '%s' "$message" | sed 's/"/\\"/g')
  osascript -e "display notification \"$message\" with title \"$title\" subtitle \"$subtitle\" sound name \"Sosumi\""
  log "FIRED: $title — $subtitle — $message"
}

check_thresholds() {
  local all_json
  all_json=$(curl -sf -m 5 "$AGENT_URL/all" 2>/dev/null) || {
    if should_fire "agent_unreachable"; then
      notify "🔴 VPS agent unreachable" "$AGENT_URL" "Cannot fetch /all — VPS agent (LEDGER-0012) may be down."
      mark_fired "agent_unreachable"
    fi
    log "agent unreachable"
    return
  }

  local mem swap load
  mem=$(echo "$all_json" | python3 -c 'import sys,json; print(json.load(sys.stdin)["system"].get("mem_pct_used",0))')
  swap=$(echo "$all_json" | python3 -c 'import sys,json; print(json.load(sys.stdin)["system"].get("swap_pct_used",0))')
  load=$(echo "$all_json" | python3 -c 'import sys,json; print(json.load(sys.stdin)["system"].get("load_1m",0))')

  local mem_int=${mem%.*} swap_int=${swap%.*}
  local load_cap=$(( CPUS * LOAD_PER_CPU ))
  local load_int=${load%.*}

  if (( mem_int > MEM_THRESHOLD )); then
    if should_fire "mem"; then
      notify "🔥 VPS memory hot" "${mem}% used (threshold ${MEM_THRESHOLD}%)" "Run server-tamer status; check /vps in Nephew."
      mark_fired "mem"
    fi
  fi
  if (( swap_int > SWAP_THRESHOLD )); then
    if should_fire "swap"; then
      notify "🟠 VPS swap hot" "${swap}% used (threshold ${SWAP_THRESHOLD}%)" "Kernel is dehydrating pages — investigate."
      mark_fired "swap"
    fi
  fi
  if (( load_int > load_cap )); then
    if should_fire "load"; then
      notify "🔴 VPS load high" "load 1m=${load} (cap ${load_cap})" "Check /processes for runaway."
      mark_fired "load"
    fi
  fi

  # Per-site 5xx / 000 check
  echo "$all_json" | python3 -c '
import sys, json
d = json.load(sys.stdin)
for s in d.get("sites", {}).get("sites", []):
    code = s.get("http_code", "")
    if code == "000" or (code and code.startswith("5")):
        print(s["sub"] + "|" + code)
' | while IFS='|' read -r sub code; do
    if should_fire "site_$sub"; then
      notify "🌐 Site $sub down" "HTTP $code" "Check vhost + upstream in Nephew /vps."
      mark_fired "site_$sub"
    fi
  done

  # LEDGER-0020 Layer A: poll intent-reality drift report (over SSH for now;
  # future PR adds GET /intent-drift to LEDGER-0012 agent for direct HTTP poll).
  local drift_count
  drift_count=$(ssh -o BatchMode=yes -o ConnectTimeout=3 vps-godaddy \
    "cat /var/lib/yousirjuan/intent-drift-report.json 2>/dev/null | python3 -c \"import json,sys; d=json.load(sys.stdin); print(d.get('drift_count',0))\" 2>/dev/null" 2>/dev/null || echo 0)
  if (( drift_count > 0 )); then
    local drift_topics
    drift_topics=$(ssh -o BatchMode=yes -o ConnectTimeout=3 vps-godaddy \
      "cat /var/lib/yousirjuan/intent-drift-report.json 2>/dev/null | python3 -c \"import json,sys; d=json.load(sys.stdin); print(', '.join(e['topic'] for e in d.get('drift_entries',[])))\"" 2>/dev/null || echo unknown)
    if should_fire "intent_drift"; then
      notify "🟣 Intent-reality drift" "$drift_count file(s): $drift_topics" "Run intent.sh remove <topic> OR fix the actual state."
      mark_fired "intent_drift"
    fi
  fi
}

# Single-tick mode (for testing) or daemon mode
if [[ "${1:-}" == "--once" ]]; then
  check_thresholds
else
  while true; do
    check_thresholds
    sleep 60
  done
fi
