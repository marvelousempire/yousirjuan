#!/usr/bin/env bash
# backup.sh — Snapshot the private AI stack's user data into a single tarball.
#
# Captures:
#   • Open WebUI Docker volume (chat history, accounts, prompts, knowledge)
#   • OpenClaw config + sessions + agent workspaces (~/.openclaw)
#   • Manifest with versions + timestamp
#
# Does NOT capture:
#   • Ollama model files (they're huge and re-pullable; pull again with `ollama pull`)
#   • Homebrew packages, Docker images, system state
#
#   bash backup.sh                              # writes to ~/Documents/private-ai-backups/
#   bash backup.sh /Volumes/USB/my-backup.tgz   # explicit path
#
# Backups can be safely created while the stack is running (containers stay up,
# Docker volume is read via a transient alpine container with read-only mount).

set -euo pipefail

# ---- helpers ---------------------------------------------------------------
step()  { printf "\n\033[1;34m==>\033[0m \033[1m%s\033[0m\n" "$*"; }
note()  { printf "    \033[2m%s\033[0m\n" "$*"; }
ok()    { printf "    \033[0;32m✓\033[0m %s\n" "$*"; }
warn()  { printf "    \033[0;33m!\033[0m %s\n" "$*"; }
die()   { printf "\n\033[0;31m✗ %s\033[0m\n" "$*"; exit 1; }
have()  { command -v "$1" >/dev/null 2>&1; }

# ---- destination -----------------------------------------------------------

STAMP="$(date '+%Y%m%d-%H%M%S')"
DEFAULT_DIR="$HOME/Documents/private-ai-backups"
DEST="${1:-$DEFAULT_DIR/private-ai-$STAMP.tgz}"

# If user passed a directory, append a default filename
if [[ -d "$DEST" ]]; then
  DEST="$DEST/private-ai-$STAMP.tgz"
fi

mkdir -p "$(dirname "$DEST")"
[[ -w "$(dirname "$DEST")" ]] || die "Can't write to $(dirname "$DEST")"

step "Backup → $DEST"

# ---- staging dir -----------------------------------------------------------

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

# ---- 1. OpenClaw ----------------------------------------------------------

step "OpenClaw config + sessions"
if [[ -d "$HOME/.openclaw" ]]; then
  cp -R "$HOME/.openclaw" "$STAGE/openclaw"
  # Strip transient log files — they're large and not user data
  rm -rf "$STAGE/openclaw/logs"
  ok "captured ~/.openclaw ($(du -sh "$STAGE/openclaw" | awk '{print $1}'))"
else
  warn "no ~/.openclaw found — skipping"
  mkdir -p "$STAGE/openclaw"
fi

# ---- 2. Open WebUI Docker volume ------------------------------------------

step "Open WebUI volume (chat history, accounts, prompts)"
if have docker && docker volume inspect open-webui >/dev/null 2>&1; then
  note "exporting open-webui volume via transient alpine container"
  docker run --rm \
    -v open-webui:/data:ro \
    -v "$STAGE":/backup \
    alpine sh -c "tar czf /backup/open-webui.tar.gz -C /data ." \
    || die "open-webui volume export failed"
  ok "captured ($(du -sh "$STAGE/open-webui.tar.gz" | awk '{print $1}'))"
else
  warn "Docker not running OR open-webui volume not present — skipping"
  : > "$STAGE/open-webui.tar.gz"  # zero-byte placeholder
fi

# ---- 3. Manifest ----------------------------------------------------------

step "Manifest"
{
  echo "Private AI backup"
  echo "Created: $(date '+%F %T %Z')"
  echo "Hostname: $(hostname)"
  echo "macOS: $(sw_vers -productVersion) ($(uname -m))"
  echo
  echo "Versions:"
  echo "  ollama:     $(ollama --version 2>&1 | head -1 || echo n/a)"
  echo "  openclaw:   $(openclaw --version 2>&1 | head -1 || echo n/a)"
  echo "  docker:     $(docker --version 2>&1 || echo n/a)"
  echo "  open-webui image: $(docker inspect ghcr.io/open-webui/open-webui:main --format '{{.Id}}' 2>/dev/null | head -c 19 || echo n/a)"
  echo
  echo "Models present at backup time (re-pull with 'ollama pull <name>'):"
  ollama list 2>/dev/null | tail -n +2 | awk '{print "  " $1 " (" $3 " " $4 ")"}' || echo "  (Ollama not running)"
  echo
  echo "Models directory: $(launchctl getenv OLLAMA_MODELS 2>/dev/null || echo "$HOME/.ollama/models (default)")"
  echo
  echo "Contents of this archive:"
  echo "  manifest.txt       — this file"
  echo "  openclaw/          — copy of ~/.openclaw (config, sessions, workspace)"
  echo "  open-webui.tar.gz  — Open WebUI Docker volume contents"
} > "$STAGE/manifest.txt"
ok "manifest written"

# ---- 4. Roll into final tarball -------------------------------------------

step "Sealing archive"
tar czf "$DEST" -C "$STAGE" .
SIZE="$(du -sh "$DEST" | awk '{print $1}')"
ok "wrote $DEST ($SIZE)"

cat <<EOF

────────────────────────────────────────────────────────────────────
  Backup complete.

  File:     $DEST
  Size:     $SIZE
  Restore:  bash restore.sh "$DEST"
────────────────────────────────────────────────────────────────────

EOF
