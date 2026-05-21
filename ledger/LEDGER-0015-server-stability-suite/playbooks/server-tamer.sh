#!/usr/bin/env bash
# server-tamer.sh — the proactive killer.
#
# Polls the LEDGER-0012 VPS agent's /system + /processes every 30s. Three tiers:
#   85% mem → WARN (log + write transient intent file)
#   90% mem → WARN_LOUD (escalate intent file)
#   92% mem sustained 2 ticks (60s) → KILL highest-RSS non-protected user process
#                                     + write loud operator-intent file documenting why
#
# Also writes /var/lib/yousirjuan/system-history.jsonl every tick (last 24h).
#
# Runs as a systemd service on the VPS. Same auth as the agent (abrownsanta).
# Cannot kill root processes — by design. If a root process is the offender,
# operator handles via SSH.
#
# Protected from kill (never targeted, even if largest):
#   - PID 1, sshd, systemd, dbus
#   - LEDGER-0007 watchdog (if running)
#   - LEDGER-0012 agent itself (self-protect)
#   - this script (self-protect)
#   - postgres, redis, gitaly (data-loss risk)
#   - anything matching patterns in /etc/yousirjuan/server-tamer-protected.conf

set -uo pipefail

AGENT_URL="${AGENT_URL:-http://127.0.0.1:9878}"
TICK_SECONDS="${TICK_SECONDS:-30}"
MEM_WARN_PCT="${MEM_WARN_PCT:-85}"
MEM_WARN_LOUD_PCT="${MEM_WARN_LOUD_PCT:-90}"
MEM_KILL_PCT="${MEM_KILL_PCT:-92}"
SUSTAINED_TICKS_TO_KILL="${SUSTAINED_TICKS_TO_KILL:-2}"

STATE_DIR="/var/lib/yousirjuan"
STATE_FILE="$STATE_DIR/server-tamer-state.json"
HISTORY_FILE="$STATE_DIR/system-history.jsonl"
LOG_FILE="/var/log/yousirjuan-server-tamer.log"
INTENT_DIR="/etc/yousirjuan/operator-intent.d"
PROTECTED_CONF="/etc/yousirjuan/server-tamer-protected.conf"

mkdir -p "$STATE_DIR" "$(dirname "$LOG_FILE")"
touch "$HISTORY_FILE" "$LOG_FILE"

# Default protected list (operator can add to PROTECTED_CONF; one regex per line).
DEFAULT_PROTECTED='^/sbin/init$|/lib/systemd/systemd|sshd$|sshd:|dbus-daemon|/usr/sbin/postgres|/usr/sbin/redis-server|/opt/gitlab/embedded/bin/postgres|/opt/gitlab/embedded/bin/redis|/opt/gitlab/embedded/bin/gitaly|yousirjuan-vps-agent|server-tamer|vps-watchdog|tailscaled'

ts() { date '+%Y-%m-%dT%H:%M:%S%z'; }
log() { printf "[%s] %s\n" "$(ts)" "$*" | tee -a "$LOG_FILE"; }

# Read counter from state file
get_counter() { jq -r '.over_kill_threshold_consecutive_ticks // 0' "$STATE_FILE" 2>/dev/null || echo 0; }
set_counter() {
  local n="$1"
  printf '{"over_kill_threshold_consecutive_ticks": %s, "last_tick": "%s"}\n' "$n" "$(ts)" > "$STATE_FILE.tmp"
  mv "$STATE_FILE.tmp" "$STATE_FILE"
}

