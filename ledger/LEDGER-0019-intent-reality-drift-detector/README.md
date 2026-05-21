---
ledgerId: LEDGER-0019
title: Intent-Reality Drift Detector — flag when operator-intent files diverge from actual state
status: in-progress
opened: 2026-05-21
closed: null
related-tickets: [LEDGER-0014, LEDGER-0015]
triggers:
  - systemd:yousirjuan-intent-drift.timer (every 5 min on VPS)
---

# LEDGER-0019 — Intent-Reality Drift Detector

## Ask

On 2026-05-21 the operator (Avery) accidentally created intent-vs-reality drift: ran `sudo systemctl unmask + start n8n-nephew.service` at 04:39 UTC for a workflow he needed, did NOT remove the corresponding `n8n-stopped.md` intent file via the LEDGER-0014 `intent.sh remove` protocol. The intent file kept claiming n8n was stopped while it was actually running, with rising memory pressure.

Forensic check (auth.log) confirmed it was the operator's own deliberate action — the Rule 13 protocol DID work (the mask blocked the first `systemctl start`, forcing him to consciously `unmask` first). What it didn't have was a way to **detect afterward** that intent + reality had diverged.

Operator: *"Yes — ship Rule 16: Intent-Reality Drift Detector."*

## Outcome

Systemd timer every 5 min on the VPS runs a checker that:

1. Reads every `/etc/yousirjuan/operator-intent.d/*.md` file
2. For each, looks for an optional `## Drift check` section with `check_cmd:` and `match_output:` fields
3. If absent, falls back to a built-in heuristic by topic name
4. Compares actual state against expected; logs to `/var/log/yousirjuan-intent-drift.log`
5. Writes a JSON report to `/var/lib/yousirjuan/intent-drift-report.json` (consumable by Nephew/DustPan)
6. Exit code 0 if no drift, 1 if any drift detected (so `systemctl status timer` shows red)

Future Phase 2: alert-watch (LEDGER-0015) extension that polls the report and pushes a macOS notification when drift first appears.

## Playbooks

- [intent-drift-check.sh](playbooks/intent-drift-check.sh) — the checker. Pure bash + python3. Heuristics built in for known intent topics (n8n-stopped, gitlab-stopped, github-actions-runner-stopped, swap-doubled-to-8gb, sshd-oom-protected, clinic-systemd-managed); operator can extend via `## Drift check` section in any intent file.
- [install-intent-drift.sh](playbooks/install-intent-drift.sh) — install/uninstall/status. Installs as systemd timer (OnUnitActiveSec=5min).

## Built-in heuristics (current intent files)

| Intent topic | Check | Expected |
|---|---|---|
| `n8n-stopped` | `systemctl is-active n8n-nephew.service` | inactive \| failed |
| `gitlab-stopped` | docker inspect `gitlab` state | exited \| missing |
| `github-actions-runner-stopped` | systemctl is-active runner service | inactive \| failed |
| `clinic-systemd-managed` | systemctl is-active clinic.service | active |
| `swap-doubled-to-8gb` | `/proc/meminfo SwapTotal ≥ 8 GB` | match |
| `sshd-oom-protected` | `/proc/<sshd-pid>/oom_score_adj` | -1000 |

## Operator-extensible per-intent check spec

Add to any intent file:

```markdown
## Drift check
check_cmd: systemctl is-active my-service.service
match_output: inactive|failed
```

The detector parses this, runs the cmd, accepts a pipe-separated alternation in match_output. If the live output starts with any alternative, no drift.

## Universal Rule 16 (separately shipped in this PR)

`rules/GLOBAL-RULES-FOR-USING-NEPHEW.md` Rule 16 + `.claude/rules/intent-reality-drift.md` mirror codify the operator's directive:

- Every operator-intent file MUST be paired with a drift check
- The check runs every 5 min
- Drift triggers a notification (Phase 2)
- The "remove intent" step is part of the workflow when intent is intentionally reverted (not optional)

## Replay

```bash
ssh vps-godaddy 'cd ~/Developer/yousirjuan && git pull && \
  sudo bash ledger/LEDGER-0019-intent-reality-drift-detector/playbooks/install-intent-drift.sh install'
```

## Verification

```bash
ssh vps-godaddy 'sudo bash ~/Developer/yousirjuan/ledger/LEDGER-0019-intent-reality-drift-detector/playbooks/install-intent-drift.sh status'
# expected: timer active + recent log showing all current intent files ✓
ssh vps-godaddy 'cat /var/lib/yousirjuan/intent-drift-report.json | python3 -m json.tool'
# expected: drift_count: 0 if all intents truthful
```

## Undo

```bash
ssh vps-godaddy 'sudo bash <repo>/ledger/LEDGER-0019-intent-reality-drift-detector/playbooks/install-intent-drift.sh uninstall'
```

## Cross-references

- LEDGER-0014 — operator-intent protocol (the layer this audits)
- LEDGER-0015 — server-tamer + alert-watch (Phase 2 plumbing for drift notifications)
- Rule 13 — "leave loud notes" — drift detector is the verifier-of-truth for that rule
- Rule 16 (NEW in this PR) — drift detection becomes binding
