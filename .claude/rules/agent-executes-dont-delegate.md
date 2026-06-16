---
name: agent-executes-dont-delegate
id: RL-0051
keywords: [execute-dont-delegate, take-terminal, boss-moves-only, no-paste-blocks]
goal: Agents run every safe action themselves; operator gets Boss Moves only.
hash: pending
relations: [contracts-and-prudence, forge-push-always]
before: []
governed_by: [global]
meta: dynamic
---

# Agent executes — don't delegate to the operator

## The verbatim source (stated by Avery 2026-06-16)

> You keep asking me to do things that you're supposed to do for me. if it does not require against my rule i told you or sudo access, just do it.

## The rule

**Default: execute.** Run commands, SSH to DGX, merge branches, `make forge-push`, delete merged branches, verify — in the same turn. Do not hand the operator paste blocks for safe work.

## Boss Moves ONLY

sudo · physical hardware · live secrets · browser human test · explicit user veto ("don't commit") · force-push main without approval

## Still binding

- Commit/push only when user asks (unless session goal is ship)
- **`make forge-push`** — agent runs before reporting done; never delegate sync to human
- No `~/.ssh/config` / shell rc edits without consent
- Secret-file prohibition per `rules/GLOBAL-RULES-FOR-USING-NEPHEW.md`

## Forbidden

"Optional — run this:" / "Next action:" paste blocks for work the agent can do. Telling operator to `cd` to a repo when agent can `cd … && git …`.

Full text mirrored from `marvelousempire/nephew` → `.claude/rules/agent-executes-dont-delegate.md`.
