#!/usr/bin/env bash
# install.sh — One-shot installer for a private AI stack on macOS
#
#   • Ollama + 2 small models (gemma2:2b, llama3.2:3b)
#   • Open WebUI in Docker (via Colima) on :3000
#   • OpenClaw personal AI agent on :18789, auto-starting via LaunchAgent
#
# Tested on macOS 13+ (Apple Silicon strongly recommended; Intel runs but
# the OpenClaw agent layer is too slow to be useful on CPU-only inference).
#
# Run:
#   bash install.sh
#
# Idempotent — safe to re-run; each step checks for existing state.

set -euo pipefail
trap 'printf "\n\033[0;31m✗ install.sh failed at line %s\033[0m\n" "$LINENO" >&2' ERR

# ---- config ----------------------------------------------------------------

BUNDLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NPM_PREFIX="$HOME/.npm-global"
OPENCLAW_HOME="$HOME/.openclaw"
LAUNCH_AGENT="$HOME/Library/LaunchAgents/ai.openclaw.gateway.plist"
GATEWAY_PORT=18789
WEBUI_PORT=3000
MIN_FREE_GB=15
LOG_FILE="$HOME/private-ai-install.log"

# ---- log everything (tee to file) -----------------------------------------
# Mirror all output to a log file so failures are debuggable after the
# Terminal window closes. Uses process substitution so colors still show
# in the terminal AND go to the log.
exec > >(tee -a "$LOG_FILE") 2>&1
printf "\n=== install.sh started at %s ===\n" "$(date '+%F %T')"

# ---- helpers ---------------------------------------------------------------

step()  { printf "\n\033[1;34m==>\033[0m \033[1m%s\033[0m\n" "$*"; }
note()  { printf "    \033[2m%s\033[0m\n" "$*"; }
ok()    { printf "    \033[0;32m✓\033[0m %s\n" "$*"; }
warn()  { printf "    \033[0;33m!\033[0m %s\n" "$*"; }
die()   { printf "\n\033[0;31m✗ %s\033[0m\n" "$*"; exit 1; }
have()  { command -v "$1" >/dev/null 2>&1; }

# ---- 1. preflight + install profile picker --------------------------------

step "Preflight"

[[ "$(uname)" == "Darwin" ]] || die "macOS only."

ARCH="$(uname -m)"
RAM_GB="$(sysctl -n hw.memsize | awk '{print int($1/1024/1024/1024)}')"
note "macOS $(sw_vers -productVersion) on $ARCH, ${RAM_GB} GB RAM"

# Hardware-aware default profile
DEFAULT_PROFILE=1
WARN_OPENCLAW=""
if [[ "$ARCH" == "arm64" && $RAM_GB -ge 16 ]]; then
  DEFAULT_PROFILE=2
elif [[ "$ARCH" != "arm64" ]]; then
  WARN_OPENCLAW="Intel Mac (no Metal GPU) — OpenClaw agent will be unstable on this hardware. Recommend chat-only."
elif (( RAM_GB < 16 )); then
  WARN_OPENCLAW="${RAM_GB} GB RAM — tight for OpenClaw + 8B models. Recommend chat-only on this hardware."
fi

step "Install profile"
[[ -n "$WARN_OPENCLAW" ]] && warn "$WARN_OPENCLAW"
echo
cat <<'PROFILES'
    What do you want to install?

      1) Chat only    Ollama + Open WebUI (browser chat)
                      → works on any Mac, fast even on CPU
      2) Full stack   above + OpenClaw agent (Jarvis-style)
                      → needs Apple Silicon (Metal GPU) for stability
      3) Custom       pick each component (advanced)

PROFILES

read -r -p "    Choice [1/2/3] (default $DEFAULT_PROFILE): " PROFILE
PROFILE="${PROFILE:-$DEFAULT_PROFILE}"

