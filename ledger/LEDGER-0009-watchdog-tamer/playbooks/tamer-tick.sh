#!/usr/bin/env bash
# tamer-tick.sh — single-shot analysis pass.
#
# Reads watchdog state + log, calls local Ollama, writes structured
# suggestions to ~/Library/yousirjuan-state/tamer-suggestions.json.
#
# Triggered by launchd every 15 min, or manually for testing.
# Strictly read-only against the watchdog — never POSTs to /settings.
# Operator must approve each suggestion via DustPan's "Apply" button
# (LEDGER-0009 Phase 3 — separate PR in marvelousempire/dustpan).
#
# Dependencies: bash, curl, python3 (macOS ships all three). No jq required.

set -euo pipefail

# ─────────────────────────── config ───────────────────────────

STATE_DIR="$HOME/Library/yousirjuan-state"
WATCHDOG_STATE="$STATE_DIR/vps-watchdog.json"
WATCHDOG_CONF="$STATE_DIR/vps-watchdog.conf"            # may not exist before LEDGER-0008 lands
WATCHDOG_LOG="$HOME/Library/Logs/yousirjuan-vps-watchdog.log"
TAMER_LOG="$HOME/Library/Logs/yousirjuan-watchdog-tamer.log"
SUGGESTIONS_FILE="$STATE_DIR/tamer-suggestions.json"
HISTORY_FILE="$STATE_DIR/tamer-history.jsonl"

OLLAMA_URL="${OLLAMA_URL:-http://127.0.0.1:11434}"
TAMER_MODEL="${TAMER_MODEL:-llama3.2:3b}"
LOG_TAIL_LINES="${LOG_TAIL_LINES:-20}"
MAX_PROMPT_BYTES="${MAX_PROMPT_BYTES:-4000}"
NUM_PREDICT="${NUM_PREDICT:-300}"
KEEP_ALIVE="${KEEP_ALIVE:-1h}"

mkdir -p "$STATE_DIR" "$(dirname "$TAMER_LOG")"
NUM_PREDICT_FOR_PY="$NUM_PREDICT"
export NUM_PREDICT KEEP_ALIVE
touch "$WATCHDOG_LOG" "$HISTORY_FILE"

# ─────────────────────────── helpers ───────────────────────────

ts() { date '+%Y-%m-%dT%H:%M:%S%z'; }
log() { printf "[%s] %s\n" "$(ts)" "$*" | tee -a "$TAMER_LOG"; }
die() { log "ERROR: $*"; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

have curl    || die "curl missing"
have python3 || die "python3 missing"

# ─────────────────────────── system prompt ───────────────────────────

SYSTEM_PROMPT='You are the "Tamer" — an SRE-discipline AI agent advising on a VPS DNS-failover watchdog (LEDGER-0007).

You receive: (1) current watchdog state JSON, (2) current watchdog conf JSON (or null if not yet configured), (3) the last ~60 log lines.

Your job is to identify ONLY high-confidence, actionable issues. Patterns to watch for:

- FLAPPING: a subdomain oscillating between vps and failover within a single hysteresis window. Suggest raising hysteresis_min_seconds.
- CHRONIC SINGLE-TARGET FAILURE: one target failing for many ticks while others are fine. The target may be upstream-dead, not the VPS host. Suggest removing the target from the list OR notifying the operator that the upstream service (e.g. n8n on workflow.yousirjuan.ai) is the actual problem.
- PROBE TIMEOUTS: many fails with curl exit codes (000). Suggest raising probe_timeout_seconds.
- DRY_RUN MISCONFIG: dry_run=false but failover_ip empty, OR dry_run=true forever despite ready Phase-2 standbys.
- NEW TARGETS REGISTERED IN log but not in conf.targets: suggest adding them to conf.
- BORING/NORMAL STATE: if there is nothing to suggest, return an empty suggestions array. DO NOT invent issues.

Output STRICT JSON of this exact shape, no preamble, no markdown:

{
  "suggestions": [
    {
      "id": "short-kebab-slug",
      "severity": "advisory" | "warning" | "critical",
      "rationale": "1-2 sentence human-readable explanation",
      "setting_diff": { "<conf key>": { "current": <current value>, "proposed": <proposed value> } },
      "evidence": ["log line excerpts or state observations supporting this"]
    }
  ]
}

If there is nothing actionable, return {"suggestions": []}.

CONSTRAINTS:
- Never suggest dry_run=false unless conf.failover_ip is set AND log evidence shows standby reachable.
- Never invent new targets — only suggest add/remove for targets actually evidenced in the log.
- Never suggest more than 5 items per tick.
- Use ONLY keys that exist in the watchdog conf schema (dry_run, vps_ip, failover_ip, targets, strikes_to_swap, strikes_to_revert, hysteresis_min_seconds, probe_timeout_seconds).
'

# ─────────────────────────── main ───────────────────────────

log "── tick start"

# Everything-in-python — resolve model, build bundle, call Ollama, write outputs.
SUGGESTIONS_FILE="$SUGGESTIONS_FILE" \
HISTORY_FILE="$HISTORY_FILE" \
WATCHDOG_STATE="$WATCHDOG_STATE" \
WATCHDOG_CONF="$WATCHDOG_CONF" \
WATCHDOG_LOG="$WATCHDOG_LOG" \
TAMER_LOG="$TAMER_LOG" \
OLLAMA_URL="$OLLAMA_URL" \
TAMER_MODEL="$TAMER_MODEL" \
LOG_TAIL_LINES="$LOG_TAIL_LINES" \
MAX_PROMPT_BYTES="$MAX_PROMPT_BYTES" \
SYSTEM_PROMPT="$SYSTEM_PROMPT" \
python3 - <<'PYEOF'
import json, os, sys, time, urllib.request, urllib.error

SUGG    = os.environ["SUGGESTIONS_FILE"]
HIST    = os.environ["HISTORY_FILE"]
STATE_F = os.environ["WATCHDOG_STATE"]
CONF_F  = os.environ["WATCHDOG_CONF"]
LOG_F   = os.environ["WATCHDOG_LOG"]
TLOG    = os.environ["TAMER_LOG"]
OLLAMA  = os.environ["OLLAMA_URL"]
PREFER  = os.environ["TAMER_MODEL"]
TAIL_N  = int(os.environ["LOG_TAIL_LINES"])
MAX_B   = int(os.environ["MAX_PROMPT_BYTES"])
NPRED   = int(os.environ["NUM_PREDICT"])
KEEP    = os.environ["KEEP_ALIVE"]
SYSPRM  = os.environ["SYSTEM_PROMPT"]

def tlog(msg):
    line = f"[{time.strftime('%Y-%m-%dT%H:%M:%S%z')}] {msg}"
    print(line)
    with open(TLOG, "a") as f:
        f.write(line + "\n")

def read_json(path, default):
    try:
        with open(path, "r") as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return default

def tail_lines(path, n):
    try:
        with open(path, "rb") as f:
            data = f.read()
        return b"\n".join(data.splitlines()[-n:]).decode("utf-8", errors="replace")
    except FileNotFoundError:
        return ""

def http_json(url, body=None, timeout=10):
    headers = {"Content-Type": "application/json"} if body else {}
    data = json.dumps(body).encode() if body else None
    req = urllib.request.Request(url, data=data, headers=headers)
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read())