# Build a regex of protected patterns
protected_regex() {
  local patterns="$DEFAULT_PROTECTED"
  if [[ -f "$PROTECTED_CONF" ]]; then
    while IFS= read -r line; do
      [[ -z "$line" || "$line" =~ ^# ]] && continue
      patterns="$patterns|$line"
    done < "$PROTECTED_CONF"
  fi
  echo "$patterns"
}

# Fetch /system + /processes from the agent
fetch_state() {
  local sys procs
  sys=$(curl -sf -m 5 "$AGENT_URL/system") || { log "ERROR: cannot reach $AGENT_URL/system"; return 1; }
  procs=$(curl -sf -m 5 "$AGENT_URL/processes") || { log "ERROR: cannot reach $AGENT_URL/processes"; return 1; }
  printf '%s\n%s' "$sys" "$procs"
}

# Choose the largest non-protected non-root non-PID-too-low process by RSS
pick_victim() {
  local procs_json="$1"
  local proto; proto=$(protected_regex)
  # Filter: user != root, pid >= 100, command doesn't match proto
  # Return: pid|user|command|rss_kb of the highest RSS that qualifies
  jq -r --arg proto "$proto" '
    .by_mem[]
    | select(.user != "root" and .pid >= 100)
    | select(.command | test($proto) | not)
    | "\(.pid)|\(.user)|\(.rss_kb)|\(.command)"
  ' <<<"$procs_json" 2>/dev/null | head -1
}

# Append the current /system snapshot to the rotating history (last 2880 entries = 24h at 30s)
append_history() {
  local sys_json="$1"
  echo "$sys_json" >> "$HISTORY_FILE"
  # Rotate: keep last 2880 lines (~24h at 30s ticks)
  if (( $(wc -l < "$HISTORY_FILE") > 3000 )); then
    tail -2880 "$HISTORY_FILE" > "$HISTORY_FILE.tmp" && mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"
  fi
}

# Write an intent file recording what we just killed
write_kill_intent() {
  local pid="$1" user="$2" rss_kb="$3" cmd="$4" mem_pct="$5"
  local topic; topic="server-tamer-killed-pid-$pid-$(date +%s)"
  local f="$INTENT_DIR/${topic}.md"
  mkdir -p "$INTENT_DIR"
  cat > "$f" <<EOF
**STOP. DO NOT just restart the killed service if it auto-restarts.**
This was an automated kill by server-tamer to prevent an OOM cascade.
Read why, fix the underlying memory issue, THEN decide whether to restart.

- **Topic:** ${topic}
- **What:** server-tamer killed PID ${pid} (user=${user}, RSS=${rss_kb}KB)
- **When:** $(ts)
- **Set by:** server-tamer.service on $(hostname)
- **Host:** $(hostname)
- **Mem at kill:** ${mem_pct}%

## Why

Memory usage exceeded ${MEM_KILL_PCT}% for ${SUSTAINED_TICKS_TO_KILL} consecutive ticks
(~$((TICK_SECONDS * SUSTAINED_TICKS_TO_KILL))s). server-tamer chose this PID as
the highest-RSS non-protected non-root process to kill BEFORE the kernel
OOM-killer fires and picks sshd/dbus/some other critical victim.

## What was killed

\`\`\`
$cmd
\`\`\`

## How to revert (the right way)

1. Find out WHY that process was using so much memory. Likely a memory leak,
   an npm install of a large package, or an unbounded operation.
2. Fix the root cause (cap the service, sandbox it via LEDGER-0010, etc.).
3. Then restart manually.
4. Remove this intent file:
   \`sudo bash <repo>/ledger/LEDGER-0014-operator-intent-protocol/playbooks/intent.sh remove ${topic}\`

## See also

- /var/log/yousirjuan-server-tamer.log for the kill decision log
- /var/lib/yousirjuan/system-history.jsonl for memory trend in the 24h leading up
- LEDGER-0015 in marvelousempire/yousirjuan for the killer's design
- LEDGER-0011 for the hardening that should reduce kill frequency
EOF
  chmod 644 "$f"
  log "  intent file: $f"
}

# ─── main loop ───────────────────────────────────────────────────────────────

log "── server-tamer started (warn=${MEM_WARN_PCT}% warn_loud=${MEM_WARN_LOUD_PCT}% kill=${MEM_KILL_PCT}% sustained=${SUSTAINED_TICKS_TO_KILL} ticks tick_seconds=${TICK_SECONDS})"

while true; do
  if state=$(fetch_state); then
    sys_json=$(echo "$state" | head -1)
    procs_json=$(echo "$state" | tail -1)

    mem_pct=$(echo "$sys_json" | jq -r '.mem_pct_used // 0')
    swap_pct=$(echo "$sys_json" | jq -r '.swap_pct_used // 0')
    load_1m=$(echo "$sys_json" | jq -r '.load_1m // 0')

    append_history "$sys_json"

    # Convert float to int for comparison
    mem_int=${mem_pct%.*}
    counter=$(get_counter)

    if (( mem_int >= MEM_KILL_PCT )); then
      counter=$((counter + 1))
      set_counter "$counter"
      log "  ⚠⚠⚠ mem=${mem_pct}% KILL_THRESHOLD exceeded (counter=$counter / ${SUSTAINED_TICKS_TO_KILL})"
      if (( counter >= SUSTAINED_TICKS_TO_KILL )); then
        log "  🔪 KILLING highest-RSS user process to prevent OOM cascade"
        victim=$(pick_victim "$procs_json")
        if [[ -z "$victim" ]]; then
          log "  ✗ no eligible victim found (all top processes are protected/root)"
          log "  → escalating: operator must SSH and intervene"
        else
          IFS='|' read -r pid user rss_kb cmd <<<"$victim"
          log "  victim: PID=$pid user=$user RSS=${rss_kb}KB cmd=${cmd:0:80}"
          if kill -TERM "$pid" 2>&1 | tee -a "$LOG_FILE"; then
            log "  ✓ sent TERM to PID $pid"
          else
            log "  ✗ TERM failed; trying KILL"
            kill -KILL "$pid" 2>&1 | tee -a "$LOG_FILE" || log "  ✗ KILL also failed"
          fi
          write_kill_intent "$pid" "$user" "$rss_kb" "$cmd" "$mem_pct"
          # Reset counter after a kill so we don't double-kill on the same spike
          set_counter 0
        fi
      fi
    elif (( mem_int >= MEM_WARN_LOUD_PCT )); then
      set_counter 0
      log "  ⚠⚠ mem=${mem_pct}% swap=${swap_pct}% load=${load_1m} (LOUD warn)"
    elif (( mem_int >= MEM_WARN_PCT )); then
      set_counter 0
      log "  ⚠ mem=${mem_pct}% swap=${swap_pct}% load=${load_1m} (warn)"
    else
      set_counter 0
      # quiet tick — only log every 10th to keep log small
      tick_num=$(( $(date +%s) / TICK_SECONDS ))
      if (( tick_num % 10 == 0 )); then
        log "  ok mem=${mem_pct}% swap=${swap_pct}% load=${load_1m}"
      fi
    fi
  fi
  sleep "$TICK_SECONDS"
done
