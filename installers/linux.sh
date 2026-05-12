#!/usr/bin/env bash
# installers/linux.sh — Install the You-Sir Juan private AI stack on Linux
# (tested: Ubuntu 22.04, 24.04 — Debian 12).
#
# Mirrors installers/macos.sh but uses:
#   • apt (not brew)
#   • systemd services (not launchd)
#   • native Docker (not Colima)
#   • Ollama via official curl install script (native binary)
#   • OpenClaw via npm with a user-owned global prefix
#
# Run via the universal entrypoint:
#   bash bootstrap.sh
# or directly:
#   bash installers/linux.sh
#
# Idempotent — safe to re-run.

set -euo pipefail
trap 'printf "\n\033[0;31m✗ linux.sh failed at line %s\033[0m\n" "$LINENO" >&2' ERR

# ---- config ----------------------------------------------------------------

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NPM_PREFIX="$HOME/.npm-global"
OPENCLAW_HOME="$HOME/.openclaw"
LAUNCH_AGENT=""  # systemd unit, not LaunchAgent — set below
GATEWAY_PORT=18789
WEBUI_PORT=3000
MIN_FREE_GB=15
LOG_FILE="$HOME/yousirjuan-install.log"

# ---- log everything (tee to file) -----------------------------------------

exec > >(tee -a "$LOG_FILE") 2>&1
printf "\n=== linux.sh started at %s ===\n" "$(date '+%F %T')"

# ---- helpers ---------------------------------------------------------------

step()  { printf "\n\033[1;34m==>\033[0m \033[1m%s\033[0m\n" "$*"; }
note()  { printf "    \033[2m%s\033[0m\n" "$*"; }
ok()    { printf "    \033[0;32m✓\033[0m %s\n" "$*"; }
warn()  { printf "    \033[0;33m!\033[0m %s\n" "$*"; }
die()   { printf "\n\033[0;31m✗ %s\033[0m\n" "$*"; exit 1; }
have()  { command -v "$1" >/dev/null 2>&1; }

require_sudo() {
  if ! sudo -n true 2>/dev/null; then
    note "sudo will prompt for your password (one-time)"
    sudo -v || die "sudo not available — install requires admin"
  fi
}

# ---- 1. preflight ----------------------------------------------------------

step "Preflight"

[[ "$(uname -s)" == "Linux" ]] || die "Linux only — use installers/macos.sh on a Mac."

if [[ -r /etc/os-release ]]; then
  . /etc/os-release
  note "Distro: $PRETTY_NAME ($ID)"
fi
note "Kernel:  $(uname -srm)"

case "${ID:-}" in
  ubuntu|debian|raspbian) PKG_MGR="apt" ;;
  *) warn "Distro $ID not officially tested. Continuing best-effort with apt."
     PKG_MGR="apt" ;;
esac

FREE_GB="$(df -kP "$HOME" | tail -1 | awk '{print int($4/1024/1024)}')"
RAM_GB="$(awk '/MemTotal/ {print int($2/1024/1024)}' /proc/meminfo)"
HAS_NVIDIA=$(have nvidia-smi && echo 1 || echo 0)
note "Disk: ${FREE_GB} GB free. RAM: ${RAM_GB} GB. NVIDIA GPU: $([[ $HAS_NVIDIA -eq 1 ]] && echo yes || echo no)"
(( FREE_GB >= MIN_FREE_GB )) || die "Need at least ${MIN_FREE_GB} GB free."

require_sudo

# Hardware-aware default profile
DEFAULT_PROFILE=1
WARN_OPENCLAW=""
if (( HAS_NVIDIA == 1 && RAM_GB >= 16 )); then
  DEFAULT_PROFILE=2
elif (( RAM_GB < 8 )); then
  WARN_OPENCLAW="${RAM_GB} GB RAM — too tight for OpenClaw + LLM. Recommend chat-only."
elif (( RAM_GB < 16 )); then
  WARN_OPENCLAW="${RAM_GB} GB RAM (no GPU) — OpenClaw inference will be slow. Recommend chat-only."
