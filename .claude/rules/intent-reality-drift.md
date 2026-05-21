# Intent-Reality Drift — every operator-intent file must be periodically verified against reality

Binding rule for every agent operating in this repo. Mirrors **Universal Rule 16** in [`rules/GLOBAL-RULES-FOR-USING-NEPHEW.md`](../../rules/GLOBAL-RULES-FOR-USING-NEPHEW.md). Both must stay in sync.

---

## The contract

Every operator-intent file under `/etc/yousirjuan/operator-intent.d/` MUST be paired with an automated drift check that compares the intent's claim against actual system state at least every 5 minutes. If the file says "X is stopped" but X is actually running (or vice versa), the system surfaces that drift via log + JSON report + (Phase 2) notification.

## Why

Rule 13 + LEDGER-0014 stop **careless** restarts (the `systemctl mask` forces deliberate `unmask` first). But the protocol can be **silently overridden** by an operator with sudo who's in a hurry. Rule 16 catches the drift after the fact — turning "invisible silent override" into "visible logged drift."

## How to write a new intent file with drift check

`intent.sh add ...` accepts an optional `## Drift check` section. Write it in the natural language of the file then append the structured block:

```markdown
## Drift check
check_cmd: systemctl is-active my-service.service
match_output: inactive|failed
```

The detector parses `check_cmd:` (single line, executed in a shell) and `match_output:` (pipe-separated alternatives; if actual output starts with any, no drift).

If you don't add the block, the script falls back to a built-in heuristic table keyed by topic name. Built-in coverage: `n8n-stopped`, `gitlab-stopped`, `github-actions-runner-stopped`, `clinic-systemd-managed`, `swap-doubled-to-8gb`, `sshd-oom-protected`.

## When you need to override an intent (the right way)

```bash
# 1. Remove the intent FIRST — this unmasks the systemd unit + deletes the file
sudo bash <repo>/ledger/LEDGER-0014-operator-intent-protocol/playbooks/intent.sh remove <topic>

# 2. Then make the operational change
sudo systemctl start <unit>
```

NOT:

```bash
# WRONG ORDER — leaves the intent file lying about state
sudo systemctl unmask <unit>
sudo systemctl start <unit>
# Rule 16 will detect the drift within 5 min and log it.
```

## ❌ FORBIDDEN

- Creating an operator-intent file without a drift check (built-in heuristic OR explicit `## Drift check` section)
- Disabling `yousirjuan-intent-drift.timer` on the VPS without operator approval
- Bypassing the LEDGER-0014 `intent.sh remove` workflow when overriding a state (use the protocol; don't manually `systemctl unmask + start`)

## ✅ REQUIRED

- When writing a new intent file, ensure it's covered by either the built-in heuristic table OR an explicit `## Drift check` section
- When overriding an intent (legitimately), use `intent.sh remove <topic>` FIRST, then the operational action
- When investigating session-time confusion, check `/var/lib/yousirjuan/intent-drift-report.json` to see if any intent currently disagrees with reality

## Cross-references

- Universal Rule 16 in [`rules/GLOBAL-RULES-FOR-USING-NEPHEW.md`](../../rules/GLOBAL-RULES-FOR-USING-NEPHEW.md) — canonical authoritative version
- LEDGER-0014 — operator-intent protocol (the layer this rule audits)
- LEDGER-0019 — the drift detector implementation (systemd timer + check script + JSON report)
- LEDGER-0015 — server-tamer + alert-watch (Phase 2 plumbing for surfacing drift as notifications)
- Rule 13 — the rule this rule audits the truthfulness of
