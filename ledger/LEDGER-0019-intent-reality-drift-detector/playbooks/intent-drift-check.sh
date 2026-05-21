#!/usr/bin/env bash
# intent-drift-check.sh — detect drift between operator-intent files and reality.
#
# Per LEDGER-0019 + Universal Rule 16.
#
# Reads /etc/yousirjuan/operator-intent.d/*.md and for each one checks whether
# the actual service/container/process state matches what the intent file says.
#
# Drift = intent says "stopped" but reality says "running" (or vice versa).
#
# Each intent file may include a structured `## Drift check` section like:
#
#   ## Drift check
#   expect: stopped
#   check_cmd: systemctl is-active n8n-nephew.service
#   match_output: inactive | failed | unknown
#
# If absent, falls back to a built-in heuristic on the topic name.
#
# Output: prints drift table. Exit 0 if no drift, 1 if drift detected.
# Logs every check to /var/log/yousirjuan-intent-drift.log.
# Writes a machine-readable report to /var/lib/yousirjuan/intent-drift-report.json.

set -uo pipefail

INTENT_DIR="${INTENT_DIR:-/etc/yousirjuan/operator-intent.d}"
LOG_FILE="${LOG_FILE:-/var/log/yousirjuan-intent-drift.log}"
REPORT_FILE="${REPORT_FILE:-/var/lib/yousirjuan/intent-drift-report.json}"

mkdir -p "$(dirname "$LOG_FILE")" "$(dirname "$REPORT_FILE")"
touch "$LOG_FILE"

ts() { date '+%Y-%m-%dT%H:%M:%S%z'; }
log() { printf "[%s] %s\n" "$(ts)" "$*" | tee -a "$LOG_FILE"; }

# Built-in heuristics: topic name → check command + expected state
heuristic_check() {
  local topic="$1"
  case "$topic" in
    n8n-stopped)            echo "systemctl is-active n8n-nephew.service|inactive|failed";;
    gitlab-stopped)         echo "docker_state gitlab|exited|missing";;
    github-actions-runner-stopped) echo "systemctl is-active actions.runner.marvelousempire-red-e-play-app.readyplay-vps.service|inactive|failed";;
    clinic-systemd-managed) echo "systemctl is-active clinic.service|active";;
    swap-doubled-to-8gb)    echo "free_swap_gb_at_least 8|ok";;
    sshd-oom-protected)     echo "sshd_oom_score -1000|ok";;
    *) echo "";;  # no heuristic
  esac
}

# Compound check primitives
docker_state() {
  local name="$1"
  docker inspect --format '{{.State.Status}}' "$name" 2>/dev/null || echo "missing"
}

free_swap_gb_at_least() {
  local target="$1"
  local total_kb; total_kb=$(awk '/SwapTotal/{print $2}' /proc/meminfo)
  local total_gb=$(( total_kb / 1024 / 1024 ))
  [[ "$total_gb" -ge "$target" ]] && echo "ok ${total_gb}GB" || echo "drift ${total_gb}GB (expected ${target})"
}

sshd_oom_score() {
  local expected="$1"
  local pid; pid=$(pidof sshd | tr ' ' '\n' | head -1)
  local actual="?"
  [[ -n "$pid" ]] && actual=$(cat "/proc/$pid/oom_score_adj" 2>/dev/null)
  [[ "$actual" == "$expected" ]] && echo "ok $actual" || echo "drift $actual (expected $expected)"
}

# ─── main ────────────────────────────────────────────────────────────────────

drift_count=0
total_count=0
drift_entries=()

[[ -d "$INTENT_DIR" ]] || { log "no intent dir at $INTENT_DIR"; exit 0; }

shopt -s nullglob
for f in "$INTENT_DIR"/*.md; do
  total_count=$((total_count + 1))
  topic=$(basename "$f" .md)

  # Try parsing structured "## Drift check" section first
  check_spec=""
  if grep -q "^## Drift check" "$f" 2>/dev/null; then
    check_cmd=$(awk '/^## Drift check/{flag=1; next} flag && /^check_cmd:/{sub(/^check_cmd: */,""); print; exit}' "$f")
    match=$(awk '/^## Drift check/{flag=1; next} flag && /^match_output:/{sub(/^match_output: */,""); print; exit}' "$f")
    [[ -n "$check_cmd" && -n "$match" ]] && check_spec="${check_cmd}|${match}"
  fi

  # Fall back to heuristic
  [[ -z "$check_spec" ]] && check_spec=$(heuristic_check "$topic")

  if [[ -z "$check_spec" ]]; then
    log "  ?  $topic — no drift check defined; skipping"
    continue
  fi

  cmd="${check_spec%%|*}"
  expected_alternatives="${check_spec#*|}"

  # Run the check
  actual=$(eval "$cmd" 2>&1 | head -1 | tr -d '\n')

  # Compare against pipe-separated alternatives
  ok=0
  IFS='|' read -ra alts <<<"$expected_alternatives"
  for alt in "${alts[@]}"; do
    if [[ "$actual" == "$alt"* || "$actual" == "ok"* ]]; then
      ok=1; break
    fi
  done

  if (( ok )); then
    log "  ✓  $topic — reality matches ($actual)"
  else
    drift_count=$((drift_count + 1))
    drift_entries+=("$topic|$actual|$expected_alternatives")
    log "  ✗  DRIFT: $topic — got '$actual', expected '$expected_alternatives'"

    # LEDGER-0020 Layer D: auto-heal if the intent file opts in with
    #   `auto_heal: stop` (or `auto_heal: start`) in its `## Drift check` section.
    heal=$(awk '/^## Drift check/{flag=1; next} flag && /^auto_heal:/{sub(/^auto_heal: */,""); print; exit}' "$f")
    if [[ -n "${heal:-}" ]]; then
      log "  🩹 auto_heal=$heal requested by intent file; attempting"
      # Heuristic: if the topic looks like "<svc>-stopped" and heal=stop, run systemctl stop.
      # For docker containers (gitlab-stopped), use docker stop.
      case "$topic" in
        n8n-stopped|*-stopped)
          if [[ "$heal" == "stop" ]]; then
            # Try as systemd unit
            unit=$(python3 -c "import json; m=json.load(open('/etc/yousirjuan/intent-unit-map.json',));print([u for u,c in m.items() if c.get('topic')=='$topic' and not u.startswith('_')][0])" 2>/dev/null || echo "")
            if [[ -n "$unit" ]]; then
              log "    → systemctl stop $unit"
              systemctl stop "$unit" 2>&1 | head -3 | sed 's/^/      /' || true
            elif [[ "$topic" == "gitlab-stopped" ]]; then
              log "    → docker stop gitlab gitlab-runner"
              docker stop gitlab gitlab-runner 2>&1 | head -3 | sed 's/^/      /' || true
            else
              log "    → no known heal mapping for $topic; skipping"
            fi
          fi
          ;;
      esac
    fi
  fi
done

# Write JSON report
python3 - <<PYEOF
import json
report = {
    "ts": "$(ts)",
    "total": $total_count,
    "drift_count": $drift_count,
    "drift_entries": [
        {"topic": p.split("|")[0], "actual": p.split("|")[1], "expected": p.split("|")[2]}
        for p in [$(printf '"%s",' "${drift_entries[@]:-}")]
        if p
    ]
}
import pathlib
pathlib.Path("$REPORT_FILE").write_text(json.dumps(report, indent=2))
PYEOF

log "── summary: $drift_count drift / $total_count intent files"

if (( drift_count > 0 )); then
  exit 1
fi
exit 0