fi

step "Install profile"
[[ -n "$WARN_OPENCLAW" ]] && warn "$WARN_OPENCLAW"
echo
cat <<'PROFILES'
    What do you want to install?

      1) Chat only       Ollama + Open WebUI (browser chat)
                         → works on any machine; CPU-only is fine
      2) Full stack      above + OpenClaw agent (Jarvis-style)
                         → needs GPU (NVIDIA / Apple Silicon) for stability
      3) Public-facing   above + nginx + Let's Encrypt cert + iptables lockdown
                         → for VPS with public IP + DNS A record (see vps/apply-vps-config.sh)
      4) Custom          pick each component (advanced)

PROFILES

read -r -p "    Choice [1/2/3/4] (default $DEFAULT_PROFILE): " PROFILE
PROFILE="${PROFILE:-$DEFAULT_PROFILE}"

OPENCLAW_MODE=""
case "$PROFILE" in
  1) INSTALL_OLLAMA=1; INSTALL_WEBUI=1; INSTALL_OPENCLAW=0; INSTALL_PUBLIC=0 ;;
  2)
    if (( HAS_NVIDIA == 0 )); then
      warn "Full stack on CPU-only — OpenClaw inference will likely time out (multi-minute per turn)."
      read -r -p "    Continue anyway? [y/N] " yn
      [[ "$yn" =~ ^[Yy]$ ]] || die "Aborted — re-run and pick option 1."
    fi
    INSTALL_OLLAMA=1; INSTALL_WEBUI=1; INSTALL_OPENCLAW=1; INSTALL_PUBLIC=0
    ;;
  3) INSTALL_OLLAMA=1; INSTALL_WEBUI=1; INSTALL_OPENCLAW=1; INSTALL_PUBLIC=1
     # On a public VPS, default OpenClaw to Docker-router mode (safer, headless)
     OPENCLAW_MODE="docker"
     note "Public-facing: OpenClaw will install in Docker-router mode (headless, sandboxed)."
     note "Also run \`sudo DOMAIN=... EMAIL=... bash vps/apply-vps-config.sh\` after this finishes."
     ;;
  4)
    read -r -p "    Install Ollama (LLM runtime)? [Y/n] " a; [[ "$a" =~ ^[Nn] ]] && INSTALL_OLLAMA=0 || INSTALL_OLLAMA=1
    read -r -p "    Install Open WebUI (browser chat UI)? [Y/n] " a; [[ "$a" =~ ^[Nn] ]] && INSTALL_WEBUI=0 || INSTALL_WEBUI=1
    read -r -p "    Install OpenClaw (agent)? [y/N] " a; [[ "$a" =~ ^[Yy] ]] && INSTALL_OPENCLAW=1 || INSTALL_OPENCLAW=0
    INSTALL_PUBLIC=0
    ;;
  *) die "Invalid choice." ;;
esac

# OpenClaw mode picker for profiles 2 + 4 (profile 3 already set above)
if (( INSTALL_OPENCLAW == 1 )) && [[ -z "$OPENCLAW_MODE" ]]; then
  echo
  cat <<'OCMODE'
    OpenClaw deployment mode:

      a) Native    Full feature set: browser control, voice, screenshots,
                   file ops. Less isolation.
                   → Best for personal workstations
      b) Docker    Headless / messaging-router only. Strong isolation
                   (cap-drop, no host filesystem, broker pattern for any
                   host action). No browser/voice from inside.
                   → Best for VPS or always-on server
      c) Skip      Don't install OpenClaw on this machine

OCMODE
  read -r -p "    OpenClaw mode [a/b/c] (default a): " OC_PICK
  case "${OC_PICK:-a}" in
    a|A) OPENCLAW_MODE="native" ;;
    b|B) OPENCLAW_MODE="docker"; warn "Docker mode requires the broker setup (see broker/README.md)" ;;
    c|C) OPENCLAW_MODE=""; INSTALL_OPENCLAW=0; ok "Skipping OpenClaw" ;;
    *)   OPENCLAW_MODE="native" ;;
  esac
