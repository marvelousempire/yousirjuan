#!/usr/bin/env bash
# restore.sh — Restore a backup created by backup.sh.
#
#   bash restore.sh <path-to-backup.tgz>
#
# Restores:
#   • ~/.openclaw  (config, sessions, agent workspace)
#   • Open WebUI Docker volume (chat history, accounts, prompts)
#
# Does NOT restore:
#   • Ollama model files (re-pull them: install.sh asks which to pull, or
#     `ollama pull <name>` for individual ones)
#
# Pre-conditions: install.sh has already been run on this Mac (so Docker,
# Open WebUI container, OpenClaw CLI, etc. are present). Restore overlays
# data onto an existing install — it doesn't install the stack itself.

set -euo pipefail

# ---- helpers ---------------------------------------------------------------
step()  { printf "\n\033[1;34m==>\033[0m \033[1m%s\033[0m\n" "$*"; }
note()  { printf "    \033[2m%s\033[0m\n" "$*"; }
ok()    { printf "    \033[0;32m✓\033[0m %s\n" "$*"; }
warn()  { printf "    \033[0;33m!\033[0m %s\n" "$*"; }
die()   { printf "\n\033[0;31m✗ %s\033[0m\n" "$*"; exit 1; }
have()  { command -v "$1" >/dev/null 2>&1; }

# ---- args + sanity --------------------------------------------------------

[[ $# -ge 1 ]] || die "Usage: bash restore.sh <path-to-backup.tgz>"

ARCHIVE="$1"
[[ -f "$ARCHIVE" ]] || die "Archive not found: $ARCHIVE"

step "Restore from $ARCHIVE"

# ---- preview manifest -----------------------------------------------------

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

note "extracting to inspect manifest"
tar xzf "$ARCHIVE" -C "$STAGE"

if [[ -f "$STAGE/manifest.txt" ]]; then
  echo
  sed 's/^/    /' "$STAGE/manifest.txt"
  echo
else
  warn "no manifest.txt in archive — proceeding anyway"
fi

read -r -p "    Restore this backup over current data? [y/N] " yn
[[ "$yn" =~ ^[Yy]$ ]] || die "Aborted."

# ---- 1. OpenClaw ----------------------------------------------------------

step "OpenClaw config + sessions"
if [[ -d "$STAGE/openclaw" && -n "$(ls -A "$STAGE/openclaw" 2>/dev/null)" ]]; then
  # Stop gateway so files aren't being held open
  launchctl bootout "gui/$(id -u)" "$HOME/Library/LaunchAgents/ai.openclaw.gateway.plist" 2>/dev/null || true
  pkill -f "openclaw gateway" 2>/dev/null || true
  sleep 1

  # Backup existing
  if [[ -d "$HOME/.openclaw" ]]; then
    BAK="$HOME/.openclaw.pre-restore.$(date +%s)"
    mv "$HOME/.openclaw" "$BAK"
    note "previous ~/.openclaw moved to $BAK"
  fi

  cp -R "$STAGE/openclaw" "$HOME/.openclaw"
  chmod 700 "$HOME/.openclaw"
  [[ -f "$HOME/.openclaw/openclaw.json" ]] && chmod 600 "$HOME/.openclaw/openclaw.json"
  ok "~/.openclaw restored"

  # Restart gateway
  if [[ -f "$HOME/Library/LaunchAgents/ai.openclaw.gateway.plist" ]]; then
    launchctl bootstrap "gui/$(id -u)" "$HOME/Library/LaunchAgents/ai.openclaw.gateway.plist" 2>/dev/null || true
    ok "gateway LaunchAgent re-loaded"
  fi
else
  note "archive contains no OpenClaw data — skipping"
fi

# ---- 2. Open WebUI volume -------------------------------------------------

step "Open WebUI volume"
if [[ -s "$STAGE/open-webui.tar.gz" ]]; then
  have docker || die "Docker not installed — run install.sh first"
  docker info >/dev/null 2>&1 || die "Docker daemon not reachable — start Colima first"

  # Stop the container so we can write to the volume cleanly
  if docker ps --format '{{.Names}}' | grep -qx open-webui; then
    note "stopping open-webui container"
    docker stop open-webui >/dev/null
    STARTED_BY_US=1
  else
    STARTED_BY_US=0
  fi

  # Make sure the volume exists
  docker volume create open-webui >/dev/null

  # Optional: backup current volume before nuking
  read -r -p "    Backup current open-webui volume before overwriting? [Y/n] " yn_bk
  if [[ ! "$yn_bk" =~ ^[Nn]$ ]]; then
    BAK_FILE="$HOME/Documents/private-ai-backups/open-webui.pre-restore.$(date +%s).tar.gz"
    mkdir -p "$(dirname "$BAK_FILE")"
    docker run --rm -v open-webui:/data:ro -v "$(dirname "$BAK_FILE")":/backup \
      alpine tar czf "/backup/$(basename "$BAK_FILE")" -C /data .
    ok "current volume archived → $BAK_FILE"
  fi

  # Wipe and restore
  note "restoring open-webui volume contents"
  docker run --rm -v open-webui:/data \
    alpine sh -c 'rm -rf /data/..?* /data/.[!.]* /data/* 2>/dev/null || true'
  docker run --rm -v open-webui:/data -v "$STAGE":/backup \
    alpine sh -c 'tar xzf /backup/open-webui.tar.gz -C /data'
  ok "volume restored"

  if (( STARTED_BY_US == 1 )); then
    docker start open-webui >/dev/null
    ok "open-webui container restarted"
  fi
else
  note "archive contains no Open WebUI volume — skipping"
fi

# ---- 3. Done --------------------------------------------------------------

cat <<EOF

────────────────────────────────────────────────────────────────────
  Restore complete.
────────────────────────────────────────────────────────────────────

  Open WebUI:    http://localhost:3000
  OpenClaw:      openclaw status

  Models from the source machine still need to be re-pulled here:
$(grep -A 99 'Models present' "$STAGE/manifest.txt" 2>/dev/null | tail -n +2 | grep -E '^  [a-z]' | sed 's/^  /    ollama pull /' | head -10 || true)

EOF
