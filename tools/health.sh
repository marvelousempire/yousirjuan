#!/usr/bin/env bash
# health.sh — One-stop "is the private AI stack actually working?" check.
#
#   bash health.sh            # check + print status table
#   bash health.sh --infer    # also do a real round-trip inference
#
# Exit code:
#   0 if everything critical is OK
#   1 if any critical component is down
# (Warnings don't fail the script.)

set -uo pipefail

FLAG_INFER=0
[[ "${1:-}" == "--infer" ]] && FLAG_INFER=1

# ---- helpers ---------------------------------------------------------------
GREEN="\033[0;32m"; YELLOW="\033[0;33m"; RED="\033[0;31m"; DIM="\033[2m"; BOLD="\033[1m"; RST="\033[0m"

CRITICAL_FAILS=0

row() {
  # row <symbol> <component> <status> [<detail>]
  local sym="$1" comp="$2" status="$3" detail="${4:-}"
  printf "  %b %-22s %-10s %b%s%b\n" "$sym" "$comp" "$status" "$DIM" "$detail" "$RST"
}
ok_row()   { row "${GREEN}✓${RST}" "$1" "OK"     "${2:-}"; }
warn_row() { row "${YELLOW}!${RST}" "$1" "WARN"  "${2:-}"; }
fail_row() { row "${RED}✗${RST}"   "$1" "FAIL"  "${2:-}"; CRITICAL_FAILS=$((CRITICAL_FAILS+1)); }

have() { command -v "$1" >/dev/null 2>&1; }

printf "\n${BOLD}Private AI stack — health check${RST}\n"
printf "%s  %s\n\n" "$(date '+%F %T')" "$(uname -srm)"

# ---- 1. Ollama ------------------------------------------------------------

if ! have ollama; then
  fail_row "Ollama CLI" "not installed"
elif ! curl -fsS --max-time 3 http://localhost:11434/ >/dev/null 2>&1; then
  fail_row "Ollama API :11434" "not responding"
else
  VER="$(ollama --version 2>&1 | head -1 | awk '{print $NF}')"
  ok_row "Ollama API :11434" "v$VER"

  # Where models live
  MODELS_DIR_EFF="$(launchctl getenv OLLAMA_MODELS 2>/dev/null)"
  [[ -z "$MODELS_DIR_EFF" ]] && MODELS_DIR_EFF="$HOME/.ollama/models (default)"
  MODELS_DISK_USAGE=""
  if [[ -d "${MODELS_DIR_EFF%% *}" ]]; then
    MODELS_DISK_USAGE=" ($(du -sh "${MODELS_DIR_EFF%% *}" 2>/dev/null | awk '{print $1}') used)"
  fi
  ok_row "  models dir" "$MODELS_DIR_EFF$MODELS_DISK_USAGE"

  # Models
  MODELS="$(ollama list 2>/dev/null | awk 'NR>1 {print $1}')"
  for want in gemma2:2b llama3.2:3b; do
    if echo "$MODELS" | grep -qx "$want"; then
      ok_row "  model $want" ""
    else
      warn_row "  model $want" "not pulled"
    fi
  done

  # Listening on 0.0.0.0 (so containers can reach)?
  if lsof -nP -iTCP:11434 -sTCP:LISTEN 2>/dev/null | awk 'NR>1 {print $9}' | grep -qE '^\*:|^0\.0\.0\.0:|^\[::\]:'; then
    ok_row "  binding" "0.0.0.0 (containers reachable)"
  else
    warn_row "  binding" "loopback only — Open WebUI in container will fail"
  fi
fi

# ---- 2. Colima + Docker ---------------------------------------------------

if ! have colima; then
  warn_row "Colima" "not installed (Open WebUI will not work)"
elif ! colima status >/dev/null 2>&1; then
  fail_row "Colima VM" "stopped — run: colima start"
else
  ok_row "Colima VM" "running"
fi

if ! have docker; then
  warn_row "Docker CLI" "not installed"
elif ! docker info >/dev/null 2>&1; then
  fail_row "Docker daemon" "unreachable"
else
  ok_row "Docker daemon" "reachable"
fi

# ---- 3. Open WebUI --------------------------------------------------------