fi

# Vendor community integrations picker (Full stack + Public + Custom)
INSTALL_CLAUDE_MEM=0
INSTALL_MARKETING_SKILLS=0
INSTALL_RUFLO=0
INSTALL_AI_SKILLS_LIBRARY=0
if [[ "$PROFILE" == "2" || "$PROFILE" == "3" || "$PROFILE" == "4" ]]; then
  echo
  step "Community integrations (vendor/, optional)"
  ask_yn "Install ai-skills-library? (operator's curated catalog: marketing/ide/project/visual skills + Claude/Cursor rules)" "y" \
    && INSTALL_AI_SKILLS_LIBRARY=1 || INSTALL_AI_SKILLS_LIBRARY=0
  ask_yn "Install claude-mem? (persistent memory for Claude Code; ~196 MB)" "n" \
    && INSTALL_CLAUDE_MEM=1 || INSTALL_CLAUDE_MEM=0
  ask_yn "Install marketing-skills? (pre-built marketing-domain skills, symlinked to ~/.claude/skills/; ~4 MB)" "n" \
    && INSTALL_MARKETING_SKILLS=1 || INSTALL_MARKETING_SKILLS=0
  ask_yn "Install ruflo? (multi-agent orchestration via MCP; ~579 MB; alternative/complement to OpenClaw)" "n" \
    && INSTALL_RUFLO=1 || INSTALL_RUFLO=0
fi

ok "Will install: ollama=$INSTALL_OLLAMA, open-webui=$INSTALL_WEBUI, openclaw=$INSTALL_OPENCLAW${OPENCLAW_MODE:+ ($OPENCLAW_MODE)}, ai-skills-library=$INSTALL_AI_SKILLS_LIBRARY, claude-mem=$INSTALL_CLAUDE_MEM, marketing-skills=$INSTALL_MARKETING_SKILLS, ruflo=$INSTALL_RUFLO"

# ---- 2. base packages ------------------------------------------------------

step "Base packages (curl, ca-certificates, gnupg, python3, build deps)"
sudo apt-get update -qq
sudo DEBIAN_FRONTEND=noninteractive apt-get install -qq -y \
  curl ca-certificates gnupg lsb-release apt-transport-https \
  python3 python3-pip build-essential pkg-config \
  unzip tar xz-utils \
  netfilter-persistent iptables-persistent \
  jq dnsutils
ok "base deps installed"

# ---- 3. Node.js + npm prefix ----------------------------------------------

step "Node.js (need 22+)"
NEED_NODE_INSTALL=0
if have node; then
  NODE_MAJOR="$(node -v | sed 's/^v//; s/\..*//')"
  (( NODE_MAJOR >= 22 )) || NEED_NODE_INSTALL=1
else
  NEED_NODE_INSTALL=1
fi

if (( NEED_NODE_INSTALL == 1 )); then
  note "Installing Node.js via NodeSource (latest LTS)"
  curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -qq -y nodejs
fi
ok "node $(node -v), npm $(npm -v)"

mkdir -p "$NPM_PREFIX/bin"
npm config set prefix "$NPM_PREFIX"
case ":$PATH:" in
  *":$NPM_PREFIX/bin:"*) ;;
  *) export PATH="$NPM_PREFIX/bin:$PATH" ;;
esac
SHELL_RC="$HOME/.bashrc"
[[ "$SHELL" == */zsh ]] && SHELL_RC="$HOME/.zshrc"
if ! grep -q "npm-global/bin" "$SHELL_RC" 2>/dev/null; then
  printf '\nexport PATH="$HOME/.npm-global/bin:$PATH"\n' >> "$SHELL_RC"
  ok "Added \$HOME/.npm-global/bin to $SHELL_RC"
fi

# ---- 4. Ollama -------------------------------------------------------------

if (( INSTALL_OLLAMA == 0 )); then
  note "Skipping Ollama (not in profile)"
else