case "$PROFILE" in
  1) INSTALL_OLLAMA=1; INSTALL_WEBUI=1; INSTALL_OPENCLAW=0; OPENCLAW_MODE="" ;;
  2)
    if [[ "$ARCH" != "arm64" ]]; then
      warn "You picked Full stack on Intel — OpenClaw inference will likely time out."
      read -r -p "    Continue anyway? [y/N] " yn
      [[ "$yn" =~ ^[Yy]$ ]] || die "Aborted — re-run and pick option 1."
    fi
    INSTALL_OLLAMA=1; INSTALL_WEBUI=1; INSTALL_OPENCLAW=1
    # OpenClaw mode picker — security tradeoff
    echo
    cat <<'OCMODE'
    OpenClaw deployment mode:

      a) Native    Full feature set: browser control, voice, screenshots,
                   file ops. Less isolation (process runs as your user).
                   → Best for personal devices (Mac mini, M1, etc.)
      b) Docker    Headless / messaging-router only. Strong isolation
                   (cap-drop, no host filesystem, broker pattern for any
                   host action). No browser/voice/screenshot from inside
                   the container — only via the broker (jail-with-door).
                   → Best for VPS or always-on server use
      c) Skip      Don't install OpenClaw on this machine

OCMODE
    read -r -p "    OpenClaw mode [a/b/c] (default a): " OC_PICK
    case "${OC_PICK:-a}" in
      a|A) OPENCLAW_MODE="native" ;;
      b|B) OPENCLAW_MODE="docker"; warn "Docker mode requires the broker setup (see broker/README.md after install)" ;;
      c|C) OPENCLAW_MODE=""; INSTALL_OPENCLAW=0; ok "Skipping OpenClaw" ;;
      *)   OPENCLAW_MODE="native" ;;
    esac
    [[ -n "$OPENCLAW_MODE" ]] && ok "OpenClaw mode: $OPENCLAW_MODE"
    ;;
  3)
    read -r -p "    Install Ollama (LLM runtime)? [Y/n] " a; [[ "$a" =~ ^[Nn] ]] && INSTALL_OLLAMA=0 || INSTALL_OLLAMA=1
    read -r -p "    Install Open WebUI (browser chat UI)? [Y/n] " a; [[ "$a" =~ ^[Nn] ]] && INSTALL_WEBUI=0 || INSTALL_WEBUI=1
    read -r -p "    Install OpenClaw (agent)? [y/N] " a; [[ "$a" =~ ^[Yy] ]] && INSTALL_OPENCLAW=1 || INSTALL_OPENCLAW=0
    ;;
  *) die "Invalid choice." ;;
esac
ok "Will install: ollama=$INSTALL_OLLAMA, open-webui=$INSTALL_WEBUI, openclaw=$INSTALL_OPENCLAW"

if ! xcode-select -p >/dev/null 2>&1; then
  step "Installing Xcode Command Line Tools"
  note "A GUI prompt will appear. After it finishes, re-run this script."
  xcode-select --install || true
  exit 0
fi
ok "Xcode CLI tools present"

warn "macOS may prompt 'Allow incoming connections?' for ollama / Docker."
warn "Click Allow when it appears, otherwise containers can't reach Ollama."

# ---- Models directory (where Ollama will store the model files) -----------

step "Where to store Ollama model files"

DEFAULT_MODELS_DIR="$HOME/.ollama/models"
note "The two models we'll pull (gemma2:2b + llama3.2:3b) total ~3.6 GB."
note "Larger models you add later (7B, 13B) can be 4–20 GB each."
note "Pick somewhere with room: internal SSD, external SSD, etc."
note "Override non-interactively by exporting MODELS_DIR before running."
echo

# Honor env var if already set
if [[ -z "${MODELS_DIR:-}" ]]; then
  read -r -p "    Models directory [$DEFAULT_MODELS_DIR]: " MODELS_DIR
fi
MODELS_DIR="${MODELS_DIR:-$DEFAULT_MODELS_DIR}"

