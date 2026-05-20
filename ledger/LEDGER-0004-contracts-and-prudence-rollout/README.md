---
ledgerId: LEDGER-0004
title: Propagate contracts-and-prudence philosophy rule to all active marvelousempire repos
status: in-progress
opened: 2026-05-20
closed: null
related-pains: []
related-tickets: []
triggers:
  - manual-cli: `bash ledger/LEDGER-0004-contracts-and-prudence-rollout/playbooks/rollout.sh dry-run`
  - manual-cli: `bash ledger/LEDGER-0004-contracts-and-prudence-rollout/playbooks/rollout.sh apply`
---

# LEDGER-0004 — Propagate contracts-and-prudence philosophy across the control tower

## Ask

> "Make sure you remember this and yousirjuan and nephew and all other under nephew control tower:
> 'Remember that good contracts are important to maintaining the good, anything else is less than good and we'd want to remain good by being good - prudence is good; careful is opposite careless and careless is equal to stupid and stupid is opposite of good.'
> Every agent should remember that philosophy before they perform tasks. Make that a rule and add it to all as a notice to remember."

Operator selected "ALL active marvelousempire repos (~40)" as the scope and "Dry-run first, then real" as the cadence.

## Outcome (pending)

Each active (non-archived) repo in the `marvelousempire` GitHub org receives an identical pair of files:

- `.claude/rules/contracts-and-prudence.md` — for Claude Code sessions
- `.cursor/rules/contracts-and-prudence.md` — for Cursor sessions

Both files contain the same content (the portable mirror at [`artifacts/contracts-and-prudence-portable.md`](artifacts/contracts-and-prudence-portable.md)) so any agent landing in any of these repos finds the philosophy on its first scan. The canonical with full rationale stays at [marvelousempire/yousirjuan `.claude/rules/contracts-and-prudence.md`](https://github.com/marvelousempire/yousirjuan/blob/main/.claude/rules/contracts-and-prudence.md); every other repo's copy is a 1:1 mirror that links back to the canonical.

The rollout playbook is idempotent — re-running it on a repo that already has the files is a no-op. When new repos join the org, re-running the playbook fleet-wide picks them up.

## Runbooks

- [01-rollout-strategy.md](runbooks/01-rollout-strategy.md) — why two files per repo, why mirror (not symlink), why identical (not adapted), and what to do when a repo needs an exception

## Playbooks

- [rollout.sh](playbooks/rollout.sh) — single-action idempotent script. Actions: `list` / `dry-run` / `apply` / `status` / `help`. Logs to `~/yousirjuan-ledger.log` and to a per-run summary file under `artifacts/runs/`.

## Artifacts

- [contracts-and-prudence-portable.md](artifacts/contracts-and-prudence-portable.md) — the canonical content shipped to every repo. **Single source of truth for the portable mirror.** Update this file; re-run the playbook; every repo's copy updates.
- `artifacts/runs/<timestamp>.txt` — per-run summary (which repos were touched, which were skipped, why)

## Replay (zero-AI)

To re-run propagation after updating the portable rule, or when a new repo enters the family:

```bash
cd ~/Developer/yousirjuan && \
bash ledger/LEDGER-0004-contracts-and-prudence-rollout/playbooks/rollout.sh dry-run && \
bash ledger/LEDGER-0004-contracts-and-prudence-rollout/playbooks/rollout.sh apply
```

## Verification

After `apply`, the `status` action lists every repo and whether its copy matches the canonical:

```bash
bash ledger/LEDGER-0004-contracts-and-prudence-rollout/playbooks/rollout.sh status
```

Each repo reports either ✓ (in sync) or ⚠ (out of sync — re-run apply, or the local copy was edited by a contributor).

## Undo

The propagation creates a PR per repo. To undo a specific repo: `gh pr revert <number>` on that repo, or delete the files locally and open a removal PR.

To undo across all 40 in bulk:

```bash
bash ledger/LEDGER-0004-contracts-and-prudence-rollout/playbooks/rollout.sh undo
```

…which opens a removal PR for each repo. Not destructive — every removal goes through PR + merge.

## Notes

- **Why mirror, not symlink:** GitHub doesn't render cross-repo symlinks; each repo needs its own physical copy of the rule for the agent's session-start scan to find it.
- **Why identical, not adapted:** the philosophy is universal. Per-repo adaptation would dilute the rule and create N versions to maintain. The canonical's deep-dive rationale lives in yousirjuan and is linked from every mirror.
- **Allowlist concern:** some repos may have their own `Contract Enforcement`-style CI that blocks the new files. The playbook detects PR check failures and reports per-repo so manual handling is possible.
- **Prudence in the rollout itself:** per the very rule being propagated, the rollout runs dry-run first; per-batch verification; idempotent so retries are safe; explicit revert path documented above.

## Cross-references

- The canonical rule it propagates: [`.claude/rules/contracts-and-prudence.md`](../../.claude/rules/contracts-and-prudence.md) (+ mirror at [`.cursor/rules/contracts-and-prudence.md`](../../.cursor/rules/contracts-and-prudence.md))
- The operator's verbatim philosophy + my agent-memory entries: `~/.claude/projects/-Users-averygoodman-Developer/memory/feedback_good_contracts_and_prudence.md` (off-repo)
