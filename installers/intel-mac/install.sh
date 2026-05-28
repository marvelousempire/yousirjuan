#!/usr/bin/env bash
# ============================================================================
#  You-Sir Juan OS — Intel Mac Installer
#  Optimized for: iMac 2017 / MacBook (Intel) / Mac mini (Intel)
#  macOS Ventura 13+ | x86_64 | 16 GB+ RAM recommended (64 GB = ideal)
#
#  One-liner:
#    curl -fsSL https://get.yousirjuan.ai/intel-mac | sh
#
#  Or from inside the cloned repo:
#    bash installers/intel-mac/install.sh
#
#  What this does:
#    1. Verifies macOS + Intel architecture
#    2. Installs Homebrew, Git, Node 20, pnpm, Docker, Ollama
#    3. Clones or updates the You-Sir Juan repo
#    4. Writes .env optimized for Intel CPU inference
#    5. Starts Docker services (Postgres, Redis, Qdrant, Kokoro, Ollama)
#    6. Pulls llama3.2:3b (best model for Intel CPU real-time voice)
#    7. Installs Node deps + starts the API + web interface
#    8. Opens the browser to the family interface
#
#  Idempotent — safe to re-run.
# ============================================================================

set -euo pipefail
trap 'printf "\n\033[0;31m✗ Failed at line %s. Check %s for details.\033[0m\n" "$LINENO" "$LOG_FILE" >&2' ERR

# ── Config ──────────────────────────────────────────────────────────────────
YSJ_REPO="https://github.com/marvelousempire/yousirjuan.git"
YSJ_DIR="${YSJ_DIR:-$HOME/yousirjuan}"
YSJ_BRANCH="${YSJ_BRANCH:-main}"
OLLAMA_MODEL="${OLLAMA_MODEL:-llama3.2:3b}"   # best for Intel real-time voice
API_PORT="${API_PORT:-4000}"
WEB_PORT="${WEB_PORT:-3000}"
LOG_FILE="$HOME/yousirjuan-install.log"
MIN_RAM_GB=8
RECOMMENDED_RAM_GB=16

# ── Logging ──────────────────────────────────────────────────────────────────
exec > >(tee -a "$LOG_FILE") 2>&1
printf "\n=== You-Sir Juan OS — Intel Mac Install started at %s ===\n\n" "$(date '+%F %T')"

# ── Helpers ──────────────────────────────────────────────────────────────────
step()  { printf "\n\033[1;34m==>\033[0m \033[1m%s\033[0m\n" "$*"; }
note()  { printf "    \033[2m%s\033[0m\n" "$*"; }
ok()    { printf "    \033[0;32m✓\033[0m  %s\n" "$*"; }
warn()  { printf "    \033[0;33m⚠\033[0m  %s\n" "$*"; }
die()   { printf "\n\033[0;31m✗  %s\033[0m\n" "$*" >&2; exit 1; }
have()  { command -v "$1" >/dev/null 2>&1; }
banner() {
  printf "\n\033[1;35m"
  printf "  ╔═══════════════════════════════════════════╗\n"
  printf "  ║       You-Sir Juan™ Operating System      ║\n"
  printf "  ║         Intel Mac Setup — v0.1            ║\n"
  printf "  ╚═══════════════════════════════════════════╝\n"
  printf "\033[0m\n"
}

# ── 1. Environment preflight ─────────────────────────────────────────────────
banner
step "Preflight checks"

[[ "$(uname)" == "Darwin" ]] || die "This installer is macOS only."

ARCH="$(uname -m)"
[[ "$ARCH" == "x86_64" ]] || {
  warn "Detected $ARCH (Apple Silicon). This installer targets Intel Macs."
  warn "For Apple Silicon, run: bash installers/macos.sh"
  read -rp "    Continue anyway? [y/N] " _cont
  [[ "$_cont" =~ ^[yY]$ ]] || exit 0
}

MACOS_VER="$(sw_vers -productVersion)"
MACOS_MAJOR="${MACOS_VER%%.*}"
[[ "$MACOS_MAJOR" -ge 13 ]] || die "macOS 13 (Ventura) or later required. You have $MACOS_VER."