# 1. Resolve model
try:
    tags = http_json(f"{OLLAMA}/api/tags", timeout=5)
except Exception as e:
    tlog(f"ERROR: ollama /api/tags failed: {e}")
    sys.exit(1)
available = [m["name"] for m in tags.get("models", [])]
if not available:
    tlog("ERROR: no Ollama models pulled")
    sys.exit(1)
chain = [PREFER, "llama3.2:3b", "gemma2:2b", "gemma4:latest", "llama3.1:8b"]
model = next((m for m in chain if m in available), available[0])
tlog(f"  model: {model}  (available: {', '.join(available)})")

# 2. Build bundle
bundle = {
    "generated_at": time.strftime("%Y-%m-%dT%H:%M:%S%z"),
    "watchdog_state": read_json(STATE_F, {}),
    "watchdog_conf":  read_json(CONF_F, None),
    "recent_log":     tail_lines(LOG_F, TAIL_N),
}
prompt = f"Analyze this watchdog snapshot and respond with the strict JSON specified in the system prompt.\n\nINPUT:\n{json.dumps(bundle, indent=2)}"
if len(prompt) > MAX_B:
    prompt = prompt[:MAX_B]
    tlog(f"  warn: prompt truncated to {MAX_B} bytes")
tlog(f"  bundle: {len(json.dumps(bundle))} bytes")

# 3. Call Ollama
t0 = time.time()
try:
    resp = http_json(f"{OLLAMA}/api/generate", {
        "model":  model,
        "system": SYSPRM,
        "prompt": prompt,
        "stream": False,
        "format": "json",
        "keep_alive": KEEP,
        "options": {"temperature": 0.2, "num_predict": NPRED},
    }, timeout=300)
except Exception as e:
    tlog(f"ERROR: ollama /api/generate failed: {e}")
    sys.exit(1)
elapsed = int(time.time() - t0)
tlog(f"  ollama responded in {elapsed}s")

# 4. Parse + validate
raw_text = resp.get("response", "")
try:
    parsed = json.loads(raw_text)
except json.JSONDecodeError:
    tlog("  warn: model returned non-JSON; treating as empty suggestions")
    parsed = {"suggestions": []}
if not isinstance(parsed, dict) or not isinstance(parsed.get("suggestions"), list):
    tlog("  warn: model JSON missing .suggestions[]; treating as empty")
    parsed = {"suggestions": []}

n = len(parsed["suggestions"])
tlog(f"  suggestions: {n}")

# 5. Write current snapshot atomically
out = {
    "generated_at": time.strftime("%Y-%m-%dT%H:%M:%S%z"),
    "model": model,
    "suggestions": parsed["suggestions"],
}
tmp = SUGG + ".tmp"
with open(tmp, "w") as f:
    json.dump(out, f, indent=2)
os.replace(tmp, SUGG)

# 6. Append to history JSONL (append-only)
with open(HIST, "a") as f:
    f.write(json.dumps(out) + "\n")

tlog(f"── tick complete ({n} suggestion(s) → {SUGG})")
PYEOF
