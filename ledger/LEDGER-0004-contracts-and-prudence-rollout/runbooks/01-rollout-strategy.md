# Runbook 01 — Rollout strategy

This runbook explains the *why* behind the rollout playbook's choices. The playbook itself is mechanical; the strategy here is what makes those mechanics defensible.

## The propagation problem

The operator stated the philosophy verbatim on 2026-05-20 and asked it be added to "yousirjuan and nephew and all other under nephew control tower" as "a notice to remember" for every agent. Scope: ~40 active repos in the `marvelousempire` GitHub org.

Constraints:

- **The philosophy is universal** — same wording, same chain of equivalences, same checklist for every repo.
- **Different agents land in different repos** — some are Claude Code-heavy, some Cursor-heavy, some primarily edited by humans.
- **GitHub doesn't render cross-repo symlinks** — each repo physically needs its own file for an agent's session-start scan to find it.
- **Branch protection / CI varies per repo** — some have contract-enforcement-style checks; some have CODEOWNERS; some are wide open.
- **The operator's time is finite** — 40 PRs to manually review is a lot. The PRs need to be reviewable in aggregate, not individually.

## Strategy decisions

### Mirror, not symlink

Cross-repo symlinks don't work in GitHub. Each repo gets a real file on disk. The propagation playbook stamps an identical copy of [`artifacts/contracts-and-prudence-portable.md`](../artifacts/contracts-and-prudence-portable.md) into every target repo.

The canonical version (with the deep-dive rationale, concrete anti-patterns, and the longer "what good looks like" section) stays in **marvelousempire/yousirjuan** at `.claude/rules/contracts-and-prudence.md`. The portable mirror links back to that canonical for the deep dive.

### Two files per repo, not one

- `.claude/rules/contracts-and-prudence.md` — Claude Code rule format. Auto-loads in any Claude Code session in the repo.
- `.cursor/rules/contracts-and-prudence.md` — Cursor rule format. Same content, same frontmatter. Auto-loads in any Cursor session.

YAML frontmatter works for both tools (both accept `description`, `alwaysApply`, `globs`). The portable file is dual-purpose.

### Identical, not adapted

Each repo gets the *same* file content. No per-repo customization. Reasons:

- The philosophy is universal — "good contracts → good" doesn't depend on what the repo does.
- Customizing per repo creates N versions to maintain. When the philosophy changes, every version needs updating.
- The canonical lives in yousirjuan; every mirror links back. There's one source of truth.

### Idempotent + dry-run-first

The playbook supports four actions:

| Action | What it does |
|---|---|
| `list` | Print the working set of repos that would be touched (filtered by active + non-archived) |
| `dry-run` | For each repo, clone temporarily, check current state, report what would change. **No commits, no pushes, no PRs.** Safe to run repeatedly. |
| `apply` | Same as dry-run, plus commit + push + open PR + (optionally) merge. |
| `status` | Inspect what's currently in each repo on origin/main. ✓ if the portable file matches the canonical; ⚠ if it diverged; ✗ if missing. |

Idempotency: if a repo already has the file and it matches the canonical, `apply` skips that repo (no spurious PRs). If the file diverged (someone edited it locally), `apply` reports the divergence and asks before overwriting.

### Per-repo failure isolation

Each repo is processed in its own subshell with `set +e` so a failure in one repo doesn't abort the others. The summary at the end lists:

- ✓ shipped (PR opened + merged)
- ⚠ PR opened but not merged (e.g., branch protection requires review)
- ✗ failed (clone error, push error, gh error) — with the per-repo error message

### Excluded by default

These categories are skipped:

- **Archived repos** — `gh repo list --json isArchived` filter.
- **Forks** — `gh repo list --json isFork` filter (we don't want to propagate into upstream's tree).
- **`bishop-factory`** — slated for archival per the existing plan; no point propagating to a doomed repo.
- **Repos under a separate user's ownership** — only `marvelousempire/*`.

To include a normally-excluded repo, run with `--include <name>` (override).

To exclude a normally-included repo, run with `--exclude <name>` (override).

## When a repo needs an exception

Some repos may not be candidates for this philosophy file even though they're active:

- **Vendor / submodule mirrors** — don't propagate into vendored copies of external libraries.
- **Pure-data repos** (e.g., `historia` if it's just markdown archives) — the rule is for agents that *do* things; archives that agents only *read* don't need it.
- **Repos owned by a contractor or partner** — don't push agent-mindset rules into spaces we don't own.

For each exception, add the repo to the `EXCLUDES` array at the top of [`playbooks/rollout.sh`](../playbooks/rollout.sh) with a comment naming the reason. Re-running the playbook respects the exclusion.

## Success criteria for the rollout

After `apply` completes:

1. Every targeted repo has both `.claude/rules/contracts-and-prudence.md` and `.cursor/rules/contracts-and-prudence.md` on its default branch.
2. All copies are byte-identical to the canonical portable file.
3. Per-run summary at `artifacts/runs/<timestamp>.txt` lists every repo with one of ✓ / ⚠ / ✗.
4. `bash playbooks/rollout.sh status` reports ✓ for every targeted repo.

## What this rollout does NOT do

- It does **NOT** modify any existing files in target repos (only adds the two new files).
- It does **NOT** modify CI workflows or branch protection.
- It does **NOT** push directly to `main`; every change goes through a PR.
- It does **NOT** auto-archive `bishop-factory` (that's a separate task).
