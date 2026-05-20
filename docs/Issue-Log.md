# Issue Log

Bottlenecks, near-misses, and lessons. Every entry here is a real cost that one of the [`.claude/rules/`](.claude/rules/) checks would have prevented (or now does prevent).

**Template:**

```
## YYYY-MM-DD — Short title

**What happened:** one paragraph.
**Cost:** time / blast radius / who noticed.
**Root cause:** what was actually broken.
**Prevention:** the check or rule that catches it next time, or a TODO to add one.
```

Keep entries short — 5 lines is fine. Newest first.

---

## 2026-05-20 — Em-dash hypothesis for workflow parse failure was a red herring

**What happened:** `release-intel-mac.yml` had been failing on every push to main in 0s with "this run likely failed because of a workflow file issue." First hypothesis: an em-dash (`—`, U+2014) in the unquoted `name: Release — Intel Mac installer` was the parse error. PR [#9](https://github.com/marvelousempire/yousirjuan/pull/9) shipped that fix — replaced the em-dash with a quoted string `name: "Release: Intel Mac installer"`. The workflow continued failing 0s on every push. Second look (PR [#10](https://github.com/marvelousempire/yousirjuan/pull/10)) revealed the actual cause: lines 93–107 sat at column 1 inside a `run: |` literal block whose first content line was at 10-space indent. YAML terminated the literal block at the first under-indented line and tried to parse `One-liner:` as a sibling top-level key.

**Cost:** one wasted PR (#9), one extra merge cycle. ~15 min of agent time chasing the wrong fix. No production impact (the broken workflow only fired on regular pushes, which never produced anything; tag pushes don't exist yet).

**Root cause (technical):** YAML literal block scalars (`|`) require every content line to be indented at least as much as the first content line. Under-indented lines END the block and the parser tries them as new top-level keys. The original author intended lines 93–107 as the multi-line content of a `NOTES="…"` bash assignment, but YAML doesn't permit that — bash multi-line strings inside a `run:` block must use a heredoc.

**Root cause (process):** Acted on the first hypothesis before confirming it was the only candidate. The diagnostic that *exposed* the bug — `gh api .../actions/workflows` returning the file path as the workflow name — was symptom-level, not cause-level. The em-dash was a plausible cause of *that* symptom but wasn't the only one.

**Prevention:** The [`workflow-debugger` agent](.claude/agents/workflow-debugger.md) shipped today encodes this lesson — its mindset section explicitly cites the PR #9 → PR #10 sequence as the formative experience: "willing to test a hypothesis, watch it fail, and discard it … when a first fix doesn't actually fix the parse error, the right move is to back up and look harder, not double down." Future workflow bugs go through the agent's diagnostic loop, which forces verification with the same diagnostic that revealed the symptom before declaring done.

**Fix:** PR [#10](https://github.com/marvelousempire/yousirjuan/pull/10) — rewrote the publish step to use `cat <<EOF | sed 's/^          //' > /tmp/release-notes.md` so heredoc content satisfies YAML indentation but renders left-aligned. `gh api` now returns the parsed name; workflow stopped firing on regular pushes.

---

## 2026-05-19 — Contract-enforcement workflow had been failing on every main push since the day it was added

**What happened:** The `Contract Enforcement - No Persona Content` GitHub Action workflow ([`.github/workflows/contract-enforcement-no-persona.yml`](../.github/workflows/contract-enforcement-no-persona.yml)) was failing every push to main, starting from the commit that added it. Cause: the workflow's `grep -r "Associate Agent"` check excluded `REPOS-CONTRACT.md` but not `CI-CONTRACT-GUIDE.md` — the latter contains the trigger strings as inline examples of what to grep for. Check 1 fails immediately on the meta-doc and exits before any other check runs.

**Cost:** 3+ days of red CI on main (2026-05-16 onward) before noticed. Made it hard to tell whether a new PR introduced a contract violation or just inherited the existing failure.

**Root cause:** When the workflow was added together with `CI-CONTRACT-GUIDE.md`, the test plan didn't include running the workflow against the new docs. Classic chicken-and-egg: the doc that describes how the workflow works contains the patterns the workflow rejects.

**Prevention:** Loosened the workflow ([PR #5](https://github.com/marvelousempire/yousirjuan/pull/5)) to use an explicit allowlist of files where persona / interface UX references are intentional: `REPOS-CONTRACT.md`, `CI-CONTRACT-GUIDE.md`, `CLAUDE.md`, `README.md`, `README2.md`, `apps/README.md`, `docs/marketing/**`, `docs/hardware/**`, `docs/assistant-role-templates.md`. Anything outside the allowlist still gets blocked. Comment block in the workflow file names every allowlisted file and why.

**Going forward:** When adding any new content-enforcement workflow, the meta-doc that describes it should either (a) be explicitly allowlisted in the workflow, or (b) live in a directory the workflow doesn't scan. Treat the workflow's own documentation as a test fixture, not as production content.
