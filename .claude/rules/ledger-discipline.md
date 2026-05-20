---
description: Capture every non-trivial task as a ledger entry — ticket + runbook + playbook — so the second time it's needed, no AI is in the loop.
alwaysApply: true
---

# Ledger discipline — capture work so AI doesn't need to be re-invoked

This rule complements [`dev-discipline.md`](dev-discipline.md). That rule says how to **open and close a session cleanly**; this rule says how to **leave a session with the work codified** — so future sessions don't redo it.

The driving principle: **treat AI invocation as the most expensive resource in the system.** Each AI cycle should leave behind enough artifact that the next instance of the same task doesn't need AI at all. That's what the ledger is for. See [`/ledger/`](../../ledger/) for the canonical home and the format-choice guide.

---

## When this rule fires

Add a ledger entry when **any** of these apply:

- The task takes more than 5 minutes of agent attention.
- The task touches the operating system (installs, configs, services, launchd/systemd, network).
- The task produces a reusable artifact (a script, a config file, a workflow, a service).
- The task is something you'd want to replay on a second machine, or a year from now.
- A teammate asks "how did we do X" and the answer isn't already in the ledger.

**Don't** add a ledger entry for:

- One-line typo fixes or comment edits.
- Pure conversational debugging that doesn't produce an artifact.
- Reading-only exploration. (Reading is fine — the rule fires when you start changing things.)

---

## The three artifacts per entry

| Artifact | Required? | Lives at | Purpose |
|---|---|---|---|
| **Ticket** (`README.md`) | Always | `ledger/LEDGER-NNNN-<slug>/README.md` | The frontmatter + ask + outcome + replay command |
| **Runbook(s)** | Always | `ledger/LEDGER-NNNN-<slug>/runbooks/NN-<slug>.md` | Human-readable how-to, one file per atomic step |
| **Playbook(s)** | When possible | `ledger/LEDGER-NNNN-<slug>/playbooks/*` | Machine-replayable artifact (Makefile / shell / Ansible / Action / plist / compose) |

If a task genuinely needs AI judgment and cannot be expressed as a playbook, **ship the runbook only and note** `no playbook because <reason>` in the ticket. That's a signal to revisit later when the task is better understood.

---

## Granularity rule — chunk aggressively

The unit of a runbook is **one atomic, reusable step**. If a runbook describes more than one independent procedure, split it.

Right size: a runbook that a future agent can read in 2 minutes and execute confidently in isolation.

Wrong size: a 30-step "do the whole project" runbook. That's a session journal — keep that at the entry root (`journal.md`), but the runbooks themselves should be microscopic.

Example from `LEDGER-0001-imac-mcp-setup` (the seed entry): one task (set up MCP on the iMac) split into 5 atomic runbooks — install `code` CLI, write workspace MCP config, install Cline + Cline MCP config, install Ollama LaunchAgent, write the Makefile wrapper. Each is replayable independently.

---

## Strictly AI-free playbooks

A playbook is a contract: **running it produces the same result without any AI in the loop.** That means:

- No `claude -p '...'` or similar inside the playbook.
- No "and then ask the agent to do X" steps.
- No prose imperatives that require interpretation.

If the task can't be expressed without AI, that's information. Note it in the ticket and ship a runbook only. The job of future-you (or future-agent) is to find the AI-free path and retroactively add a playbook to the existing entry.

---

## Counter discipline

The "Next number" line in [`ledger/README.md`](../../ledger/README.md) is the source of truth. When you open a new entry:

1. Read the current "Next number" (e.g. `LEDGER-0007`).
2. Claim it: create `ledger/LEDGER-0007-<slug>/` by copying `ledger/_template/`.
3. Bump the line to the next number (`LEDGER-0008`) in the **same commit** that creates the entry.
4. Add a row to the index table with `status: in-progress`.

Two PRs racing for the same number is a real risk — that's why the bump goes in the same commit, not after.

---

## Naming + frontmatter

- **Folder:** `LEDGER-NNNN-<kebab-slug>/` where `NNNN` is zero-padded four digits and `<slug>` describes the *task*, not the date. Dates live in frontmatter.
- **Frontmatter:** every ticket starts with the YAML block from [`ledger/_template/README.md`](../../ledger/_template/README.md). The `triggers:` field is important — it tells a future agent how this playbook fires automatically (launchd / cron / GitHub Actions / file-watch / manual).
- **Cross-links:** if the entry resolves a pain, list it in `related-pains: [PAIN-NNNN]`. If it builds on a prior ledger entry, list it in `related-tickets: [LEDGER-NNNN]`.

---

## Format-choice guide (brief — full version in `ledger/README.md`)

| Task type | Reach for |
|---|---|
| Dev workflow with multiple related ops | **Makefile** |
| One-shot install / setup | **shell script** (sources the standard `step/ok/warn/die/have` helpers) |
| Multi-host config | **Ansible** (optional dependency — only when its idempotence is a clear win) |
| Scheduled / push / PR | **GitHub Actions** |
| Persistent macOS background service | **launchd plist** |
| Container service stack | **docker-compose** snippet |
| Anything needing AI judgment | **Runbook only** — note why in ticket |

The full guide, with code snippets for the helper functions and idempotency patterns, lives in [`ledger/README.md`](../../ledger/README.md).

---

## Session closer (for any session that produces a ledger entry)

Run in order:

1. **Confirm the entry exists.** `ls ledger/LEDGER-NNNN-<slug>/README.md` resolves.
2. **Confirm the ticket is complete.** Frontmatter filled, `Ask` / `Outcome` / `Verification` / `Undo` populated.
3. **Confirm every runbook ends with a "Success criteria" and "Undo" section.** Match the shape of LEDGER-0001's runbooks.
4. **Run the playbook on a clean test, if possible.** Idempotency check: running it twice produces no diff and no errors.
5. **Bump the "Next number" line** in `ledger/README.md` and add the index row — same commit.
6. **Open a PR** per `dev-discipline.md` rules (explicit-path staging, no `git add -A`).
7. **Status flip** (`in-progress` → `shipped`, fill `closed:`) happens in the merge commit or in the PR body — not before merge.

---

## Pinnable checklist

Keep this visible during ledger-producing work:

```
LEDGER ENTRY CHECKLIST
[ ] Folder name follows LEDGER-NNNN-<kebab-slug>
[ ] Counter bumped in ledger/README.md "Next number" line
[ ] Index row added with status: in-progress
[ ] Ticket frontmatter complete (ledgerId, title, status, opened, related-pains, triggers)
[ ] Ticket body has Ask / Outcome / Runbooks / Playbooks / Replay / Verification / Undo
[ ] Runbooks split into atomic steps, each <= 2 min to read
[ ] Each runbook has Success criteria + Undo
[ ] Playbook is strictly AI-free (or runbook-only with "no playbook because ..." noted)
[ ] Idempotency tested — playbook is safe to re-run
[ ] PR opened with explicit-path staging
[ ] On merge: status flipped to shipped, closed: date filled
```

---

## When this rule does not apply

This rule is for **operational work** that produces artifacts. It does not apply to:

- Pure code-only PRs that don't produce a reproducible setup procedure (those follow `dev-discipline.md`'s CHANGELOG + Feature Ledger rules instead).
- Read-only exploration sessions.
- Pain-journal entries (those describe problems, not solutions — different artifact).

If you're unsure whether a task warrants a ledger entry, ask: *"would I want to replay this on a second machine?"* If yes, ledger it. If no, skip.
