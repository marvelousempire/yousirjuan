#!/usr/bin/env bash
#
# install-user-scope.sh — promote the workflow-debugger agent from project
# scope (.claude/agents/ in this repo) to user scope (~/.claude/agents/),
# making it available in any Claude Code session on this machine.
#
# Usage:
#   bash ledger/LEDGER-0002-workflow-debugger-agent/playbooks/install-user-scope.sh
#   bash …/install-user-scope.sh uninstall   # remove the user-scope copy
#   bash …/install-user-scope.sh status      # show what's installed where
#
# Idempotent. Logs to ~/yousirjuan-ledger.log.

set -euo pipefail

LEDGER_LOG="${HOME}/yousirjuan-ledger.log"
mkdir -p "$(dirname "$LEDGER_LOG")"
exec > >(tee -a "$LEDGER_LOG") 2>&1

# Canonical agent definition lives at the ledger playbook path
# (mirrored from the live .claude/agents/ at LEDGER-0002 creation time).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPT_DIR/agent-definition.md"
USER_AGENTS_DIR="$HOME/.claude/agents"
DEST="$USER_AGENTS_DIR/workflow-debugger.md"

# ───── colors + helpers (canonical yousirjuan set) ─────
BLUE='\033[1;34m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; RED='\033[1;31m'; DIM='\033[2m'; NC='\033[0m'
step() { printf "${BLUE}→ %s${NC}\n" "$*"; }
note() { printf "${DIM}  %s${NC}\n" "$*"; }
ok()   { printf "${GREEN}  ✓ %s${NC}\n" "$*"; }
warn() { printf "${YELLOW}  ⚠ %s${NC}\n" "$*"; }
die()  { printf "${RED}  ✗ %s${NC}\n" "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

action_install() {
  step "Promoting workflow-debugger to user scope ($DEST)"
  [[ -f "$SRC" ]] || die "Source not found: $SRC"
  mkdir -p "$USER_AGENTS_DIR"
  if [[ -f "$DEST" ]] && cmp -s "$SRC" "$DEST"; then
    ok "already installed and identical, skipping"
    return 0
  fi
  cp "$SRC" "$DEST"
  ok "installed at $DEST"
  note "Available in any Claude Code session on this machine."
  note "The project-scope copy at .claude/agents/ is also still loaded for"
  note "sessions inside this repo. Project scope wins on conflict."
}

action_uninstall() {
  step "Removing user-scope copy"
  if [[ -f "$DEST" ]]; then
    rm "$DEST"
    ok "removed $DEST"
    note "Project-scope copy at .claude/agents/ is unaffected."
  else
    note "$DEST does not exist, nothing to remove"
  fi
}

action_status() {
  echo "── canonical source (this ledger entry) ─────────"
  if [[ -f "$SRC" ]]; then echo "✓ $SRC"; else echo "✗ missing"; fi
  echo "── project-scope copy (loaded inside this repo) ──"
  PROJECT_DEST="$(cd "$SCRIPT_DIR/../../.." && pwd)/.claude/agents/workflow-debugger.md"
  if [[ -f "$PROJECT_DEST" ]]; then echo "✓ $PROJECT_DEST"; else echo "✗ missing"; fi
  echo "── user-scope copy (loaded in any session) ───────"
  if [[ -f "$DEST" ]]; then echo "✓ $DEST"; else echo "✗ not installed"; fi
  echo "── divergence check ─────────────────────────────"
  if [[ -f "$DEST" && -f "$SRC" ]]; then
    if cmp -s "$SRC" "$DEST"; then
      echo "✓ user-scope copy matches canonical"
    else
      warn "user-scope copy diverges from canonical — diff:"
      diff "$SRC" "$DEST" | head -20 || true
    fi
  fi
}

action_help() {
  cat <<EOF
Usage: $0 <action>

Actions:
  install    copy the agent definition to ~/.claude/agents/ (user scope)
  uninstall  remove the user-scope copy
  status     show what's installed where, and whether copies diverge

Files:
  source:        $SRC
  user-scope:    $DEST
  project-scope: (auto-loaded from .claude/agents/ inside this repo)

Logs: $LEDGER_LOG
EOF
}

case "${1:-install}" in
  install)   action_install ;;
  uninstall) action_uninstall ;;
  status)    action_status ;;
  help|-h|--help) action_help ;;
  *) echo "Unknown action: $1" >&2; action_help; exit 1 ;;
esac