if have docker && docker ps -a --format '{{.Names}}' 2>/dev/null | grep -qx open-webui; then
  STATUS="$(docker inspect -f '{{.State.Status}}' open-webui 2>/dev/null)"
  HEALTH="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}n/a{{end}}' open-webui 2>/dev/null)"
  if [[ "$STATUS" != "running" ]]; then
    fail_row "Open WebUI container" "$STATUS"
  else
    case "$HEALTH" in
      healthy)  ok_row "Open WebUI container" "healthy";;
      starting) warn_row "Open WebUI container" "still starting (first run takes 2-4 min)";;
      *)        ok_row "Open WebUI container" "$STATUS / $HEALTH";;
    esac

    # HTTP probe
    CODE="$(curl -s --max-time 5 -o /dev/null -w '%{http_code}' http://localhost:3000/ 2>/dev/null || echo 000)"
    if [[ "$CODE" == "200" ]]; then
      ok_row "Open WebUI HTTP :3000" "200 OK"
    else
      warn_row "Open WebUI HTTP :3000" "HTTP $CODE"
    fi

    # Container -> Ollama reachability
    if docker exec open-webui sh -c 'curl -fsS --max-time 3 http://host.docker.internal:11434/api/tags' >/dev/null 2>&1; then
      ok_row "container -> Ollama" "reachable"
    else
      warn_row "container -> Ollama" "unreachable (check OLLAMA_HOST=0.0.0.0:11434)"
    fi
  fi
else
  warn_row "Open WebUI" "container not present"
fi

# ---- 4. OpenClaw ----------------------------------------------------------

if ! have openclaw; then
  warn_row "OpenClaw CLI" "not on PATH (try: source ~/.zshrc)"
else
  OC_VER="$(openclaw --version 2>&1 | head -1 | sed 's/.*OpenClaw //')"
  ok_row "OpenClaw CLI" "$OC_VER"

  # LaunchAgent loaded?
  if launchctl print "gui/$(id -u)/ai.openclaw.gateway" >/dev/null 2>&1; then
    ok_row "  LaunchAgent" "loaded"
  else
    warn_row "  LaunchAgent" "not loaded"
  fi

  # Gateway port
  if lsof -nP -iTCP:18789 -sTCP:LISTEN >/dev/null 2>&1; then
    ok_row "  gateway :18789" "listening"

    # Status RPC
    if openclaw status >/dev/null 2>&1; then
      ok_row "  gateway RPC" "responsive"
    else
      warn_row "  gateway RPC" "not responding (try: openclaw devices list)"
    fi
  else
    fail_row "  gateway :18789" "not listening — see ~/.openclaw/logs/gateway.err.log"
  fi
fi

# ---- 5. Optional: real inference round-trip -------------------------------

if (( FLAG_INFER == 1 )); then
  printf "\n${BOLD}Inference round-trip test${RST}\n"
  if have ollama && curl -fsS --max-time 3 http://localhost:11434/ >/dev/null 2>&1; then
    note=" (gemma2:2b, ~5-15s on M1)"
    printf "  testing Ollama directly%s ... " "$note"
    START=$(date +%s)
    REPLY="$(curl -fsS --max-time 60 -X POST http://localhost:11434/api/generate \
      -H 'Content-Type: application/json' \
      -d '{"model":"gemma2:2b","prompt":"Reply with one word: OK","stream":false}' \
      2>/dev/null | python3 -c 'import sys,json; print(json.load(sys.stdin).get("response","").strip()[:40])' 2>/dev/null || echo "")"
    DUR=$(( $(date +%s) - START ))
    if [[ -n "$REPLY" ]]; then
      printf "${GREEN}OK${RST} (%ds) — '%s'\n" "$DUR" "$REPLY"
    else
      printf "${RED}FAIL${RST}\n"
      CRITICAL_FAILS=$((CRITICAL_FAILS+1))
    fi
  else
    printf "  (skipped — Ollama not reachable)\n"
  fi
fi

# ---- summary --------------------------------------------------------------

printf "\n"
if (( CRITICAL_FAILS == 0 )); then
  printf "${GREEN}${BOLD}All critical components OK.${RST}\n\n"
  exit 0
else
  printf "${RED}${BOLD}${CRITICAL_FAILS} critical failure(s).${RST}\n\n"
  exit 1
fi
