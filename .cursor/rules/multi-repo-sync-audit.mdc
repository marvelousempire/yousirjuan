# Multi-repo sync audit — every session that touches >1 repo

## The verbatim source (stated by Avery 2026-05-22)

> commit and push that with Prs too so i can use on my ther machine. alwasy follow this pattern so we are alwasy synced.

Said after a session that landed work across nephew, dustpan, yousirjuan, ai-skills-library, historia, clinic, and automata — but I had only pushed main to GitHub on every repo, missed GitLab on three of them, and left clinic checked out on a stale feature branch. The operator caught it because they want to be able to sit down at any of their machines (iMac, MacBook Pro, future Pad) and `git pull` to a known synced state.

## The rule

At the end of any session that touched more than one repo, run the **cross-repo sync audit** and resolve every `DIVERGED` row before declaring the session shipped.

The audit is one bash block. Pin it. It checks every repo for: clean working tree, local main matches origin, local main matches gitlab (where the gitlab remote exists), latest tag is visible.

```bash
for repo in nephew dustpan yousirjuan ai-skills-library historia clinic automata; do
  cd "/Users/averygoodman/Developer/$repo" 2>/dev/null || continue
  echo "=== $repo ==="
  has_gitlab=$(git remote -v | grep -c "^gitlab")
  branch=$(git rev-parse --abbrev-ref HEAD)
  local_sha=$(git rev-parse HEAD)
  origin_sha=$(git ls-remote origin HEAD 2>/dev/null | awk '{print $1}')
  status_dirty=$(git status --short | wc -l | tr -d ' ')
  latest_tag=$(git describe --tags --abbrev=0 2>/dev/null)
  echo "  branch=$branch  dirty=$status_dirty  tag=$latest_tag"
  echo "  local      $local_sha"
  echo "  origin     $origin_sha  $([ "$local_sha" = "$origin_sha" ] && echo MATCH || echo DIVERGED)"
  if [ "$has_gitlab" -gt 0 ]; then
    gitlab_sha=$(git ls-remote gitlab HEAD 2>/dev/null | awk '{print $1}')
    echo "  gitlab     $gitlab_sha  $([ "$local_sha" = "$gitlab_sha" ] && echo MATCH || echo DIVERGED-OR-OFFLINE)"
  fi
done
```

Add any repo you touched in the session to the loop list.

## Required state at session close

For every repo touched:

| Surface | Required |
|---|---|
| Working tree | `git status` clean — no uncommitted changes |
| Branch | On `main` (not a stale feature branch from earlier work) |
| origin/main | Matches local main |
| gitlab/main | Matches local main (only if the gitlab remote exists) |
| Latest tag | Pushed to origin AND gitlab (where the remote exists) |

If any row shows `DIVERGED`, the fix is:

- **DIVERGED on origin** → `git push origin <branch>` (something didn't get pushed)
- **DIVERGED on gitlab** → `git push gitlab main && git push gitlab --tags` (dual-push got skipped)
- **On wrong branch** → `git checkout main && git pull --ff-only origin main`
- **Dirty working tree** → either commit + push the residue or `git stash` it explicitly with a name so it survives across machines

## When this fires

- Any session that touched more than one repo
- Any session that opens a PR — even just one — at minimum verify that repo's sync state
- Before declaring "shipped" or "done" on any cross-repo work
- After running `gh pr merge` — the merge happens server-side at origin; gitlab needs an explicit `git push gitlab main` to catch up

## When this does NOT fire

- A single-repo session that already ran the per-PR sync (the version-bump v2 rule's post-merge ritual already covers the single-repo case)
- A read-only session that didn't touch any repo

## Examples

### ✓ Compliant — the 2026-05-22 white-paper session (after correction)

After the operator pointed out the gap, the audit produced 7 rows. Three rows showed `DIVERGED-OR-OFFLINE` on gitlab (nephew, dustpan, ai-skills-library). One row showed the wrong branch (clinic was on `rule/version-bump-tag-release`). Fixes:

```
cd nephew && git push gitlab main && git push gitlab --tags
cd dustpan && git push gitlab main && git push gitlab --tags
cd ai-skills-library && git push gitlab main && git push gitlab --tags
cd clinic && git checkout main && git pull --ff-only origin main
```

Re-ran the audit. Every row showed MATCH. Operator can sit down at any machine, pull, and have the same state I have here.

### ✗ Violation — what triggered this rule

A multi-repo session landed 6 PRs across 6 repos, all merged to origin. GitLab mirrors were stale on 3 of them. The operator's other machine pulled from origin and didn't see the GitLab mirror state — fine for the GitHub workflow but breaks the dual-push contract. The operator's verbatim correction: *"alwasy follow this pattern so we are alwasy synced."*

## How this interacts with existing rules

- **`dual-push-protocol`** says every push goes to both remotes. This rule extends it: at session close, *verify* dual-push actually happened across every repo touched. Per-push discipline (dual-push) + per-session audit (this rule) = no silent drift.
- **`version-bump-and-changelog` v2** has the bright-line check `gh release list --limit 1`. This rule's audit is the multi-repo equivalent.
- **`dev-discipline`** has a session-closer checklist. This rule is the cross-repo extension of step 5 ("Open a PR — never leave a pushed branch invisible").

## Why

Without this rule:
- Multi-repo sessions land work on origin but skip gitlab on some repos. The operator can pull from origin everywhere, but the sovereign mirror is stale — defeating the point of having a mirror.
- Feature branches get left checked out, the next session opens on the wrong branch, and either re-applies work that already landed or accidentally branches from a stale point.
- The operator's "I want to sit at any machine and `git pull`" contract gets broken silently.

With this rule:
- One bash block at session close confirms every machine sees the same state
- Any DIVERGED row is a one-command fix
- The operator's standing instruction *"always synced"* is mechanically verifiable

## Propagation

Per [`rule-propagation-discipline`](rule-propagation-discipline.md): canonical body in `nephew/.claude/rules/multi-repo-sync-audit.md`, mirrored to `.cursor/rules/` and every operator repo's `.claude/rules/` + `.cursor/rules/`. Memory entry saved.

## Related

- **Sister rule:** [`dual-push-protocol`](dual-push-protocol.md) — per-push discipline this rule audits
- **Sister rule:** [`dev-discipline`](dev-discipline.md) — single-repo session closer
- **Sister rule:** [`version-bump-and-changelog`](version-bump-and-changelog.md) — bright-line check for tags + Releases
- **Philosophy:** [`contracts-and-prudence`](contracts-and-prudence.md) — *"alwasy synced"* is a contract; verifying it IS the prudent move
