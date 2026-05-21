#!/usr/bin/env bash
# intent-aware-unmask.sh — one-step "I really do want to start this protected
# service" command. Combines intent.sh remove + systemctl unmask + start.
#
# Per LEDGER-0020 Layer C. Makes the right path frictionless so the operator
# doesn't have to remember the 2-step protocol every time.
#
# Usage:
#   sudo bash intent-aware-unmask.sh <unit>
#
# What it does (atomic):
#   1. Looks up which intent topic protects this unit (via intent-unit-map.json)
#   2. If an intent file for that topic exists: intent.sh remove <topic>
#      (which unmasks the unit + deletes the file)
#   3. If no intent file: systemctl unmask (in case mask was applied without intent)
#   4. systemctl start <unit>
#   5. systemctl is-active confirmation

set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "must run as root (sudo)"; exit 1; }

UNIT="${1:-}"
[[ -n "$UNIT" ]] || { echo "usage: sudo bash $0 <unit>"; exit 1; }

MAP_FILE="/etc/yousirjuan/intent-unit-map.json"
INTENT_PLAYBOOK="$(dirname "$0")/../../LEDGER-0014-operator-intent-protocol/playbooks/intent.sh"

BLUE='\033[1;34m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; RED='\033[1;31m'; NC='\033[0m'
step() { printf "${BLUE}→ %s${NC}\n" "$*"; }
ok()   { printf "${GREEN}✓ %s${NC}\n" "$*"; }
warn() { printf "${YELLOW}⚠ %s${NC}\n" "$*"; }
die()  { printf "${RED}✗ %s${NC}\n" "$*" >&2; exit 1; }

step "intent-aware-unmask: $UNIT"

# Look up topic
TOPIC=""
if [[ -f "$MAP_FILE" ]]; then
  TOPIC=$(python3 -c "
import json
m = json.load(open('$MAP_FILE'))
print(m.get('$UNIT', {}).get('topic', ''))
" 2>/dev/null)
fi

if [[ -n "$TOPIC" ]] && [[ -f "/etc/yousirjuan/operator-intent.d/${TOPIC}.md" ]]; then
  step "  removing intent '$TOPIC' (unmasks + deletes file)"
  if [[ -x "$INTENT_PLAYBOOK" ]]; then
    bash "$INTENT_PLAYBOOK" remove "$TOPIC"
  else
    # Fallback: do it manually
    systemctl unmask "$UNIT" 2>&1 | head -3
    rm -f "/etc/yousirjuan/operator-intent.d/${TOPIC}.md"
    ok "  removed intent file"
  fi
else
  step "  no intent file to remove; just unmasking + starting"
  systemctl unmask "$UNIT" 2>&1 | head -3 || true
fi

step "  systemctl start $UNIT"
systemctl start "$UNIT"
sleep 2

if systemctl is-active --quiet "$UNIT"; then
  ok "$UNIT is active"
else
  warn "$UNIT did not become active — journalctl -u $UNIT -n 30"
fi

step "Done. Reminder: if you want this to NOT auto-start on reboot:"
echo "      sudo systemctl disable $UNIT"
echo "      sudo bash $INTENT_PLAYBOOK add ${TOPIC:-<topic>} \"<desc>\" \"<why>\" --mask-service $UNIT"
