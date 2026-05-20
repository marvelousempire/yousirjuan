---
description: When emitting shell snippets for a human to run, format them as one copy-pasteable block with `\` continuations and `&&` chaining — never split steps into separate fenced blocks.
alwaysApply: true
---

# CLI snippet formatting — one block, one paste

When you give a human shell commands to run, **always format them so the whole sequence can be copy-pasted into a terminal in a single shot**. The cost of "paste-paste-paste-paste" per individual step is small per occurrence but real — and it's exactly the kind of friction this rule pays back forever once fixed.

---

## The rules

1. **One fenced block per logical operation.** A multi-step sequence goes in one block, not N blocks with prose between them.
2. **Chain steps with `&&`** by default — every step runs only if the previous one succeeded. Use `;` only when steps are genuinely independent and you don't want a failure to halt the rest.
3. **Use `\` line continuations** for any single command long enough to wrap visually. The block is still one shell command; `\` just breaks it across lines for readability.
4. **Comments inside the block are fine** (`# comment` between steps doesn't break the chain), and often improve scan-ability.
5. **Don't put commands inline in prose.** Every command goes inside a fenced ``` block.

---

## Examples

**Wrong — five separate blocks, five paste operations:**

````markdown
First do this:
```
gh pr merge 4 --squash --delete-branch
```
Then this:
```
gh pr edit 6 --base main
```
Then this:
```
gh pr update-branch 6 --rebase
```
…and finally:
```
gh pr merge 6 --squash --delete-branch
```
````

**Right — one block, one paste:**

````markdown
```
gh pr merge 4 --repo marvelousempire/yousirjuan --squash --delete-branch && \
gh pr edit 6 --repo marvelousempire/yousirjuan --base main && \
gh pr update-branch 6 --repo marvelousempire/yousirjuan --rebase && \
gh pr merge 6 --repo marvelousempire/yousirjuan --squash --delete-branch
```
````

**Right — single long command with `\`:**

````markdown
```
gh pr create --repo marvelousempire/yousirjuan \
  --base main --head feat/new-thing \
  --title "feat(scope): summary" \
  --body "$(cat <<'EOF'
## Summary
...body...
EOF
)"
```
````

---

## When to split

Splitting is OK when the operator genuinely needs to inspect output before continuing — and you should call that out explicitly:

> Run this first, then check the output for `status=READY`:
> ```
> gh run view 12345 --repo foo/bar
> ```
> If you see `READY`, paste this next:
> ```
> gh pr merge 12 --squash --delete-branch
> ```

If you can't articulate why the steps must be split, they shouldn't be split.

---

## Why this rule exists

Stated by Avery 2026-05-19 after receiving four separate `gh` commands as four separate fenced code blocks. He had to click-copy each one individually. Recorded as a "Rule:" — durable, not a one-off correction.

The deeper principle: **make the operator's hands and eyes move as little as possible per unit of agent output.** A well-formatted CLI block reads as "do this thing" not "now type the next thing now type the next thing." The cost difference is small per command but compounds across every session with shell instructions.

---

## Quick checklist

```
Before sending shell commands to a human:
[ ] Single fenced block per logical sequence
[ ] && between steps (or ; for independent ones)
[ ] \ continuations for long single commands
[ ] No prose interleaved with code unless steps MUST be inspected between
[ ] Comments inside the block where they aid scanning
[ ] Full --repo / absolute path flags so the block works from any cwd
```