# Validate
[[ "$MODELS_DIR" = /* ]] || die "Path must be absolute (start with /). Got: $MODELS_DIR"
mkdir -p "$MODELS_DIR" || die "Could not create $MODELS_DIR — check permissions."
[[ -w "$MODELS_DIR" ]] || die "$MODELS_DIR is not writable."

# Disk space check on the chosen filesystem
FREE_GB="$(df -k "$MODELS_DIR" | tail -1 | awk '{print int($4/1024/1024)}')"
note "Free space on that volume: ${FREE_GB} GB (need at least ${MIN_FREE_GB})"
(( FREE_GB >= MIN_FREE_GB )) || die "Need at least ${MIN_FREE_GB} GB free on the models volume."

ok "Models will live at: $MODELS_DIR"

# Persist OLLAMA_MODELS so it survives reboot.
# launchctl setenv applies for the current login session and is inherited by
# services started afterward (brew services, our LaunchAgents). To make it
# stick across reboots we also install a tiny "boot env" LaunchAgent that
# sets the variable at login.
launchctl setenv OLLAMA_MODELS "$MODELS_DIR"

ENV_LA="$HOME/Library/LaunchAgents/ai.private-ai.env.plist"
mkdir -p "$(dirname "$ENV_LA")"
cat > "$ENV_LA" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>ai.private-ai.env</string>
  <key>RunAtLoad</key><true/>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/launchctl</string>
    <string>setenv</string>
    <string>OLLAMA_MODELS</string>
    <string>$MODELS_DIR</string>
  </array>
</dict>
</plist>
PLIST
chmod 644 "$ENV_LA"
launchctl bootout "gui/$(id -u)" "$ENV_LA" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$ENV_LA"

# Also export in shell config so terminal sessions see it
if ! grep -q "OLLAMA_MODELS=" "$HOME/.zshrc" 2>/dev/null; then
  printf '\nexport OLLAMA_MODELS="%s"\n' "$MODELS_DIR" >> "$HOME/.zshrc"
fi
ok "OLLAMA_MODELS persisted (launchctl + ~/.zshrc + boot LaunchAgent)"

# ---- Model picker (RAM-aware) ---------------------------------------------

step "Model selection wizard"
RAM_GB="$(sysctl -n hw.memsize | awk '{print int($1/1024/1024/1024)}')"
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
    ask_yn "llama3.1:70b (~40 GB) — top-tier, needs 64+ GB RAM (M1 Max+ recommended)?" "n" && MODELS_TO_PULL+=("llama3.1:70b")
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

note "Will pull: ${MODELS_TO_PULL[*]}"

# ---- 2. Homebrew -----------------------------------------------------------

step "Homebrew"
if ! have brew; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi
ok "$(brew --version | head -1)"

# ---- 3. Node + npm prefix --------------------------------------------------

step "Node.js"
have node || brew install node
NODE_MAJOR="$(node -v | sed 's/^v//; s/\..*//')"
(( NODE_MAJOR >= 22 )) || die "Need Node 22+, got $(node -v). Try: brew upgrade node"
ok "node $(node -v), npm $(npm -v)"

mkdir -p "$NPM_PREFIX/bin"
npm config set prefix "$NPM_PREFIX"
case ":$PATH:" in
  *":$NPM_PREFIX/bin:"*) ;;
  *) export PATH="$NPM_PREFIX/bin:$PATH" ;;
esac
if ! grep -q "npm-global/bin" "$HOME/.zshrc" 2>/dev/null; then
  printf '\nexport PATH="$HOME/.npm-global/bin:$PATH"\n' >> "$HOME/.zshrc"
  ok "Added \$HOME/.npm-global/bin to ~/.zshrc"
fi

# ---- 4. Ollama -------------------------------------------------------------

if (( INSTALL_OLLAMA == 0 )); then
  note "Skipping Ollama (not in profile)"
else

step "Ollama"
if ! have ollama; then
  if [[ "$ARCH" == "arm64" ]]; then
    brew install ollama
  else
    note "Downloading official Ollama macOS app (avoids slow source build)"
    curl -L --progress-bar -o /tmp/Ollama.zip \
      https://github.com/ollama/ollama/releases/latest/download/Ollama-darwin.zip
    unzip -q -o /tmp/Ollama.zip -d /Applications/
    if [[ -w /usr/local/bin ]]; then
      ln -sf /Applications/Ollama.app/Contents/Resources/ollama /usr/local/bin/ollama
    else
      sudo ln -sf /Applications/Ollama.app/Contents/Resources/ollama /usr/local/bin/ollama
    fi
  fi
fi

# Bind Ollama to 0.0.0.0 so Docker containers can reach it via host.docker.internal
launchctl setenv OLLAMA_HOST "0.0.0.0:11434" 2>/dev/null || true

# If Ollama is already running, restart it so it picks up the new env vars
# (OLLAMA_MODELS + OLLAMA_HOST that we just set above)
if curl -fsS --max-time 2 http://localhost:11434/ >/dev/null 2>&1; then
  note "restarting Ollama to apply OLLAMA_MODELS=$MODELS_DIR"
  pkill -f "ollama serve" 2>/dev/null || true
  if [[ "$ARCH" == "arm64" ]]; then
    brew services restart ollama 2>/dev/null || true
  fi
  sleep 2
fi

# Start the service (no-op if already running)
if [[ "$ARCH" == "arm64" ]]; then
  brew services start ollama 2>/dev/null || true
