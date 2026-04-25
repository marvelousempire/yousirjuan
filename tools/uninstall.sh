#!/usr/bin/env bash
# uninstall.sh — Reverse what install.sh did.
#
#   bash uninstall.sh            # interactive; prompts before destructive steps
#   bash uninstall.sh --all      # remove EVERYTHING including Ollama models,
#                                # Open WebUI chat history, and Colima VM
#
# Safe items (configs, LaunchAgent, OpenClaw CLI, Open WebUI container) are
# always removed. Big/irreplaceable items (models, chat history, Docker VM,
# Homebrew packages) prompt individually unless --all is passed.
#
# Never removes: Homebrew itself, Node.js, /usr/local, your $HOME/.zshrc.

set -euo pipefail

FLAG_ALL=0
[[ "${1:-}" == "--all" ]] && FLAG_ALL=1

# ---- helpers ---------------------------------------------------------------
step()  { printf "\n\033[1;34m==>\033[0m \033[1m%s\033[0m\n" "$*"; }
note()  { printf "    \033[2m%s\033[0m\n" "$*"; }
ok()    { printf "    \033[0;32m✓\033[0m %s\n" "$*"; }
warn()  { printf "    \033[0;33m!\033[0m %s\n" "$*"; }
have()  { command -v "$1" >/dev/null 2>&1; }

confirm() {
  (( FLAG_ALL == 1 )) && return 0
  local prompt="$1"
  read -r -p "    $prompt [y/N] " yn
  [[ "$yn" =~ ^[Yy]$ ]]
}

# ---- 1. OpenClaw gateway + LaunchAgent ------------------------------------

step "OpenClaw gateway"
LA="$HOME/Library/LaunchAgents/ai.openclaw.gateway.plist"
if [[ -f "$LA" ]]; then
  launchctl bootout "gui/$(id -u)" "$LA" 2>/dev/null || true
  rm -f "$LA"
  ok "LaunchAgent removed"
else
  note "no LaunchAgent at $LA"
fi
pkill -f "openclaw gateway" 2>/dev/null || true
pkill -f "openclaw-tui" 2>/dev/null || true
ok "openclaw processes stopped"

# ---- 1b. Env LaunchAgent (OLLAMA_MODELS at boot) --------------------------

ENV_LA="$HOME/Library/LaunchAgents/ai.private-ai.env.plist"
if [[ -f "$ENV_LA" ]]; then
  launchctl bootout "gui/$(id -u)" "$ENV_LA" 2>/dev/null || true
  rm -f "$ENV_LA"
  ok "env LaunchAgent removed"
fi
launchctl unsetenv OLLAMA_MODELS 2>/dev/null || true
launchctl unsetenv OLLAMA_HOST 2>/dev/null || true

# ---- 2. OpenClaw CLI + config ---------------------------------------------

step "OpenClaw CLI"
if have openclaw; then
  npm uninstall -g openclaw 2>/dev/null && ok "npm package removed" \
    || warn "npm uninstall failed (maybe installed elsewhere)"
else
  note "openclaw CLI not on PATH"
fi

if [[ -d "$HOME/.openclaw" ]]; then
  if confirm "Remove ~/.openclaw (config, sessions, workspace, logs)?"; then
    rm -rf "$HOME/.openclaw"
    ok "~/.openclaw deleted"
  else
    note "kept ~/.openclaw"
  fi
fi

# ---- 3. Open WebUI container + volume -------------------------------------

step "Open WebUI"
if have docker && docker ps -a --format '{{.Names}}' 2>/dev/null | grep -qx open-webui; then
  docker rm -f open-webui >/dev/null 2>&1 || true
  ok "container removed"

  if confirm "Remove the open-webui Docker volume (chat history, accounts, prompts — IRREVERSIBLE)?"; then
    docker volume rm open-webui >/dev/null 2>&1 || warn "volume remove failed"
    ok "volume removed"
  else
    note "kept open-webui volume"
  fi
else
  note "no open-webui container"
fi

# ---- 4. Colima VM ---------------------------------------------------------

step "Colima VM"
if have colima && colima status >/dev/null 2>&1; then
  if confirm "Stop + delete Colima VM (removes ALL Docker data — images, other containers)?"; then
    colima stop >/dev/null 2>&1 || true
    colima delete -f >/dev/null 2>&1 || true
    ok "Colima removed"
  else
    note "kept Colima VM (it's still running)"
  fi
fi

# ---- 5. Ollama models + service -------------------------------------------

step "Ollama"
if have ollama; then
  if confirm "Remove Ollama models (gemma2:2b, llama3.2:3b — ~3.6 GB)?"; then
    ollama rm gemma2:2b 2>/dev/null || true
    ollama rm llama3.2:3b 2>/dev/null || true
    ok "models removed"
  else
    note "kept Ollama models"
  fi

  if confirm "Uninstall Ollama itself?"; then
    brew services stop ollama 2>/dev/null || true
    pkill -f "ollama serve" 2>/dev/null || true
    if brew list ollama >/dev/null 2>&1; then
      brew uninstall ollama
      ok "Ollama uninstalled (brew)"
    elif [[ -d /Applications/Ollama.app ]]; then
      rm -rf /Applications/Ollama.app
      rm -f /usr/local/bin/ollama 2>/dev/null || sudo rm -f /usr/local/bin/ollama
      ok "Ollama app removed"
    fi
    if confirm "Remove ~/.ollama (manifests, model blobs — IRREVERSIBLE)?"; then
      rm -rf "$HOME/.ollama"
      ok "~/.ollama deleted"
    fi
  fi
fi

# ---- 6. typebox patch artifacts (if any) ----------------------------------

step "Cleanup"
# Nothing to do — typebox lived inside the openclaw node_modules which was
# removed via npm uninstall above.
ok "done"

# ---- 7. Summary -----------------------------------------------------------

cat <<EOF

────────────────────────────────────────────────────────────────────
  Uninstall complete.
────────────────────────────────────────────────────────────────────

  Still installed (intentionally — used by other things on your Mac):
    • Homebrew
    • Node.js / npm
    • Colima + Docker CLI (unless you chose to delete the VM)
    • Your $HOME/.zshrc PATH entry for ~/.npm-global/bin

  To remove those, do it manually:
    brew uninstall colima docker node
    brew uninstall --cask ...   # if anything was cask-installed

  Re-run install.sh anytime to set everything back up.

EOF
