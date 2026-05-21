# Dual-Push Protocol — every `git push` goes to GitHub AND GitLab

Binding rule for every agent operating in this repo (and every marvelousempire repo with both remotes configured).

This rule mirrors **Universal Rule 14** in [`rules/GLOBAL-RULES-FOR-USING-NEPHEW.md`](../../rules/GLOBAL-RULES-FOR-USING-NEPHEW.md). Both must stay in sync.

---

## The contract

When the operator says **"push"**, **"push to git"**, **"push everything"**, or any equivalent — that means push to **BOTH**:

1. **GitHub** (`origin` remote) — public source of truth
2. **GitLab** (`gitlab` remote at `git.yousirjuan.ai:2424`) — sovereign mirror per LEDGER-0005

Pushing to only one is a broken contract. The single shorthand "push" must fan out to both.

## How to keep it

Use the dual-push tool:

```bash
bash tools/git-dual-push.sh                  # current branch to both
bash tools/git-dual-push.sh feat/my-branch   # explicit branch to both
bash tools/git-dual-push.sh --tags           # include tags
bash tools/git-dual-push.sh --backfill       # retry every pending entry when GitLab comes back
```

Equivalent manual sequence (if the script isn't available):

```bash
git push origin <branch> && git push gitlab <branch>
```

## What the script does that bare `git push` doesn't

- **Tries GitHub first** (must succeed — it's the source of truth)
- **Tries GitLab second** with a 15s timeout (warn-but-continue if unreachable — GitLab can be intentionally stopped per LEDGER-0014 operator-intent files)
- **Records pending GitLab pushes** to `~/.local/share/yousirjuan/pushes-pending-to-gitlab.log` when GitLab fails — so a later `--backfill` can resync once GitLab is back
- **Exits non-zero only on GitHub failure** — GitLab being down doesn't fail the command (you still need to know GitHub succeeded)

## When the `gitlab` remote isn't configured

The script prints the exact `git remote add` command:

```
git remote add gitlab ssh://git@72.167.151.251:2424/marvelousempire/<repo>.git
```

Add it before next push.

## When GitLab is down per operator-intent

The script will detect the timeout, warn, and log to the pending file. Do NOT:

- Restart GitLab without checking `/etc/yousirjuan/operator-intent.d/gitlab-stopped.md` and asking the operator
- Silently mark the push as "complete" — the pending log is the receipt

When GitLab comes back (operator removes the intent + starts the container), run:

```bash
bash tools/git-dual-push.sh --backfill
```

That replays every pending entry across every repo on the box.

## ❌ FORBIDDEN

- `git push` (bare) — only goes to one remote; breaks the contract
- `git push origin` alone — only GitHub; breaks the contract
- `gh pr merge` (which triggers a server-side merge to origin/main only and never touches GitLab) **without a follow-up** `git fetch origin && bash tools/git-dual-push.sh main` to mirror the new main to GitLab
- Pretending success when only GitHub succeeded — the operator must know about GitLab pending state

## ✅ REQUIRED

- Use `tools/git-dual-push.sh` whenever you would have run `git push`
- After every `gh pr merge` to main: `git fetch origin && git reset --hard origin/main && bash tools/git-dual-push.sh main` to mirror the new main commit to GitLab too
- If you're inside a repo without the `gitlab` remote, add it before the first push

## Cross-references

- Universal Rule 14 in [`rules/GLOBAL-RULES-FOR-USING-NEPHEW.md`](../../rules/GLOBAL-RULES-FOR-USING-NEPHEW.md)
- LEDGER-0005 — GitLab CE sovereign source-of-truth (the mirror doctrine this enforces)
- LEDGER-0014 — operator-intent protocol (why GitLab might be intentionally stopped)
- `.claude/rules/operator-intent-protocol.md` — companion rule that complements this one
- `.claude/rules/contracts-and-prudence.md` — underlying operating philosophy