fi
if ! curl -fsS http://localhost:11434/ >/dev/null 2>&1; then
  OLLAMA_HOST="0.0.0.0:11434" OLLAMA_MODELS="$MODELS_DIR" \
    nohup ollama serve >/tmp/ollama.log 2>&1 & disown
fi

note "Waiting for Ollama API"
for i in {1..30}; do
  curl -fsS http://localhost:11434/ >/dev/null 2>&1 && break
  sleep 1
done
curl -fsS http://localhost:11434/ >/dev/null 2>&1 || die "Ollama not responding on :11434"
ok "Ollama listening on :11434"

fi  # end INSTALL_OLLAMA

# ---- 5. Models -------------------------------------------------------------

if (( INSTALL_OLLAMA == 0 )); then
  note "Skipping model pull (no Ollama)"
else

step "Pulling models: ${MODELS_TO_PULL[*]}"
have_model() { ollama list 2>/dev/null | awk 'NR>1 {print $1}' | grep -qx "$1"; }
for m in "${MODELS_TO_PULL[@]}"; do
  if have_model "$m"; then
    ok "$m already present"
  else
    note "pulling $m"
    ollama pull "$m" || warn "$m pull failed (continuing — re-run install.sh to retry)"
  fi
done

fi  # end INSTALL_OLLAMA models block

# ---- 6. Colima + Docker ----------------------------------------------------

if (( INSTALL_WEBUI == 0 )); then
  note "Skipping Docker/Colima (Open WebUI not in profile)"
else

step "Colima + Docker CLI"
have colima || brew install colima
have docker || brew install docker
if ! colima status >/dev/null 2>&1; then
  note "Starting Colima VM (4 CPU, 8 GB RAM, 60 GB disk)"
  colima start --cpu 4 --memory 8 --disk 60
fi
ok "Docker via Colima ready"

# ---- 7. Open WebUI ---------------------------------------------------------
# (still inside INSTALL_WEBUI block from section 6)

step "Open WebUI on :$WEBUI_PORT (hardened container)"
if docker ps -a --format '{{.Names}}' | grep -qx open-webui; then
  docker start open-webui >/dev/null 2>&1 || true
  ok "open-webui container exists, ensured running"
else
  note "Pulling Open WebUI image (~5 GB)"
  # Hardened container: dropped capabilities, no-new-privileges, resource caps,
  # tmpfs for /tmp + writable HF cache, only the data volume is rw.
  # Run as root inside container (Open WebUI's image expects this) but escape
  # blocked via no-new-privileges + cap-drop.
  docker run -d --name open-webui -p $WEBUI_PORT:8080 \
    --add-host=host.docker.internal:host-gateway \
    --cap-drop=ALL \
    --cap-add=CHOWN --cap-add=DAC_OVERRIDE --cap-add=SETUID --cap-add=SETGID \
    --security-opt=no-new-privileges:true \
    --memory=4g --memory-swap=4g \
    --pids-limit=512 \
    --tmpfs /tmp:rw,nosuid,nodev,noexec,size=512m \
    -v open-webui:/app/backend/data \
    -e OLLAMA_BASE_URL=http://host.docker.internal:11434 \
    --restart always \
    ghcr.io/open-webui/open-webui:main
  ok "Container hardening: cap-drop=ALL (4 readded for app boot), no-new-privileges, mem 4G, pids 512, tmpfs /tmp"
fi

note "Waiting for Open WebUI to finish first-run setup (DB migrations + HF embedding model downloads, 2-4 min)"
code=000
for i in {1..240}; do
  code="$(curl -s -o /dev/null -w '%{http_code}' http://localhost:$WEBUI_PORT/)"
  [[ "$code" == "200" ]] && break
  sleep 2
done
if [[ "$code" == "200" ]]; then
  ok "Open WebUI ready at http://localhost:$WEBUI_PORT"
else
  warn "Open WebUI not responding (HTTP $code) — check 'docker logs open-webui'"
fi

fi  # end INSTALL_WEBUI

# ---- 8. OpenClaw via direct npm install ------------------------------------

if (( INSTALL_OPENCLAW == 0 )); then
  note "Skipping OpenClaw (not in profile)"
else

step "OpenClaw"
if ! have openclaw; then
  note "npm installing openclaw@latest globally to $NPM_PREFIX"
  npm install -g openclaw@latest
fi
ok "OpenClaw $(openclaw --version 2>&1 | head -1 | sed 's/.*OpenClaw //')"

