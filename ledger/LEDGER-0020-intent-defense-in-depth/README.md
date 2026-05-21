---
ledgerId: LEDGER-0020
title: Intent defense in depth — close the intent-reality drift gap with 4 layers (A+B+C+D)
status: in-progress
opened: 2026-05-21
related-tickets: [LEDGER-0014, LEDGER-0015, LEDGER-0019]
triggers:
  - systemd:ExecStartPre per protected unit (Layer B)
  - manual-cli:intent-aware-unmask.sh (Layer C)
  - launchd:alert-watch (Layer A) — extended in LEDGER-0015
  - systemd:intent-drift timer (Layer D auto-heal) — extended in LEDGER-0019
---

# LEDGER-0020 — Intent defense in depth

## Ask

Operator 2026-05-21 after the n8n drift incident: *"How do you suggest we fix close that gap so that we have no drift in the future"* — followed by *"All four (A+B+C+D) — maximum defense."*

LEDGER-0014 + Rule 13 stop **careless** restarts. LEDGER-0019 + Rule 16 **detect drift** after the fact (within 5 min). What was missing: layers that make creating drift in the first place harder.

## Four layers shipped (full defense)

### Layer A — Real-time alert (extends LEDGER-0015 alert-watch on iMac)

`alert-watch.sh` (iMac launchd) now ALSO polls the VPS drift report each tick. When any drift is detected, fires a macOS osascript notification:

```
🟣 Intent-reality drift
3 file(s): n8n-stopped, gitlab-stopped, ...
Run intent.sh remove <topic> OR fix the actual state.
```

Debounced 5 min per the existing alert-watch debounce so no spam.

### Layer B — systemd ExecStartPre hook (prevention)

`check-intent-before-start.sh` lives in `/usr/local/lib/yousirjuan/` and is invoked as `ExecStartPre=` by each protected unit's drop-in at `/etc/systemd/system/<unit>.d/50-yousirjuan-intent-check.conf`.

Behavior:
1. Read `/etc/yousirjuan/intent-unit-map.json` to map unit name → intent topic
2. If a corresponding intent file exists AND claims `expected_state: stopped` → **fail the start with REFUSED message in journal**
3. Otherwise → allow start

This **survives `systemctl unmask`** because the drop-in is separate from the mask. Even if the mask is gone, the ExecStartPre still runs.

The error the operator sees in journal:
```
yousirjuan-intent-check[1234]: REFUSED: intent file /etc/yousirjuan/operator-intent.d/n8n-stopped.md says 'stopped'.
Run: sudo bash <repo>/ledger/LEDGER-0014-operator-intent-protocol/playbooks/intent.sh remove n8n-stopped
```

### Layer C — `intent-aware-unmask.sh` (frictionless right path)

One command to legitimately override an intent:

```bash
sudo bash /usr/local/lib/yousirjuan/intent-aware-unmask.sh n8n-nephew.service
```

That atomically:
1. Looks up the intent topic from the unit map
2. Runs `intent.sh remove <topic>` (which unmasks + deletes the intent file)
3. `systemctl start <unit>`
4. Confirms `is-active`

So the operator doesn't have to remember the 2-step protocol every time. The "right way" is one command.

### Layer D — Optional auto-heal (drift detector extension)

Per-intent opt-in via the `## Drift check` section:

```markdown
## Drift check
check_cmd: systemctl is-active n8n-nephew.service
match_output: inactive|failed
auto_heal: stop
```

When drift is detected AND the intent file specifies `auto_heal: stop`, the LEDGER-0019 drift checker (running every 5 min) automatically:
- For systemd units (looked up in intent-unit-map.json): `systemctl stop <unit>`
- For `gitlab-stopped`: `docker stop gitlab gitlab-runner`
- For unknown topics: logs but takes no action (safe default)

**Auto-heal is OFF by default per intent.** Opt in only when you're SURE the intent is the source of truth (e.g. n8n must never come back without operator decision).

## Playbooks

- [check-intent-before-start.sh](playbooks/check-intent-before-start.sh) — Layer B ExecStartPre hook
- [intent-aware-unmask.sh](playbooks/intent-aware-unmask.sh) — Layer C wrapper
- [install.sh](playbooks/install.sh) — installs Layer B + C on VPS, lays down drop-ins for units in the map

## Artifacts

- [intent-unit-map.json](artifacts/intent-unit-map.json) — unit ↔ topic mapping (operator-editable; default has n8n-nephew + github-actions-runner)

## Edits to existing playbooks (shipped in this PR)

- `ledger/LEDGER-0015-server-stability-suite/playbooks/alert-watch.sh` — added Layer A drift polling block
- `ledger/LEDGER-0019-intent-reality-drift-detector/playbooks/intent-drift-check.sh` — added Layer D auto-heal block

## Replay

```bash
ssh vps-godaddy 'cd ~/Developer/yousirjuan && git pull && \
  sudo bash ledger/LEDGER-0020-intent-defense-in-depth/playbooks/install.sh install'

# iMac: alert-watch already running; the LEDGER-0015 edit just adds drift to its checks
bash /Users/averygoodman/Developer/yousirjuan/ledger/LEDGER-0015-server-stability-suite/playbooks/install-alert-watch.sh install
```

## Verify each layer

```bash
# Layer A test: trigger drift, watch for macOS notification
ssh vps-godaddy 'echo "_test" | sudo tee /etc/yousirjuan/operator-intent.d/test-drift.md'
# Wait 60-90s → macOS notification should appear

# Layer B test: try starting a unit with an active intent
ssh vps-godaddy 'sudo bash <repo>/ledger/LEDGER-0014-operator-intent-protocol/playbooks/intent.sh add n8n-stopped "test" "test" --mask-service n8n-nephew.service'
ssh vps-godaddy 'sudo systemctl unmask n8n-nephew.service && sudo systemctl start n8n-nephew.service'
# → should fail with REFUSED in journal

# Layer C test: use the wrapper
ssh vps-godaddy 'sudo bash /usr/local/lib/yousirjuan/intent-aware-unmask.sh n8n-nephew.service'
# → atomically removes intent + unmasks + starts

# Layer D test: add auto_heal: stop to an intent file, force a drift, watch drift checker auto-stop
```

## Undo

```bash
ssh vps-godaddy 'sudo bash ledger/LEDGER-0020-intent-defense-in-depth/playbooks/install.sh uninstall'
```

Removes drop-ins + scripts. Intent unit map preserved.

## What this DOESN'T fix

- Operator with sudo can still `systemctl edit <unit>` and remove the drop-in. The defense is depth + friction, not absolute.
- Auto-heal could undo legitimate operator work if enabled too broadly. Default OFF.
- The wrapper assumes the unit-map covers every protected unit; new units need a map entry to get prevention.

## Cross-references

- Rule 13 / LEDGER-0014 — the operator-intent protocol this defends
- Rule 16 / LEDGER-0019 — the drift detector this complements (and Layer D extends)
- Rule 17 (NEW in this PR) — defense-in-depth becomes binding
