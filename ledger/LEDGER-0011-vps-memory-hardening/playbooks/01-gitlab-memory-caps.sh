#!/usr/bin/env bash
# 01-gitlab-memory-caps.sh — apply GitLab Puma + Sidekiq memory caps.
#
# Idempotent: re-running yields no diff and no errors.
# Reversible: invoke with --undo to restore from backup.
#
# Per LEDGER-0007 runbook 05:
#   - per_worker_max_memory_mb: default ~1024 → 400 (kills Puma worker if it grows past)
#   - sidekiq concurrency: default 20 → 10 (cuts in-flight job memory in half)
#
# Combined effect: ~1.2 GB of headroom on an 8 GB host under steady-state load.

set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "must run as root (sudo)"; exit 1; }

GITLAB_RB="/etc/gitlab/gitlab.rb"
BACKUP_DIR="/etc/gitlab/yousirjuan-backups"
MARKER="# LEDGER-0011 memory caps"
PUMA_LINE="puma['per_worker_max_memory_mb'] = 400  $MARKER"
SIDEKIQ_LINE="sidekiq['concurrency'] = 10  $MARKER"

BLUE='\033[1;34m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; RED='\033[1;31m'; NC='\033[0m'
step() { printf "${BLUE}→ %s${NC}\n" "$*"; }
ok()   { printf "${GREEN}✓ %s${NC}\n" "$*"; }
warn() { printf "${YELLOW}⚠ %s${NC}\n" "$*"; }
die()  { printf "${RED}✗ %s${NC}\n" "$*" >&2; exit 1; }

action="${1:-apply}"

ensure_gitlab() {
  [[ -f "$GITLAB_RB" ]] || die "$GITLAB_RB not found — is GitLab Omnibus installed?"
  command -v gitlab-ctl >/dev/null || die "gitlab-ctl not in PATH"
}

backup_rb() {
  mkdir -p "$BACKUP_DIR"
  local stamp; stamp=$(date '+%Y-%m-%dT%H-%M-%S')
  cp "$GITLAB_RB" "$BACKUP_DIR/gitlab.rb.$stamp.bak"
  ok "backup: $BACKUP_DIR/gitlab.rb.$stamp.bak"
}

apply() {
  ensure_gitlab
  step "Applying LEDGER-0011 GitLab memory caps"

  # Idempotency: if our marker lines are already present, skip the write.
  if grep -qF "$MARKER" "$GITLAB_RB"; then
    ok "marker already present — no changes (still safe to gitlab-ctl reconfigure)"
  else
    backup_rb
    {
      printf '\n# ─── LEDGER-0011 memory caps (begin) ──────────────────────\n'
      printf '%s\n' "$PUMA_LINE"
      printf '%s\n' "$SIDEKIQ_LINE"
      printf '# ─── LEDGER-0011 memory caps (end) ────────────────────────\n'
    } >> "$GITLAB_RB"
    ok "appended caps to $GITLAB_RB"
  fi

  step "Reconfiguring GitLab (takes ~60-90s)"
  gitlab-ctl reconfigure
  ok "GitLab reconfigured"

  step "Verifying caps in effect"
  grep -E "per_worker_max_memory_mb|sidekiq\['concurrency'\]" "$GITLAB_RB" | grep "$MARKER"
}

undo() {
  ensure_gitlab
  step "Reverting LEDGER-0011 GitLab memory caps"

  if ! grep -qF "$MARKER" "$GITLAB_RB"; then
    warn "marker not present — nothing to revert"
    return 0
  fi

  backup_rb

  # Remove our marked block.
  sed -i.tmp '/# ─── LEDGER-0011 memory caps (begin)/,/# ─── LEDGER-0011 memory caps (end)/d' "$GITLAB_RB"
  rm -f "${GITLAB_RB}.tmp"
  ok "removed marked block from $GITLAB_RB"

  step "Reconfiguring GitLab"
  gitlab-ctl reconfigure
  ok "GitLab reconfigured (back to defaults)"
}

case "$action" in
  apply|--apply|"")  apply ;;
  undo|--undo)       undo ;;
  *) die "usage: $0 [apply|undo]" ;;
esac