step "Ollama"
if ! have ollama; then
  note "Installing Ollama via official installer (creates systemd unit)"
  curl -fsSL https://ollama.com/install.sh | sh
fi
ok "ollama $(ollama --version 2>&1 | head -1 | awk '{print $NF}')"

# Ask where to store models (or honor MODELS_DIR env)
DEFAULT_MODELS_DIR="$HOME/.ollama/models"
if [[ -z "${MODELS_DIR:-}" ]]; then
  read -r -p "    Ollama models directory [$DEFAULT_MODELS_DIR]: " MODELS_DIR
fi
MODELS_DIR="${MODELS_DIR:-$DEFAULT_MODELS_DIR}"
[[ "$MODELS_DIR" = /* ]] || die "Path must be absolute. Got: $MODELS_DIR"
mkdir -p "$MODELS_DIR"

# Bind Ollama to 0.0.0.0 + custom MODELS_DIR via systemd override
sudo mkdir -p /etc/systemd/system/ollama.service.d
sudo tee /etc/systemd/system/ollama.service.d/override.conf >/dev/null <<EOF
[Service]
Environment="OLLAMA_HOST=0.0.0.0:11434"
Environment="OLLAMA_MODELS=$MODELS_DIR"
EOF
sudo systemctl daemon-reload
sudo systemctl restart ollama
sleep 3
ss -tlnp 2>/dev/null | grep ':11434 ' | head -1 || warn "Ollama not listening yet — check: journalctl -u ollama"
ok "Ollama bound to 0.0.0.0:11434, models at $MODELS_DIR"

fi  # end INSTALL_OLLAMA

# ---- 5. Pull models with RAM-aware picker ---------------------------------

if (( INSTALL_OLLAMA == 0 )); then
  note "Skipping models (no Ollama)"
else

step "Model selection wizard"
RAM_GB="$(awk '/MemTotal/ {print int($2/1024/1024)}' /proc/meminfo)"
note "Detected RAM: ${RAM_GB} GB"
echo
cat <<'PRESETS'
    Pick a preset, or "custom" to choose one-by-one:

      1) Minimal       gemma2:2b only (~1.6 GB) — fastest, low-RAM friendly
      2) Recommended   Minimal + llama3.2:3b + llama3:8b + qwen3:8b (~13 GB; needs 16 GB RAM)
      3) Pro           Recommended + gpt-oss:20b (~26 GB; needs 32 GB RAM, flagship-class)
      4) Family Office Recommended + gpt-oss:20b + qwen3:14b (~35 GB; needs 32 GB RAM)
      5) Custom        I'll prompt y/n for each model
      6) Skip          don't pull anything now (you can `ollama pull <name>` later)

PRESETS

read -r -p "    Choice [1/2/3/4/5/6]: " PRESET
PRESET="${PRESET:-2}"

ask_yn() {
  local q="$1" def="$2" reply
  local hint="[Y/n]"; [[ "$def" == "n" ]] && hint="[y/N]"
  read -r -p "    $q $hint " reply
  reply="${reply:-$def}"
  [[ "$reply" =~ ^[Yy] ]]
}

case "$PRESET" in
  1) MODELS_TO_PULL=("gemma2:2b") ;;
  2) MODELS_TO_PULL=("gemma2:2b" "llama3.2:3b" "llama3:8b" "qwen3:8b") ;;
  3) MODELS_TO_PULL=("gemma2:2b" "llama3.2:3b" "llama3:8b" "qwen3:8b" "gpt-oss:20b" "gemma4:26b") ;;
  4) MODELS_TO_PULL=("gemma2:2b" "llama3.2:3b" "llama3:8b" "qwen3:8b" "gpt-oss:20b" "gemma4:26b" "qwen3:14b") ;;
  5)
    MODELS_TO_PULL=("gemma2:2b")
    ask_yn "llama3.2:3b (~2 GB) — fast, fits anywhere?" "y" && MODELS_TO_PULL+=("llama3.2:3b")
    ask_yn "llama3:8b (~4.7 GB) — Meta's general-purpose, needs 16+ GB RAM?" "y" && MODELS_TO_PULL+=("llama3:8b")
    ask_yn "qwen3:8b (~5 GB) — Alibaba's latest, strong code+reasoning?" "y" && MODELS_TO_PULL+=("qwen3:8b")
    ask_yn "gpt-oss:20b (~13 GB) — OpenAI's open-weights, needs 32 GB RAM?" "n" && MODELS_TO_PULL+=("gpt-oss:20b")
    ask_yn "gemma4:26b (~16 GB) — Google's latest flagship-class, needs 32 GB RAM?" "n" && MODELS_TO_PULL+=("gemma4:26b")
    ask_yn "qwen3:14b (~9 GB) — needs 32 GB RAM?" "n" && MODELS_TO_PULL+=("qwen3:14b")
    ask_yn "gemma4:31b (~19 GB) — needs 40 GB RAM?" "n" && MODELS_TO_PULL+=("gemma4:31b")
    ask_yn "gpt-oss:120b (~65 GB) — top-tier, needs 96+ GB RAM?" "n" && MODELS_TO_PULL+=("gpt-oss:120b")
    ask_yn "llama3.1:70b (~40 GB) — top-tier, needs 64+ GB RAM?" "n" && MODELS_TO_PULL+=("llama3.1:70b")
    ;;
  6) MODELS_TO_PULL=() ;;
  *) MODELS_TO_PULL=("gemma2:2b" "llama3.2:3b") ;;
esac

if ask_yn "Add custom models by name (e.g. mistral, phi3, codellama, deepseek-coder)?" "n"; then
  read -r -p "    Comma-separated model IDs: " EXTRA
  IFS=',' read -ra EXTRA_LIST <<< "$EXTRA"
  for m in "${EXTRA_LIST[@]}"; do
    m="${m// /}"; [[ -n "$m" ]] && MODELS_TO_PULL+=("$m")
  done
fi

if (( ${#MODELS_TO_PULL[@]} == 0 )); then
  warn "No models selected. You can pull later with: ollama pull <name>"
fi

step "Pulling models: ${MODELS_TO_PULL[*]}"
have_model() { ollama list 2>/dev/null | awk 'NR>1 {print $1}' | grep -qx "$1"; }
for m in "${MODELS_TO_PULL[@]}"; do
  if have_model "$m"; then
    ok "$m present"
  else
    note "pulling $m"
    ollama pull "$m" || warn "$m pull failed (re-run install to retry)"
  fi
done

fi  # end INSTALL_OLLAMA models

# ---- 6. Docker -------------------------------------------------------------

if (( INSTALL_WEBUI == 0 )); then
  note "Skipping Docker (Open WebUI not in profile)"
else

step "Docker (Engine + Compose plugin)"
if ! have docker; then
  note "Installing Docker via official apt repo"
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  sudo apt-get update -qq
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -qq -y \
    docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo systemctl enable --now docker
fi
# Add current user to docker group so docker commands don't need sudo
if ! id -nG "$USER" | grep -qw docker; then
  sudo usermod -aG docker "$USER"
  warn "Added $USER to docker group — log out/in or run: newgrp docker"
fi
ok "$(docker --version)"

# ---- 7. Open WebUI ---------------------------------------------------------
# (still inside INSTALL_WEBUI block from section 6)

step "Open WebUI on :$WEBUI_PORT (hardened container)"
if docker ps -a --format '{{.Names}}' | grep -qx open-webui; then
  docker start open-webui >/dev/null 2>&1 || true
  ok "open-webui container exists, ensured running"
else
  note "Pulling Open WebUI image"
  docker run -d --name open-webui -p $WEBUI_PORT:8080 \
    --add-host=host.docker.internal:host-gateway \
    --cap-drop=ALL \
    --cap-add=CHOWN --cap-add=DAC_OVERRIDE --cap-add=SETUID --cap-add=SETGID \
    --security-opt=no-new-privileges:true \
    --memory=4g --memory-swap=4g \
    --pids-limit=512 \
    --tmpfs /tmp:rw,nosuid,nodev,noexec,size=512m \
    -v open-webui:/app/backend/data \
    -e USE_OLLAMA_DOCKER=false \
    -e OLLAMA_BASE_URL=http://host.docker.internal:11434 \
    --restart always \
    ghcr.io/open-webui/open-webui:main
  ok "Container hardening: cap-drop=ALL (4 readded), no-new-privileges, mem 4G, pids 512, tmpfs /tmp"
fi
note "Waiting for Open WebUI HTTP 200 (first run = DB migrations + HF models, 2-4 min)"
code=000
for i in {1..240}; do
  code="$(curl -s -o /dev/null -w '%{http_code}' http://localhost:$WEBUI_PORT/)"
  [[ "$code" == "200" ]] && break
  sleep 2
done
[[ "$code" == "200" ]] && ok "Open WebUI ready on :$WEBUI_PORT" \
  || warn "Open WebUI not yet ready — docker logs open-webui"

fi  # end INSTALL_WEBUI

# ---- 8. OpenClaw -----------------------------------------------------------

if (( INSTALL_OPENCLAW == 0 )); then
  note "Skipping OpenClaw (not in profile)"
else

step "OpenClaw (personal AI agent)"
if ! have openclaw; then
  note "npm installing openclaw@latest"
  npm install -g openclaw@latest
fi
ok "openclaw $(openclaw --version 2>&1 | head -1 | sed 's/.*OpenClaw //')"

# typebox sanity check (works around upstream packaging bug)
patch_typebox() {
  local oc_root="$NPM_PREFIX/lib/node_modules/openclaw"
  [[ -d "$oc_root" ]] || return
  local need=0
  for tb in "$oc_root/node_modules/typebox/build/index.mjs" \
            "$oc_root/dist/extensions/google/node_modules/typebox/build/index.mjs"; do
    [[ -f "$tb" ]] || { need=1; break; }
  done
  (( need == 0 )) && { ok "typebox build complete"; return; }
  warn "typebox incomplete — patching from npm"
  local tmp; tmp=$(mktemp -d)
  ( cd "$tmp" && npm init -y >/dev/null 2>&1 \
              && npm install --silent --no-save typebox@1.1.33 ) || { rm -rf "$tmp"; return; }
  for dest in "$oc_root/node_modules/typebox/build" \
              "$oc_root/dist/extensions/google/node_modules/typebox/build"; do
    mkdir -p "$dest"
    cp -R "$tmp/node_modules/typebox/build/." "$dest/"
  done
  rm -rf "$tmp"
  ok "typebox patched"
}
patch_typebox

# ---- 9. OpenClaw config + systemd unit -----------------------------------

step "OpenClaw config + systemd unit"
mkdir -p "$OPENCLAW_HOME"/{logs,workspace,agents/main/sessions,flows,identity}
chmod 700 "$OPENCLAW_HOME"

TPL="$REPO_DIR/config/openclaw.json.template"
if [[ -f "$TPL" ]]; then
  [[ -f "$OPENCLAW_HOME/openclaw.json" ]] && \
    cp "$OPENCLAW_HOME/openclaw.json" "$OPENCLAW_HOME/openclaw.json.bak.$(date +%s)"
  TOKEN="$(openssl rand -hex 24)"
  sed -e "s|__HOME__|$HOME|g" -e "s|__GENERATE__|$TOKEN|g" "$TPL" \
    > "$OPENCLAW_HOME/openclaw.json"
  chmod 600 "$OPENCLAW_HOME/openclaw.json"
  ok "openclaw.json written"
fi

NODE_BIN="$(which node)"
SVC=/etc/systemd/system/openclaw-gateway.service
sudo tee "$SVC" >/dev/null <<EOF
[Unit]
Description=OpenClaw Gateway
After=network-online.target ollama.service
Wants=network-online.target

[Service]
Type=simple
User=$USER
Group=$USER
Environment=HOME=$HOME
Environment=PATH=$NPM_PREFIX/bin:/usr/local/bin:/usr/bin:/bin
WorkingDirectory=$HOME
ExecStart=$NODE_BIN $NPM_PREFIX/lib/node_modules/openclaw/dist/index.js gateway --port $GATEWAY_PORT
Restart=on-failure
RestartSec=5
StandardOutput=append:$OPENCLAW_HOME/logs/gateway.log
StandardError=append:$OPENCLAW_HOME/logs/gateway.err.log

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable --now openclaw-gateway.service
ok "systemd unit installed: $SVC"

# Wait for gateway
note "Waiting for gateway on :$GATEWAY_PORT"
gateway_up=0
for i in {1..60}; do
  if ss -tlnp 2>/dev/null | grep -q ":$GATEWAY_PORT "; then gateway_up=1; break; fi
  sleep 1
done
(( gateway_up == 1 )) && ok "gateway listening" || warn "gateway didn't start — see $OPENCLAW_HOME/logs/gateway.err.log"

fi  # end INSTALL_OPENCLAW

# ---- 10. End-to-end test --------------------------------------------------

if (( INSTALL_OPENCLAW == 0 )); then
  note "Skipping end-to-end agent test (no OpenClaw)"
else

step "End-to-end test (sending a real prompt to llama3.2:3b via OpenClaw)"
TEST_OUT="$(mktemp)"
( openclaw infer model run --model "ollama/llama3.2:3b" --prompt "Say 'OK' and nothing else." \
    > "$TEST_OUT" 2>&1 ) &
PID=$!
elapsed=0
while kill -0 $PID 2>/dev/null; do
  (( elapsed >= 120 )) && { kill -9 $PID 2>/dev/null; break; }
  sleep 2; elapsed=$((elapsed + 2))
done
wait $PID 2>/dev/null || true
if grep -qiE "OK|hello|hi" "$TEST_OUT"; then
  ANSWER="$(grep -iE 'OK|hello|hi' "$TEST_OUT" | head -1 | tr -d '\r' | cut -c1-80)"
  ok "Agent responded in ${elapsed}s: \"$ANSWER\""
else
  warn "End-to-end test failed/timed out after ${elapsed}s. Tail:"
  tail -5 "$TEST_OUT" | sed 's/^/      /'
fi
rm -f "$TEST_OUT"

fi  # end INSTALL_OPENCLAW e2e test

# ---- 10b. Vendor community integrations -----------------------------------

if (( INSTALL_CLAUDE_MEM == 1 || INSTALL_MARKETING_SKILLS == 1 || INSTALL_RUFLO == 1 || INSTALL_AI_SKILLS_LIBRARY == 1 )); then
  step "Vendor community integrations"
  if [[ -f "$REPO_DIR/vendor/install-integrations.sh" ]]; then
    # shellcheck disable=SC1091
    source "$REPO_DIR/vendor/install-integrations.sh"
    install_all_selected_integrations
  else
    warn "vendor/install-integrations.sh not found — skipping"
  fi
fi

# ---- 11. Summary ----------------------------------------------------------

cat <<EOF

────────────────────────────────────────────────────────────────────
  DONE.
────────────────────────────────────────────────────────────────────

  Open WebUI:             http://localhost:$WEBUI_PORT
                          (sign up — first user becomes admin, all local)

  OpenClaw gateway:       systemctl status openclaw-gateway
  OpenClaw chat:          openclaw chat
  OpenClaw status:        openclaw status

  Ollama models:          $(ollama list 2>/dev/null | awk 'NR>1 {print $1}' | tr '\n' ' ')
  Models directory:       $MODELS_DIR

  Logs:
    Install log           $LOG_FILE
    OpenClaw gateway      $OPENCLAW_HOME/logs/gateway.log
    Ollama                journalctl -u ollama

  Restart OpenClaw gateway:  sudo systemctl restart openclaw-gateway
  Restart Ollama:            sudo systemctl restart ollama

EOF

printf "\n=== linux.sh finished at %s ===\n" "$(date '+%F %T')"
