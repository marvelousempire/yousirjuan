---
description: Session opener + closer rituals so nothing is behind, every shipped feature is logged, and bottlenecks teach us instead of repeating.
alwaysApply: true
---

# Dev discipline — session opener + closer

This rule complements [`changelog-and-versioning.mdc`](changelog-and-versioning.md). That rule says **what** to log when something ships; this rule says **how** to start and end every session so logs actually get written and parallel work doesn't collide.

The cost of skipping these two rituals is documented in [`docs/Issue-Log.md`](../docs/Issue-Log.md) — every entry there is a real bottleneck that one of these checks would have prevented.

---

## Three docs, one source of truth each

| Doc | Source of truth for | Update when |
|---|---|---|
| [`docs/CHANGELOG.md`](../docs/CHANGELOG.md) | What shipped, by version, with timestamps | Any user-visible / product-visible change ships |
| [`docs/Feature Ledger.md`](../docs/Feature%20Ledger.md) | Per-feature status grid (✅/✔️/🔜/❌) | A feature row's status changes, or a new feature is introduced |
| [`docs/Issue-Log.md`](../docs/Issue-Log.md) | Bottlenecks, near-misses, lessons | Anything took >30 min unexpectedly, was a near-miss, or taught a process lesson |

**Don't invent a fourth doc.** If something feels like it doesn't fit any of the three, it probably belongs in the most relevant existing PR description or a code comment, not a new tracking surface.

---

## Session opener (run before the first edit)

```bash
git worktree list                           # know what's in flight
cd <correct worktree>                       # confirm pwd matches the task
git fetch                                    # get latest origin
git status                                   # see current state
git log origin/main..HEAD --oneline          # see your branch's unmerged work
git log HEAD..origin/main --oneline          # see what you're behind
```

Then **skim the last 3-5 entries in [`docs/Issue-Log.md`](../docs/Issue-Log.md)** — don't re-hit a wall someone already documented.

**Why these checks exist:** every one corresponds to a real Issue Log entry. Skipping them costs time. Running them takes ~30 seconds.

### Branch hygiene

For new feature branches, **base off `origin/main` explicitly**, not local `main`:

```bash
git checkout -B feature/short-name origin/main
```

Local `main` drifts silently across sessions and is not a source of truth.

### Worktree hygiene

When working in a `.claude/worktrees/*` worktree:
- Edits go through paths inside **that worktree's prefix**, not the main checkout's prefix
- Read-back the file with `Read` after a non-trivial edit if the path looked unusual
- If `git status` in your worktree shows nothing after an edit, you probably edited the main checkout — `find` the file path to confirm

---

## Session closer (run before opening a PR)

In order:

### 1. Stage by explicit path

**Forbidden:** `git add -A`, `git add .`, `git add -u`.

**Required:** `git add path/to/file1 path/to/file2 ...` listing each modified file by name. This monorepo has Xcode-regenerated files (`*.pbxproj`), tool-generated lockfiles, and cross-surface code (admin/ vs marketing/ vs backend/ vs Red-E Play/) that *will* drift into your working tree without your intent. Bulk-add silently bundles them into your PR.

If a file you didn't edit appears modified, leave it uncommitted and move on. It's not your concern this PR.

### 2. Update CHANGELOG.md

Per [`changelog-and-versioning.mdc`](changelog-and-versioning.md): every user-visible change gets a section, with the Eastern timestamp and the version bump. **Same commit as the code, or an immediate follow-up commit before push** — never let shipped work sit unlogged.

### 3. Update Feature Ledger.md (if applicable)

If the change introduces a new feature row OR moves an existing row's status (✅/✔️/🔜/❌), update [`docs/Feature Ledger.md`](../docs/Feature%20Ledger.md) in the same PR. Status drift is a silent failure mode — the ledger only works if it reflects reality.

### 4. Add to Issue-Log.md (if applicable)

Add an entry to [`docs/Issue-Log.md`](../docs/Issue-Log.md) if **any** of these apply:
- The work took noticeably longer than expected because of a *system* gap (not just a hard bug)
- You caught a near-miss during commit / pre-flight / review
- A mistake landed and needed revert or follow-up patch
- You learned something a future dev (or your future self) would thank you for documenting

Use the template at the top of `Issue-Log.md`. Keep entries short (5 lines is fine).

### 5. Open a PR — never leave a pushed branch invisible

**If you push commits to a feature branch, you MUST one of:**
- `gh pr create ...` — open a real PR (preferred)
- `gh pr create --draft ...` — open as draft with a one-line comment explaining why it's not ready

A pushed branch with no PR is invisible work. It blocks reviewers, blocks parallel sessions from knowing the work exists, and creates duplicate-work failure modes. **No exceptions** — even WIP needs a visible surface.