# ---- 8b. typebox sanity check + auto-patch --------------------------------

step "typebox build sanity check"
patch_typebox() {
  local oc_root="$NPM_PREFIX/lib/node_modules/openclaw"
  [[ -d "$oc_root" ]] || { warn "openclaw not at $oc_root — skipping patch"; return; }

  local need_patch=0
  for tb in "$oc_root/node_modules/typebox/build/index.mjs" \
            "$oc_root/dist/extensions/google/node_modules/typebox/build/index.mjs"; do
    [[ -f "$tb" ]] || { need_patch=1; break; }
  done

  if (( need_patch == 0 )); then
    ok "typebox build complete in both locations"
    return
  fi

  warn "typebox build incomplete — patching from npm"
  local tmp; tmp=$(mktemp -d)
  ( cd "$tmp" && npm init -y >/dev/null 2>&1 \
              && npm install --silent --no-save typebox@1.1.33 ) \
    || { warn "could not fetch typebox from npm"; rm -rf "$tmp"; return; }
  local src="$tmp/node_modules/typebox/build"
  for dest in "$oc_root/node_modules/typebox/build" \
              "$oc_root/dist/extensions/google/node_modules/typebox/build"; do
    mkdir -p "$dest"
    cp -R "$src/." "$dest/"
  done
  rm -rf "$tmp"
  ok "typebox patched"
}
patch_typebox

# ---- 9. OpenClaw config (restore template) --------------------------------

step "OpenClaw config"
mkdir -p "$OPENCLAW_HOME"/{logs,workspace,agents/main/sessions,flows,identity}
chmod 700 "$OPENCLAW_HOME"

TPL="$BUNDLE_DIR/openclaw.json.template"
if [[ -f "$TPL" ]]; then
  if [[ -f "$OPENCLAW_HOME/openclaw.json" ]]; then
    cp "$OPENCLAW_HOME/openclaw.json" "$OPENCLAW_HOME/openclaw.json.bak.$(date +%s)"
    note "existing config backed up"
  fi
  TOKEN="$(openssl rand -hex 24)"
  sed -e "s|__HOME__|$HOME|g" -e "s|__GENERATE__|$TOKEN|g" "$TPL" \
    > "$OPENCLAW_HOME/openclaw.json"
  chmod 600 "$OPENCLAW_HOME/openclaw.json"
  ok "openclaw.json written ($OPENCLAW_HOME/openclaw.json)"
else
  warn "no template at $TPL — letting OpenClaw use defaults"
fi

# ---- 10. LaunchAgent (auto-start the gateway on boot) ---------------------

step "LaunchAgent for OpenClaw gateway"
NODE_BIN="$(which node)"
LAUNCH_PATH="$NPM_PREFIX/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"

mkdir -p "$(dirname "$LAUNCH_AGENT")"
cat > "$LAUNCH_AGENT" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>ai.openclaw.gateway</string>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>ThrottleInterval</key><integer>5</integer>
  <key>ProgramArguments</key>
  <array>
    <string>$NODE_BIN</string>
    <string>$NPM_PREFIX/lib/node_modules/openclaw/dist/index.js</string>
    <string>gateway</string>
    <string>--port</string>
    <string>$GATEWAY_PORT</string>
  </array>
  <key>StandardOutPath</key><string>$OPENCLAW_HOME/logs/gateway.log</string>
  <key>StandardErrorPath</key><string>$OPENCLAW_HOME/logs/gateway.err.log</string>
  <key>EnvironmentVariables</key>
  <dict>
    <key>HOME</key><string>$HOME</string>
    <key>PATH</key><string>$LAUNCH_PATH</string>
  </dict>
</dict>
</plist>
PLIST
chmod 644 "$LAUNCH_AGENT"

# Reload (bootout may fail if not loaded — that's fine)
launchctl bootout "gui/$(id -u)" "$LAUNCH_AGENT" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$LAUNCH_AGENT"
ok "LaunchAgent installed at $LAUNCH_AGENT"

# ---- 11. Wait for gateway --------------------------------------------------

note "Waiting for gateway on :$GATEWAY_PORT"
gateway_up=0
for i in {1..60}; do
  if lsof -nP -iTCP:$GATEWAY_PORT -sTCP:LISTEN >/dev/null 2>&1; then
    gateway_up=1; break
  fi
  sleep 1
done
if (( gateway_up == 0 )); then
  warn "Gateway didn't start within 60s — check $OPENCLAW_HOME/logs/gateway.err.log"
