#!/usr/bin/env bash
# intent.sh — write a loud operator-intent note that the next agent on this
# host (or you next week) cannot miss.
#
# Per LEDGER-0014. The problem this solves: today (2026-05-21) an agent
# stopped n8n via SSH, recorded the decision only in a PR description, and
# another agent landing on the box later helpfully "fixed" what looked
# broken. The contract existed only in human-readable git history — not
# where the next operator would look.
#
# This script creates a markdown file at
# /etc/yousirjuan/operator-intent.d/<topic>.md that is:
#   1. Visible to anyone via `ls /etc/yousirjuan/operator-intent.d/`
#   2. Dumped on every SSH login via the MOTD hook
#       (/etc/update-motd.d/99-yousirjuan-intent)
#   3. Exposed at GET /operator-intent on the LEDGER-0012 VPS agent
#       (so DustPan + Nephew Control Tower can show it)
#
# Usage:
#   sudo bash intent.sh add <topic> "<short description>" "<why>" \
#       [--mask-service <unit>]
#
#   sudo bash intent.sh remove <topic>
#   sudo bash intent.sh list

set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "must run as root (sudo)"; exit 1; }

INTENT_DIR="/etc/yousirjuan/operator-intent.d"
MOTD_HOOK="/etc/update-motd.d/99-yousirjuan-intent"
mkdir -p "$INTENT_DIR"
chmod 755 "$INTENT_DIR"

BLUE='\033[1;34m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; RED='\033[1;31m'; NC='\033[0m'
step() { printf "${BLUE}→ %s${NC}\n" "$*"; }
ok()   { printf "${GREEN}✓ %s${NC}\n" "$*"; }
warn() { printf "${YELLOW}⚠ %s${NC}\n" "$*"; }
die()  { printf "${RED}✗ %s${NC}\n" "$*" >&2; exit 1; }

ensure_motd_hook() {
  if [[ -f "$MOTD_HOOK" ]]; then return; fi
  step "Installing MOTD hook at $MOTD_HOOK"
  cat > "$MOTD_HOOK" <<'EOF'
#!/usr/bin/env bash
# Yousirjuan operator-intent MOTD hook — LEDGER-0014.
# Dumps every active operator-intent file at SSH login.
INTENT_DIR="/etc/yousirjuan/operator-intent.d"
if [[ -d "$INTENT_DIR" ]] && compgen -G "$INTENT_DIR/*.md" >/dev/null; then
  printf '\033[1;31m'
  printf '═══════════════════════════════════════════════════════════════════════\n'
  printf '  YOUSIRJUAN OPERATOR INTENT — read before changing anything on this host\n'
  printf '═══════════════════════════════════════════════════════════════════════\n'
  printf '\033[0m'
  for f in "$INTENT_DIR"/*.md; do
    printf '\n\033[1;33m── %s ──\033[0m\n' "$(basename "$f" .md)"
    sed -n '1,12p' "$f"
  done
  printf '\n\033[2m  Full files: ls %s\033[0m\n' "$INTENT_DIR"
  printf '\033[2m  Manage:     sudo bash <repo>/ledger/LEDGER-0014-operator-intent-protocol/playbooks/intent.sh\033[0m\n\n'
fi
EOF
  chmod 755 "$MOTD_HOOK"
  ok "MOTD hook installed"
}

action_add() {
  local topic="$1"
  local desc="$2"
  local why="$3"
  shift 3 || true
  local mask_service=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --mask-service) mask_service="$2"; shift 2;;
      *) die "unknown arg: $1";;
    esac
  done

  [[ "$topic" =~ ^[a-z0-9-]+$ ]] || die "topic must match [a-z0-9-]+ (got: $topic)"
  local f="$INTENT_DIR/${topic}.md"

  ensure_motd_hook

  step "Writing intent: $topic"
  cat > "$f" <<EOF
**STOP. DO NOT just restart this if you see it stopped/disabled/masked.**
This is a deliberate operator decision. Read the why below, then ask before changing.

- **Topic:** ${topic}
- **What:** ${desc}
- **When:** $(date -Iseconds)
- **Set by:** ${SUDO_USER:-${USER:-root}} (via ${0##*/})
- **Host:** $(hostname)

## Why

${why}

## How to revert (the right way)

\`\`\`
sudo bash $0 remove ${topic}
\`\`\`

(That removes the intent file and unmasks the service if any. THEN start the service manually if appropriate.)

EOF

  if [[ -n "$mask_service" ]]; then
    cat >> "$f" <<EOF
## systemd-masked

This intent also masks the systemd unit \`${mask_service}\` so a careless \`systemctl start\` will fail with \"Unit is masked.\" Forcing past this requires deliberate operator action — exactly the point.
EOF
    systemctl mask "$mask_service" 2>&1 | sed 's/^/  /'
    ok "masked $mask_service"
  fi

  chmod 644 "$f"
  ok "wrote $f"
}

action_remove() {
  local topic="$1"
  local f="$INTENT_DIR/${topic}.md"
  [[ -f "$f" ]] || die "no intent file for topic '$topic'"

  # Find any masked service mentioned and unmask it.
  if grep -q "^This intent also masks the systemd unit" "$f"; then
    local unit
    unit=$(grep -oE "\`[^\`]+\.service\`" "$f" | head -1 | tr -d '`')
    if [[ -n "$unit" ]]; then
      step "Unmasking $unit"
      systemctl unmask "$unit" 2>&1 | sed 's/^/  /'
    fi
  fi

  rm -f "$f"
  ok "removed $f"
}

action_list() {
  if ! compgen -G "$INTENT_DIR/*.md" >/dev/null; then
    echo "(no active operator-intent files in $INTENT_DIR)"
    return
  fi
  for f in "$INTENT_DIR"/*.md; do
    printf "${BLUE}── %s ──${NC}\n" "$(basename "$f" .md)"
    sed -n '1,8p' "$f"
    echo
  done
}

case "${1:-help}" in
  add)    shift; [[ $# -ge 3 ]] || die "usage: intent.sh add <topic> <desc> <why> [--mask-service <unit>]"; action_add "$@";;
  remove) shift; [[ $# -ge 1 ]] || die "usage: intent.sh remove <topic>"; action_remove "$@";;
  list)   action_list;;
  *) cat <<EOF
Usage:
  sudo bash $0 add <topic> "<desc>" "<why>" [--mask-service <unit>]
  sudo bash $0 remove <topic>
  sudo bash $0 list

Examples:
  sudo bash $0 add n8n-stopped \\
    "n8n-nephew.service stopped + disabled + masked" \\
    "OOM trigger today — runbook 05; move to LEDGER-0010 sandbox before restart" \\
    --mask-service n8n-nephew.service
EOF
;;
esac
