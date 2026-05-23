# 01 — Pick the auth strategy

## Goal

Decide which of the four options in the parent ticket the operator wants. The decision controls every subsequent runbook.

## Decision matrix

| Criterion | A: per-repo deploy keys | B: machine user | C: PAT | D: GitHub App |
|---|---|---|---|---|
| Setup time | Medium (~10 min, scriptable via `gh api`) | Low (~5 min) | Low (~3 min) | High (~30 min) |
| Rotation cadence | Manual, no expiry | Manual, no expiry | Mandatory ≤1 year | Automatic, 1-hour tokens |
| Audit trail | Per-key | Per-user actions | Per-token actions | Per-app, per-installation |
| Scope | Specific repos | All org repos the user sees | Configurable (all / select) | Configurable |
| GitHub plan cost | $0 (deploy keys free) | $0 unless private org seats are capped | $0 | $0 |
| Future-proof for other orgs | No (each org needs its own keys) | No (one user per org) | Mid (PAT per org) | **Yes** (one app, multi-org installations) |

## Recommended default

If this is the only org and there's a free user seat: **Option B (machine user)**. One credential, one place to revoke, no rotation alarms.

If multiple orgs are coming: **Option D (GitHub App)**. Pay the upfront cost once.

## Record the decision

Once picked, add a one-line `## Decision (YYYY-MM-DD)` block to the parent README's "Approach options" section noting which one + why. That note becomes the audit trail for future agents wondering "why this credential and not the others."

## Success criteria

- Decision recorded in parent ticket
- Status of LEDGER-0025 flipped from `planning` to `in-progress`
- Next runbook (`02-generate-credential.md`) populated with the steps specific to the chosen option

## Undo

N/A — this runbook only records a decision; nothing on disk changes.