else
  ok "Gateway listening on :$GATEWAY_PORT"
fi

# ---- 12. Auto-approve pending CLI device pairing ---------------------------

step "CLI device pairing"
if (( gateway_up == 1 )); then
  # Trigger a CLI request so the gateway knows about us
  openclaw status >/dev/null 2>&1 || true
  sleep 2
  PEND_ID="$(openclaw devices list 2>/dev/null \
              | grep -oE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' \
              | head -1 || true)"
  if [[ -n "${PEND_ID:-}" ]]; then
    note "approving pending pairing $PEND_ID"
    openclaw devices approve "$PEND_ID" >/dev/null 2>&1 \
      && ok "device approved" \
      || warn "approval failed (non-fatal)"
  else
    ok "no pending pairing"
  fi
else
  warn "skipping pairing (gateway not up)"
fi

fi  # end INSTALL_OPENCLAW

# ---- 13. End-to-end test ---------------------------------------------------

if (( INSTALL_OPENCLAW == 0 )); then
  note "Skipping end-to-end agent test (no OpenClaw)"
else

step "End-to-end test (sending a real prompt to llama3.2:3b via OpenClaw)"
TEST_TIMEOUT=$([[ "$ARCH" == "arm64" ]] && echo 120 || echo 300)
TEST_OUT="$(mktemp)"

(
  openclaw infer model run \
    --model "ollama/llama3.2:3b" \
    --prompt "Say 'OK' and nothing else." \
    > "$TEST_OUT" 2>&1
) &
TEST_PID=$!

elapsed=0
while kill -0 "$TEST_PID" 2>/dev/null; do
  if (( elapsed >= TEST_TIMEOUT )); then
    kill -9 "$TEST_PID" 2>/dev/null || true
    break
  fi
  sleep 2; elapsed=$((elapsed + 2))
done
wait "$TEST_PID" 2>/dev/null || true

if grep -qiE "OK|hello|hi" "$TEST_OUT"; then
  ANSWER="$(grep -iE 'OK|hello|hi' "$TEST_OUT" | head -1 | tr -d '\r' | cut -c1-80)"
  ok "Agent responded in ${elapsed}s: \"$ANSWER\""
else
  warn "End-to-end test failed/timed out after ${elapsed}s. Tail of output:"
  tail -8 "$TEST_OUT" | sed 's/^/      /'
  warn "Open WebUI should still work at http://localhost:$WEBUI_PORT"
fi
rm -f "$TEST_OUT"

fi  # end INSTALL_OPENCLAW e2e test

# ---- 14. Summary -----------------------------------------------------------

cat <<EOF

────────────────────────────────────────────────────────────────────
  DONE.
────────────────────────────────────────────────────────────────────

  Open WebUI:           http://localhost:$WEBUI_PORT
                        (sign up — first user becomes admin, all local)

  OpenClaw dashboard:   http://localhost:$GATEWAY_PORT
  OpenClaw chat (TUI):  openclaw chat
  OpenClaw status:      openclaw status

  Ollama models:        $(ollama list 2>/dev/null | awk 'NR>1 {print $1}' | tr '\n' ' ')

  Auto-start:           OpenClaw gateway runs on login via LaunchAgent
                        Restart with:  launchctl kickstart -k gui/\$(id -u)/ai.openclaw.gateway

  If 'openclaw' is missing in a new terminal:
                        source ~/.zshrc

  Add cloud models (Claude/OpenAI) later:
                        openclaw configure
  Add API keys to Open WebUI:
                        Settings → Connections in the web UI

  Full install log:     $LOG_FILE

EOF

# ---- 15. macOS notification + open Open WebUI in browser ------------------

# Suppress this if AUTO_OPEN=0 was passed (useful in CI/scripted re-runs)
if [[ "${AUTO_OPEN:-1}" == "1" ]]; then
  osascript -e 'display notification "Your private AI stack is ready. Open WebUI is launching." with title "Private AI" sound name "Glass"' \
    >/dev/null 2>&1 || true

  # Give Open WebUI a beat to be 100% accepting connections, then open
  if curl -s --max-time 2 -o /dev/null -w '%{http_code}' "http://localhost:$WEBUI_PORT/" 2>/dev/null | grep -q '^200$'; then
    open "http://localhost:$WEBUI_PORT/" 2>/dev/null || true
  fi
fi

printf "\n=== install.sh finished at %s ===\n" "$(date '+%F %T')"