Run `gh pr list --state open` periodically to make sure your branches all have PRs.

### 6. Name the pipeline stage when reporting "done"

Work moves through 5 stages: **committed → pushed → PR'd → merged → deployed.** Each is a different status. "Done" without a stage is a story, not a status — and it builds false confidence.

When telling anyone (user, teammate, future-you in the Issue Log) that work is "shipped" or "live":
- **"Live"** requires that you have curl'd the production URL OR seen `gh run list` show a `success` deploy workflow since the relevant merge to `main`
- **"Shipped"** requires the PR is merged into `main`
- **"In review"** = PR'd, awaiting merge
- **"On a branch"** = pushed but pre-PR (and per rule #5, this should be rare)
- **"In my working tree"** = committed locally, not on remote

If you can't name the stage, you don't know the status. Find out before reporting.

### 7. Don't merge from inside the worktree being merged

When running `gh pr merge --delete-branch`, **`cd` to the main checkout (or any path outside the worktree being merged) first.**

`gh` deletes the local branch *and* the associated worktree as part of `--delete-branch`. If your shell's CWD is inside that worktree, your CWD becomes invalid. With persistent-shell agent harnesses (Claude Code, etc.), this wedges every subsequent foreground bash call until the CWD is explicitly reset. Cascading "did the merge actually succeed?" confusion follows.

Safe pattern:

```bash
cd /Users/.../red-e-play-app   # main checkout, never a worktree
gh pr merge <N> --squash --delete-branch
```

If you must keep the worktree (e.g. you'll do a follow-up commit on the same branch immediately), use `--squash` without `--delete-branch` and clean up by hand later.

### 8. Run `pnpm build` locally before pushing marketing PRs

For changes that touch `marketing/**`, **run `pnpm build` locally before pushing** unless the diff is *literally* trivial. Trivial = renaming a label, reordering a const array, nothing that creates new JSX text, new types, new imports. Anything else: build first.

**Why this rule exists.** `pnpm dev` doesn't run ESLint or `tsc --noEmit` by default — but `pnpm build` does. That means a dev-loop iteration can pass lint-free while the production build explodes on `react/no-unescaped-entities` (an apostrophe in JSX text), a TypeScript union-type mismatch, or a missing export. Since the VPS deploy IS the first place those errors surface, each round-trip costs ~3 minutes AND leaves a broken build on `main` until the fix lands. Documented incident cost in `docs/Issue-Log.md` — once was a single-PR fix, twice in one PR was the same *pattern* relearned.

**The command:**

```bash
cd marketing
pnpm install --frozen-lockfile   # only needed if node_modules is cold (~2 min); usually cached
pnpm build                        # runs next build → lint + tsc + compile, ~30s warm
```

**Warm builds are fast** — maybe 30 seconds, most of which is TypeScript. Skipping the build costs more than running it when it catches a bug, *especially* because the fallout (broken deploy → "is it live yet?" confusion → scramble-fix PR) is documented and real.

**Don't apply to:** `admin/**` or `backend/**` PRs (they have their own pipelines), docs-only PRs, `.cursor/rules/**` PRs, single-label or const-reorder PRs in marketing.

**Long-term:** add a CI job (GitHub Actions, runs on every PR touching `marketing/**`) that does `pnpm install --frozen-lockfile && pnpm build` so ESLint + tsc errors block the merge button, not the deploy. Tracked as a follow-up; this rule is the interim discipline.

---

## When to spawn a sibling task instead of expanding the current PR

If during work you notice something out-of-scope (dead code, stale doc, missing test coverage, a real-but-unrelated security issue), **don't bloat the current PR**. Either:
- Note it in the Issue Log if it taught you something
- Spawn a separate task / file a follow-up issue / open a chip via the Cowork harness
- Or just note it in the PR description under "follow-ups"

Scope creep is the second-biggest source of stalled PRs after "no PR opened in the first place."

---

## Quick checklist

Pin this somewhere visible during dev work:

```
SESSION OPENER
[ ] git worktree list, cd to correct worktree, pwd
[ ] git fetch, git status, git log origin/main..HEAD
[ ] Skim last 3-5 Issue-Log entries

SESSION CLOSER (before push)
[ ] Stage files by explicit path (no git add -A)
[ ] CHANGELOG.md entry with Eastern timestamp
[ ] Feature Ledger.md row updated if status changed
[ ] Issue-Log.md entry if there was a near-miss or lesson
[ ] gh pr create (real or --draft) — never push without a PR
[ ] When reporting "done": name the pipeline stage (committed / pushed / PR'd / merged / deployed)
[ ] Before `gh pr merge --delete-branch`: cd to main checkout, never inside the merging worktree
[ ] For marketing/** PRs: cd marketing && pnpm build BEFORE pushing (skip only for trivial label/order changes)
```