RAM_GB="$(sysctl -n hw.memsize | awk '{printf "%d", $1/1024/1024/1024}')"
CPU_BRAND="$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo 'Intel CPU')"
CORES="$(sysctl -n hw.physicalcpu)"
DISK_FREE_GB="$(df -g "$HOME" | awk 'NR==2{print $4}')"

note "macOS $MACOS_VER | $ARCH | $CPU_BRAND"
note "${RAM_GB} GB RAM | ${CORES} CPU cores | ${DISK_FREE_GB} GB free disk"

[[ "$RAM_GB" -ge "$MIN_RAM_GB" ]] || die "Minimum ${MIN_RAM_GB} GB RAM required. Found ${RAM_GB} GB."
[[ "$DISK_FREE_GB" -ge 20 ]] || die "Need at least 20 GB free disk. Found ${DISK_FREE_GB} GB."
[[ "$RAM_GB" -lt "$RECOMMENDED_RAM_GB" ]] && \
  warn "Recommended ${RECOMMENDED_RAM_GB}+ GB RAM for best performance. You have ${RAM_GB} GB."
[[ "$RAM_GB" -ge 32 ]] && ok "${RAM_GB} GB RAM — excellent for CPU inference on Intel"

ok "Preflight passed"

# ── 2. Homebrew ──────────────────────────────────────────────────────────────
step "Homebrew"
if ! have brew; then
  note "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Add to path for the rest of this script
  eval "$(/usr/local/bin/brew shellenv)"
  ok "Homebrew installed"
else
  ok "Homebrew $(brew --version | head -1 | awk '{print $2}') already installed"
fi

# ── 3. Git ───────────────────────────────────────────────────────────────────
step "Git"
if ! have git; then
  brew install git
fi
ok "Git $(git --version | awk '{print $3}')"

