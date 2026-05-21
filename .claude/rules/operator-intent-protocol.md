# Operator-intent protocol — read intent files before "fixing" anything on the VPS

This is a binding rule for every agent that lands in this repo. It exists because a real incident happened (2026-05-21): one agent stopped a service for a sound reason, recorded the decision in a PR description only, and the next agent helpfully restarted what looked broken. The operator paid the price.

The fix lives in [`ledger/LEDGER-0014-operator-intent-protocol/`](../../ledger/LEDGER-0014-operator-intent-protocol/). This rule is the agent-side enforcement.

---

## Before "fixing" anything on the VPS

If you observe a service / container / port / mount / process that looks **stopped, disabled, masked, removed, missing, or unhealthy** on `vps-godaddy` (or any operator host), do this FIRST:

```bash
ssh vps-godaddy 'ls /etc/yousirjuan/operator-intent.d/ 2>/dev/null && \
                 cat /etc/yousirjuan/operator-intent.d/*.md 2>/dev/null'
```

If any file mentions the topic you're about to touch:

1. **STOP.** Do not restart, unstop, unmask, reinstall, recreate, or "fix" it.
2. Quote the relevant intent file to the operator and ask explicitly: *"I see this is intentionally stopped per intent file `<topic>`. Do you want me to revert it?"*
3. Wait for explicit yes before acting.

---

## After making any deliberate state change of your own

Any time you do one of the below on a host that has the intent protocol installed:

- `systemctl stop|disable|mask <unit>`
- `docker stop` + `docker update --restart=no` (or `docker rm`)
- `pkill -f <pattern>` (where the process would otherwise auto-restart or be re-started)
- `iptables` rule blocking a port that would otherwise be reachable
- `nginx` removing or pointing-away a vhost
- Anything that an unrelated agent could reasonably interpret as "this looks broken, let me fix it"

You must, **in the same session**:

```bash
ssh vps-godaddy 'sudo bash ~/Developer/yousirjuan/ledger/LEDGER-0014-operator-intent-protocol/playbooks/intent.sh \
  add <topic-slug> "<short description>" "<why — link to the LEDGER / runbook>" \
  [--mask-service <unit>]'
```

The intent file is part of your deliverable. Not a follow-up. Not "I'll write it after the PR merges." **In the same session.**

---

## How to know the intent file actually landed

The MOTD hook (`/etc/update-motd.d/99-yousirjuan-intent`) dumps every active intent file on every SSH login. After `intent.sh add ...`, **reconnect via SSH** to confirm your intent shows up in the banner. That's the proof the next agent will see it.

```bash
ssh vps-godaddy 'echo --- intent banner test ---' | head -30
```

---

## When to remove an intent

When the operator decides the state change should be reverted, run **the script's remove action** rather than just starting the service:

```bash
ssh vps-godaddy 'sudo bash <repo>/ledger/LEDGER-0014-operator-intent-protocol/playbooks/intent.sh remove <topic>'
```

This unmasks the systemd unit (if any) AND removes the intent file. THEN start the service. Doing it in the other order leaves a masked unit + a confusing "started something that says it shouldn't be" state.

---

## Concrete examples

### Right

> Operator: "stop n8n; it's the OOM trigger from runbook 05."
>
> Agent:
> 1. `ssh vps-godaddy 'sudo systemctl stop n8n-nephew.service && sudo systemctl disable n8n-nephew.service'`
> 2. **Same session:** `ssh vps-godaddy 'sudo bash …/intent.sh add n8n-stopped "n8n stopped + disabled + masked" "OOM trigger per LEDGER-0007 runbook 05; migrate to LEDGER-0010 sandbox before restart" --mask-service n8n-nephew.service'`
> 3. Reconnects via SSH; confirms MOTD shows the n8n-stopped banner.
> 4. PR description mentions the intent file path, not just the systemctl command.

### Wrong (what happened today before this rule existed)

> Agent stops n8n via SSH. Records the why in a PR description. Closes session.
> Next agent SSHes in, sees n8n stopped, no MOTD banner, no `/etc/yousirjuan/operator-intent.d/` (didn't exist yet), and helpfully `systemctl start`s it.

That's the exact failure mode this rule prevents.

---

## Cross-references

- [LEDGER-0014](../../ledger/LEDGER-0014-operator-intent-protocol/) — the playbook + MOTD hook + concrete instances
- [`.claude/rules/contracts-and-prudence.md`](contracts-and-prudence.md) — the underlying operating philosophy: visible contracts maintain good; invisible contracts get broken
- [`.claude/rules/ledger-discipline.md`](ledger-discipline.md) — the broader principle that decisions become artifacts, not chat history
