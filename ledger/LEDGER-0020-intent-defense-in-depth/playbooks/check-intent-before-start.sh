#!/usr/bin/env bash
# check-intent-before-start.sh — ExecStartPre hook that refuses to let a
# systemd unit start if an operator-intent file says it should be stopped.
#
# Per LEDGER-0020 Layer B. The systemd mask (LEDGER-0014) protects against
# accidental `systemctl start`. But `systemctl unmask` removes the mask;
# the next start succeeds with no further check. This hook lives in a
# drop-in that SURVIVES unmask — making the prevention persistent.
#
# Drop-in (operator installs per-unit via install-intent-drop-ins.sh):
#   /etc/systemd/system/<unit>.d/50-yousirjuan-intent-check.conf
#   [Service]
#   ExecStartPre=/usr/local/lib/yousirjuan/check-intent-before-start.sh %n
#
# Behavior:
#   - Maps unit name → expected intent topic via the JSON map at
#     /etc/yousirjuan/intent-unit-map.json (operator-editable)
#   - If the intent file exists AND claims this unit should be stopped → exit 1
#     (systemd then aborts the start with the message in its journal)
#   - Otherwise → exit 0 (start proceeds)
#
# The error message systemd shows when ExecStartPre exits non-zero:
#   "Failed to start <unit>: Process exited with code 1"
# We write a clearer message to journal via systemd-cat first so the operator
# sees WHY immediately in journalctl.

set -uo pipefail

UNIT="${1:-}"
MAP_FILE="/etc/yousirjuan/intent-unit-map.json"
INTENT_DIR="/etc/yousirjuan/operator-intent.d"

[[ -n "$UNIT" ]] || { echo "usage: $0 <unit>" >&2; exit 0; }

# No map → no protection (allow start)
[[ -f "$MAP_FILE" ]] || exit 0

# Look up unit → intent topic
TOPIC=$(python3 -c "
import json, sys
try:
    m = json.load(open('$MAP_FILE'))
    print(m.get('$UNIT', {}).get('topic', ''))
except Exception:
    pass
" 2>/dev/null)

# No mapping for this unit → no protection
[[ -n "$TOPIC" ]] || exit 0

# Look for the intent file
INTENT_FILE="$INTENT_DIR/${TOPIC}.md"
if [[ ! -f "$INTENT_FILE" ]]; then
  # Intent file removed → operator deliberately reverted the intent → allow start
  exit 0
fi

# Intent file exists; what does it claim?
EXPECTED=$(python3 -c "
import json, sys
m = json.load(open('$MAP_FILE'))
print(m.get('$UNIT', {}).get('expected_state', 'stopped'))
" 2>/dev/null)

if [[ "$EXPECTED" == "stopped" ]]; then
  # Yell into the journal so the operator sees this immediately:
  printf "REFUSED: intent file %s says '$EXPECTED'. Run: sudo bash <repo>/ledger/LEDGER-0014-operator-intent-protocol/playbooks/intent.sh remove %s\n" \
    "$INTENT_FILE" "$TOPIC" | systemd-cat -t yousirjuan-intent-check -p err
  exit 1
fi

exit 0
