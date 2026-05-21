---
ledgerId: LEDGER-0014
title: Operator-intent protocol — loud cross-agent ops notes so the next agent doesn't undo your work
status: in-progress
opened: 2026-05-21
closed: null
related-pains: []
related-tickets: [LEDGER-0007, LEDGER-0012, LEDGER-0013]
triggers:
  - manual-cli: `sudo bash ledger/LEDGER-0014-operator-intent-protocol/playbooks/intent.sh add <topic>`
  - ssh-login: MOTD hook dumps every active intent file (/etc/update-motd.d/99-yousirjuan-intent)
  - http-fetch: GET /operator-intent on LEDGER-0012 agent (future PR)
---

# LEDGER-0014 — Operator-intent protocol

## Ask (the failure that motivated this)

> "another agent reinstalled it because you did not leave healthy notes on what you did to play-well with others."

The 2026-05-20 session stopped n8n via SSH because n8n's `npm install` was the OOM cascade trigger (LEDGER-0007 runbook 05). The decision was recorded in a PR description — invisible to any agent landing on the host after the fact. The next day, **another agent saw a stopped service and helpfully restarted it.** Result: the OOM trigger came back online unannounced.

The contract existed only in human-readable git history. Not where the next agent (or future-you, or a teammate) would look.

## Outcome

Three layers, so the intent CANNOT be missed:

### 1. Intent file on the host

`/etc/yousirjuan/operator-intent.d/<topic>.md` — one file per deliberate-state-change. Each starts with a loud first line:

```
**STOP. DO NOT just restart this if you see it stopped/disabled/masked.**
This is a deliberate operator decision. Read the why below, then ask before changing.
```

Followed by structured fields: what, when, who set it, why, how to revert the right way.

### 2. MOTD hook

`/etc/update-motd.d/99-yousirjuan-intent` — every SSH login dumps all active intent files (first 12 lines each, colored red header) before the shell prompt appears. No agent gets a `$` without seeing them.

### 3. `systemctl mask` enforcement

For intents that protect a systemd service, the script also `systemctl mask`s the unit. A careless `systemctl start n8n-nephew.service` then fails with `Failed to start n8n-nephew.service: Unit n8n-nephew.service is masked`. Forcing past it requires `systemctl unmask` — a deliberate, visible operator action.

## Runbooks

- `01-the-n8n-recurrence-story.md` — the small postmortem of why this ledger entry exists
- `02-when-to-write-an-intent.md` — guidelines: any time you `systemctl stop|disable`, `docker stop`, `pkill`, or `iptables`-block a thing that another agent might reasonably try to "fix"
- `03-applying-on-fresh-vps.md` — install the MOTD hook + write initial intent files on a fresh box

## Playbooks

- `intent.sh` — the lifecycle script: `add`, `remove`, `list`. Idempotent. Installs the MOTD hook on first `add`.

## Initial intent files to apply (today)

Catching up the operator-intent backlog from prior session-only-recorded decisions:

| Topic | What it documents |
|---|---|
| `n8n-stopped` | n8n-nephew.service stopped + disabled + masked (LEDGER-0007 runbook 05) |
| `gitlab-stopped` | gitlab + gitlab-runner Docker containers stopped + restart-policy `no` |
| `github-actions-runner-stopped` | self-hosted runner systemd unit stopped + disabled |
| `clinic-systemd-managed` | clinic.service runs The Clinic; don't bypass via direct `python server.py` |
| `swap-doubled-to-8gb` | /swapfile resized; do NOT shrink without re-checking memory budget |
| `sshd-oom-protected` | systemd drop-in pins OOMScoreAdjust=-1000; do NOT remove |

These will be created on the VPS via `intent.sh add ...` in the next session step.

## Repo-side rule

This LEDGER also ships `.claude/rules/operator-intent-protocol.md` so every agent landing in the yousirjuan repo learns to:

1. Check `ssh vps-godaddy 'ls /etc/yousirjuan/operator-intent.d/'` before changing anything on the VPS
2. If the topic of work matches an existing intent, ask the operator before proceeding
3. After making any deliberate-state-change of their own, run `intent.sh add ...` in the same session, not as a follow-up

## Replay (zero-AI)

```bash
ssh vps-godaddy 'cd ~/Developer/yousirjuan && git pull && \
  sudo bash ledger/LEDGER-0014-operator-intent-protocol/playbooks/intent.sh list'
```

## Verification

```bash
# On VPS:
ls /etc/yousirjuan/operator-intent.d/
sudo bash playbooks/intent.sh list
# Disconnect + SSH back in → see the MOTD dump
# Try: sudo systemctl start n8n-nephew.service → should fail "Unit is masked"
```

## Undo (per intent)

```bash
ssh vps-godaddy 'sudo bash <repo>/ledger/LEDGER-0014-operator-intent-protocol/playbooks/intent.sh remove <topic>'
```

(Unmasks the systemd unit if any, removes the file. THEN start the service manually if you actually want it back.)

## Future Phase 2

Add `GET /operator-intent` endpoint to the LEDGER-0012 VPS agent so DustPan + Nephew Control Tower surface the same intent files in the UI, not just at SSH login.

## Cross-references

- LEDGER-0007 runbook 05 — the OOM event that motivated stopping n8n
- LEDGER-0012 — agent that should surface intents to UI clients in Phase 2
- LEDGER-0013 — companion pattern (the `audit-vhost-upstreams.sh` catches misconfigs; this catches "agent undid my deliberate change")
- ADR-0001 — the contracts-and-prudence framing
