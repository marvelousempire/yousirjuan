---
ledgerId: LEDGER-NNNN
title: <Short imperative phrase — what this task does>
status: in-progress
opened: YYYY-MM-DD
closed: null
related-pains: []
related-tickets: []
triggers: []
---

# LEDGER-NNNN — <Title>

## Ask

<What the operator asked for, in their words where possible. One paragraph.>

## Outcome

<One paragraph summarizing what shipped. Fill in when status flips to `shipped`.>

## Runbooks

<One bullet per atomic step. Each step is its own `runbooks/NN-<slug>.md` file. Split aggressively — the goal is microscopic, reusable units.>

- [01-step-one.md](runbooks/01-step-one.md) — one-line summary
- [02-step-two.md](runbooks/02-step-two.md) — one-line summary

## Playbooks

<One bullet per executable artifact. Strictly AI-free. If a task can't be expressed without AI, ship the runbook only and note `no playbook because <reason>` here.>

- [Makefile](playbooks/Makefile) — `make install` (targets: install, uninstall, status, ...)
- [install.sh](playbooks/install.sh) — idempotent shell, logs to `~/yousirjuan-ledger.log`

## Replay (zero-AI)

<The single command, copy-pasteable, that re-runs this task on a clean machine.>

```
make -C ledger/LEDGER-NNNN-<slug>/playbooks install
```

## Verification

<How to know the task succeeded. Concrete: `make status` output, `curl http://...`, a file exists at a path.>

## Undo

<How to revert. Either a target (`make uninstall`) or step-by-step prose.>

---

## Notes

<Anything else worth keeping. Why-was-this-done context, surprises hit during execution, decisions deferred to follow-ups. Optional but valuable.>