# ── 4. Node.js 20+ via nvm ───────────────────────────────────────────────────
step "Node.js 20+"
if ! have node || [[ "$(node -e 'process.stdout.write(String(process.version.match(/\d+/)[0]))')" -lt 20 ]]; then
  note "Installing Node.js via nvm..."
  if ! have nvm && [[ ! -d "$HOME/.nvm" ]]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
  fi
  export NVM_DIR="$HOME/.nvm"
  # shellcheck source=/dev/null
  [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
  nvm install 20
  nvm use 20
  nvm alias default 20
fi
ok "Node $(node --version)"

# ── 5. pnpm ──────────────────────────────────────────────────────────────────
step "pnpm"
if ! have pnpm; then
  curl -fsSL https://get.pnpm.io/install.sh | sh -
  # Source updated shell config
  export PNPM_HOME="$HOME/Library/pnpm"
  export PATH="$PNPM_HOME:$PATH"
fi
ok "pnpm $(pnpm --version)"

# ── 6. Docker Desktop ────────────────────────────────────────────────────────
step "Docker"
if ! have docker; then
  warn "Docker Desktop not found."
  note "Download Docker Desktop for Mac (Intel chip):"
  note "  https://docs.docker.com/desktop/install/mac-install/"
  note "  → Choose: Mac with Intel chip"
  note ""
  note "After installing Docker Desktop, re-run this installer:"
  note "  bash installers/intel-mac/install.sh"
  note ""
  read -rp "    Open download page in browser? [Y/n] " _open_docker
  [[ ! "$_open_docker" =~ ^[nN]$ ]] && open "https://docs.docker.com/desktop/install/mac-install/"
  die "Docker Desktop required. Install it and re-run this script."
fi

# Ensure Docker daemon is running
if ! docker info >/dev/null 2>&1; then
  note "Starting Docker Desktop..."
  open -a Docker
  printf "    Waiting for Docker to start"
  for _ in {1..30}; do
    docker info >/dev/null 2>&1 && break
    printf "."
    sleep 2
  done
  printf "\n"
  docker info >/dev/null 2>&1 || die "Docker did not start. Open Docker Desktop manually and retry."
fi
ok "Docker $(docker --version | awk '{print $3}' | tr -d ',')"

# ── 7. Ollama ────────────────────────────────────────────────────────────────
step "Ollama (Intel Mac)"
if ! have ollama; then
  note "Installing Ollama..."
  curl -fsSL https://ollama.ai/install.sh | sh
fi
ok "Ollama $(ollama --version 2>/dev/null | head -1)"

# ── 8. Clone or update repo ──────────────────────────────────────────────────
step "You-Sir Juan repo"
if [[ -d "$YSJ_DIR/.git" ]]; then
  note "Repo found at $YSJ_DIR — pulling latest..."
  git -C "$YSJ_DIR" fetch origin
  git -C "$YSJ_DIR" checkout "$YSJ_BRANCH"
  git -C "$YSJ_DIR" pull origin "$YSJ_BRANCH"
  git -C "$YSJ_DIR" submodule update --init --recursive
  ok "Repo updated to $(git -C "$YSJ_DIR" rev-parse --short HEAD)"
else
  note "Cloning into $YSJ_DIR ..."
  git clone --branch "$YSJ_BRANCH" --recurse-submodules "$YSJ_REPO" "$YSJ_DIR"
  ok "Repo cloned at $(git -C "$YSJ_DIR" rev-parse --short HEAD)"
fi

# ── 9. Write .env optimized for Intel Mac ───────────────────────────────────
step ".env configuration"
ENV_FILE="$YSJ_DIR/.env"

# Only write if it doesn't already exist
if [[ ! -f "$ENV_FILE" ]]; then
  # Generate a random session secret
  SESSION_SECRET="$(openssl rand -hex 32)"

  cat > "$ENV_FILE" << DOTENV
# You-Sir Juan OS — Intel Mac profile
# Generated by installers/intel-mac/install.sh on $(date '+%F')

# ── API ──────────────────────────────────────────────────────────────
PORT=$API_PORT
SESSION_SECRET=$SESSION_SECRET
CORS_ORIGINS=http://localhost:$WEB_PORT

# ── Ollama — Intel CPU optimized ─────────────────────────────────────
# llama3.2:3b is the recommended model for real-time voice on Intel i5/i7.
# It loads in ~2 GB RAM and generates at 8-15 tok/sec — fast enough for
# 2-4 second voice turn responses.
# Upgrade to llama3.1:8b for higher quality if you can tolerate ~5-8 sec.
OLLAMA_URL=http://localhost:11434
OLLAMA_MODEL=$OLLAMA_MODEL

# ── Kokoro TTS ───────────────────────────────────────────────────────
KOKORO_URL=http://localhost:8880

# ── Database ─────────────────────────────────────────────────────────
POSTGRES_PASSWORD=full
DATABASE_URL=postgresql://full:full@localhost:5432/yousirjuan

# ── Memory ───────────────────────────────────────────────────────────
MEMORY_DIR=.data/memory

# ── iOS app (point at this machine's LAN IP for real-device use) ─────
YOUSIRJUAN_API_URL=http://localhost:$API_PORT

# ── Services ─────────────────────────────────────────────────────────
HOMEKIT_BRIDGE_PORT=4002
DOTENV
  ok ".env written with Intel Mac profile"
else
  ok ".env already exists — not overwritten"
fi

# ── 10. Node dependencies ────────────────────────────────────────────────────
step "Node dependencies"
cd "$YSJ_DIR"
pnpm install --frozen-lockfile
cd apps/yousirjuan-web && pnpm install --frozen-lockfile
cd "$YSJ_DIR"
ok "Node deps installed"

# ── 11. Docker services ──────────────────────────────────────────────────────
step "Docker services (Postgres, Redis, Qdrant, Ollama, Kokoro)"
cd "$YSJ_DIR"

# Start everything except nginx (which needs domain config for production)
docker compose up -d postgres redis qdrant ollama kokoro

# Wait for Postgres to be healthy
printf "    Waiting for Postgres"
for _ in {1..20}; do
  docker exec ysj-postgres pg_isready -U full >/dev/null 2>&1 && break
  printf "."
  sleep 2
done
printf "\n"
ok "Docker services running"

# ── 12. Pull Ollama model ────────────────────────────────────────────────────
step "Pulling Ollama model: $OLLAMA_MODEL"
note "This download may take a few minutes (~2 GB for llama3.2:3b)..."

# Start Ollama if not already running
if ! pgrep -q ollama; then
  ollama serve &>/dev/null &
  sleep 3
fi

if ! ollama list 2>/dev/null | grep -q "${OLLAMA_MODEL%%:*}"; then
  ollama pull "$OLLAMA_MODEL"
  ok "$OLLAMA_MODEL pulled"
else
  ok "$OLLAMA_MODEL already present"
fi

# ── 13. Set up LaunchAgent for always-on API ────────────────────────────────
step "LaunchAgent (always-on API)"
PLIST_PATH="$HOME/Library/LaunchAgents/ai.yousirjuan.api.plist"
NODE_BIN="$(which node)"
PNPM_BIN="$(which pnpm)"

if [[ ! -f "$PLIST_PATH" ]]; then
  cat > "$PLIST_PATH" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>ai.yousirjuan.api</string>
  <key>ProgramArguments</key>
  <array>
    <string>$NODE_BIN</string>
    <string>$YSJ_DIR/api/server.js</string>
  </array>
  <key>WorkingDirectory</key>
  <string>$YSJ_DIR</string>
  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key>
    <string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
    <key>NODE_ENV</key>
    <string>production</string>
  </dict>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>StandardOutPath</key>
  <string>$HOME/Library/Logs/yousirjuan-api.log</string>
  <key>StandardErrorPath</key>
  <string>$HOME/Library/Logs/yousirjuan-api.log</string>
</dict>
</plist>
PLIST
  launchctl load "$PLIST_PATH"
  ok "LaunchAgent installed — API starts on login"
else
  ok "LaunchAgent already installed"
fi

# ── 14. Start the web app (dev mode for first run) ──────────────────────────
step "Starting web interface"
note "Launching API and web app in background..."

# Make sure API is responding
sleep 2
if curl -sf "http://localhost:$API_PORT/health" >/dev/null 2>&1; then
  ok "API running at http://localhost:$API_PORT"
else
  note "Starting API..."
  cd "$YSJ_DIR"
  PORT=$API_PORT node api/server.js &>/dev/null &
  sleep 3
fi

# Start web in background
cd "$YSJ_DIR/apps/yousirjuan-web"
pnpm dev &>/dev/null &
WEB_PID=$!
sleep 5

# ── 15. Done ─────────────────────────────────────────────────────────────────
printf "\n"
printf "\033[1;32m"
printf "  ╔═══════════════════════════════════════════════════════╗\n"
printf "  ║                                                       ║\n"
printf "  ║   You-Sir Juan OS is running.                        ║\n"
printf "  ║                                                       ║\n"
printf "  ║   Web interface:   http://localhost:$WEB_PORT           ║\n"
printf "  ║   API:             http://localhost:$API_PORT           ║\n"
printf "  ║   Ollama model:    $OLLAMA_MODEL                  ║\n"
printf "  ║                                                       ║\n"
printf "  ║   Log file:        $LOG_FILE  ║\n"
printf "  ║                                                       ║\n"
printf "  ╚═══════════════════════════════════════════════════════╝\n"
printf "\033[0m\n"

printf "  \033[2mNote: The API LaunchAgent will restart automatically on login.\033[0m\n"
printf "  \033[2mTo stop: launchctl unload ~/Library/LaunchAgents/ai.yousirjuan.api.plist\033[0m\n\n"

note "Want full iOS 18 development capability on this machine?"
note "See: installers/intel-mac/opencore-sonoma-guide.md"
note "OpenCore Legacy Patcher installs Sonoma → unlocks Xcode 16 → iPadOS 18 builds."
printf "\n"

# Open the browser
open "http://localhost:$WEB_PORT"
