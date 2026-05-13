---
description: Keep docs/CHANGELOG.md and Xcode marketing/build versions in sync; stamp US Eastern date-time on releases.
alwaysApply: true
---

# Changelog and version discipline

After **any significant product or user-visible change** (features, notable fixes, UX/copy that ships, dependency or capability shifts), update **`docs/CHANGELOG.md`** in the **same change** (or immediately in a follow-up commit if split).

## New release line (required shape)

Use a **new top section** under the intro (newest first):

```markdown
## [0.x.y] — YYYY-MM-DD HH:MM:SS Eastern · *short tagline*
```

- **`0.x.y`** — Follow the changelog’s beta rules (patch vs minor bump).
- **Date and time** — **US Eastern** wall clock to the **second**, using the **`America/New_York`** zone (automatically EST or EDT). Get the stamp when you finish the entry, e.g.  
  `TZ=America/New_York date '+%Y-%m-%d %H:%M:%S'`  
  then append a space and **`Eastern`** after the time (do not hard-code “EST” year-round).
- If you are **backfilling** an old section and one git commit clearly introduced it, you may use that commit’s **author date** converted to Eastern instead.

## Match Xcode / project metadata

In **`Red-E Play/project.yml`** (and **`RedEPlay.xcodeproj/project.pbxproj`** if not regenerated from YAML):

- Set **`MARKETING_VERSION`** to the same **`0.x.y`** as the new changelog heading.
- Increment **`CURRENT_PROJECT_VERSION`** (integer build) for every build you treat as releasable.

If you changed code but **did not** add a changelog section, **go back** and add it before considering the task done.

## Git (commit and branch)

Version and changelog edits are part of the **same deliverable** as the code or docs they describe—**do not leave them only in the working tree**.

- **Prefer one commit** that includes product change + **`docs/CHANGELOG.md`** + **`Red-E Play/project.yml`** (then **`xcodegen generate`** if you touch YAML) so history and tags stay traceable. If you must split (e.g. huge diff), use a **follow-up commit immediately** with a message that calls out version/changelog (e.g. `Changelog + bump to 0.6.22`).
- **Branching** — Use a short-lived branch (`feature/…`, `fix/…`) when you expect a **PR**, parallel work, or CI review; put the changelog/version bump **on that branch** before merge so `main` never lacks the release line for shipped work. For **small solo fixes** directly on `main`, still **commit and push** the version files with the fix.
- **Push** after commit when the repo is the source of truth so teammates and CI see the same **`MARKETING_VERSION`** / changelog as the code.

## Feature ledger

When the change is **ledger-worthy** (major screen, model, or integration), also update **`docs/Feature Ledger.md`** in the same pass if the project tracks that there.
