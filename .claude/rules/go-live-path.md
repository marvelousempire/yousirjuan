---
description: Always deliver go-live steps immediately—migrate, deploy, smoke-test—even on forced/hotfix ships
alwaysApply: true
---

# Go live path — never defer

When this repo’s work **ships** (code, migrations, config that affects production), you **must** treat **“what you need to do to see it live”** as part of the **same deliverable** as the implementation—not a follow-up chat, not “documentation later.”

## Mandatory behavior

1. **State the go-live path in your response** before considering the task done: which surfaces changed (**backend** / **admin** / **marketing** / **iOS**), **Postgres migrations** (run `migrate` / which new `.sql` files), **deploy mechanism** (merge to `main`, then **Actions → Run workflow** on `deploy-{backend,admin,marketing}.yml` → `pm2 reload` on success), and **how to verify** (URLs, admin pages, API curls).
2. **Do this immediately** in the same turn as the code/docs—do not wait for the user to ask.
3. **No exceptions for “forced” or urgent ships.** Hotfix, emergency merge, or “just push it” **still** require the go-live checklist in writing. Forcing live does not remove the obligation to name migrations, deploy targets, and smoke checks—it tightens the need for clarity so nobody merges blind.

## Align with pipeline truth

Per [`dev-discipline.mdc`](dev-discipline.md), name the real stage: **committed → pushed → PR’d → merged → deployed**. “Done” without a stage is not status. If you only committed locally, say so and give **`git push`** / **PR** / **migrate** as the next steps.

## Minimum checklist shape

Adapt to the diff; always hit these when relevant:

- **DB:** `npm run migrate` (or project equivalent) on **production**; name new migration files.
- **API:** run **Deploy backend** workflow after merge; `pm2` is handled inside the workflow.
- **Web:** run **Deploy admin** / **Deploy marketing** workflows after merge; **`pnpm build`** for `marketing/**` when rules require it before push.
- **Verify:** concrete checks (e.g. `GET /public/…`, admin page path, feature flag).

If production access is not available from the agent environment, **still** publish the exact steps so the operator can run them in order—same requirement.

## Anti-patterns

- Shipping a migration file without saying **where** it must run and **after** which deploy step.
- Closing with “merge when ready” without **migrate + reload + smoke** when the change isn’t live until those run.
- Assuming “CI handles it” without naming **which workflow** and **what green means** for this change.

This rule applies to **Cursor, Claude Code, ChatGPT, or any assistant** operating under this repo’s rules: **go-live discipline is not optional.**
