# Global Rules For Using Nephew — Universal AI Operating System

> **File rename history (2026-05-21):** Originally `UNIVERSAL-NEPHEW-RULES.md`, briefly renamed to `GLOBAL-RULES-WHILE-USING-NEPHEW.md` mid-day, then settled on the current name `GLOBAL-RULES-FOR-USING-NEPHEW.md` per operator's final phrasing. Content unchanged across all three filenames. The current name signals these rules govern every agent, IDE, LLM, and human worker the moment they begin operating in any Nephew-adjacent environment.

**Owner:** ALL AI agents, LLMs, and orchestration systems  
**Scope:** Universal — applies to every AI system, not just Nephew  
**Enforcement:** Hard rule at the skill/orchestrator layer  
**Status:** Active immediately across all systems

---

## Rule 1: Always Take the Terminal

<system_reminder>
When it is time to execute CLI commands, Git operations, file changes, or build/test runs — the AI must perform the action directly, NOT outline it for the user to run.

This is not a suggestion. This is the contract.
</system_reminder>

### ✅ REQUIRED

```bash
# Direct execution — AI runs this command
cd /Users/nivram/Developer/automata && \
git add -A && \
git commit -m "feat: purpose-gap truth, Nephew CLI rule" && \
git push origin main
```

AI output:
```
[main abc123] feat: purpose-gap truth, Nephew CLI rule
 5 files changed, 450 insertions(+)
To github.com:marvelousempire/automata.git
   def456..abc123  main -> main
```
AI adds: "Pushed. The commit is now live on GitHub at [link]."

### ❌ FORBIDDEN

- "Paste this into your terminal: ..."
- "Once you push this ..."
- "You should run ..."
- "Here's the command to run:" (followed by code block)
- "Try running this:" (any instruction-style phrasing)

**All of these are violations.** The user wants execution, not instructions.

---

## Rule 2: When to Take the Terminal

| Task | Action |
|---|---|
| Git (add, commit, branch, push, merge, rebase) | **Direct execution** |
| File changes (write_file, edit_file, mkdir, rm) | **Direct execution** |
| Build/test/lint (pnpm build, npm test, make) | **Direct execution** |
| CLI tools (automata slice, automata patrol, docker) | **Direct execution** |
| Network requests (curl, wget, fetch) | **Direct execution** |
| Process management (services, dev servers, pm2) | **Direct execution** |
| Data processing (sed, awk, jq, python scripts) | **Direct execution** |

---

## Rule 3: When NOT to Take the Terminal

| Task | Action |
|---|---|
| Pure information retrieval ("what is X?") | **Explain, don't execute** |
| Opinion/analysis ("should I do X?") | **Advise, don't execute** |
| User explicitly says "tell me how to" | **Provide instructions only** |
| User explicitly says "don't run this" | **Stop, ask for permission** |
| User asks for a template/snippet | **Provide code block only** |

---

## Rule 4: Success/Error Badge System

<system_reminder>
Every AI must display a visual badge next to every report card, task, or agent action:**✅ Success** or **❌ Failed** — no exceptions. This is the Nephew orientation standard.
</system_reminder>

### Badge Format

```
✅ [Task Name] — Completed in Xs
```

or

```
❌ [Task Name] — Failed at step Y
```

### Report Card Format

```
## Task Report

**Agent:** Nephew CLI Orchestrator  
**Task:** Commit and push Nephew rules  
**Status:** ✅ Success  
**Duration:** 2.3s  
**Files changed:** 7  
**Lines added:** 1,247  
**Commit:** abc123def  
**Link:** [GitHub PR](https://github.com/...)

---

### What Changed
- NEPHEW-RULES.md: canonical ruleset (NEW)
- docs/the-gap.md: product-truth gap (NEW)
- packages/core/src/executor.ts: execution layer (NEW)

### Test Results
- flow.test.ts: 14/14 ✅
- patrol.test.ts: 12/12 ✅
- validate-schemas.mjs: 7/7 ✅

### Next Steps
- P0: Implement action stage in flow.ts
- P1: Build 6 real cells in automation/cells/
```

### Badge Placement

- **Always** at the top of the report (first line after task name)
- **Always** in bold with emoji (✅ or ❌)
- **Always** include duration and file count
- **Never** hide the badge in a collapsible section

---

## Rule 5: Escalation Path

If a command fails or requires user credentials:

1. **Retry once** — if it's a transient error (network, lock file)
2. **Diagnose** — check what went wrong (`git status`, `ls -la`, etc.)
3. **Report with badge** — show the failure clearly:
   ```
   ❌ Git push failed — permission denied
   
   Exact error:
   fatal: unable to access 'https://github.com/...': Could not resolve host
   
   What I tried:
   git push -u origin main
   
   Next step:
   Check network connection or use SSH instead of HTTPS
   ```
4. **Offer** — ask the user if they want to try a different approach

**Never ask for credentials.** If a command requires SSH key, GitHub token, or password — stop and explain what's needed. Do not attempt to bypass security.

---

## Rule 6: Commit Message Format

All commits follow this structure:

```
<type>(<scope>): <short imperative summary, ≤72 chars>

<WHY — one paragraph>

<WHAT — file-by-file bullet list>

<TESTS — pass count + command to reproduce>

<SCHEMAS/DOCS — any schema, doc, or rule file touched>
```

**Types:** `feat` · `fix` · `test` · `refactor` · `docs` · `ci` · `chore` · `rules`  
**Scopes:** `core` · `cli` · `watcher` · `pad` · `schemas` · `ci` · `docs` · `rules` · `nephew` · `global`

---

## Rule 7: Line Continuation for Multi-Line Commands

Every multi-line shell command MUST use `\` line continuation so it can be pasted and run as a single unit.

**Correct:**
```sh
cd /path/to/repo && \
git add -A && \
git commit -m "feat: description"
```

**Wrong:**
```sh
cd /path/to/repo
git add -A
git commit -m "feat: description"
```

---

## Rule 8: PR Description Format

Every PR must include these sections:

```markdown
## Why this PR exists
## What changed
## Test coverage
## How to verify
## Schemas / docs touched
## Checklist
```

---

## Rule 9: Witnessed Delivery Standard

Every PR that ships product code must:
1. Include a passing test that witnesses the behaviour
2. Update `witness/SHIP-LOG.md` with the slice id, date, and container level
3. Pass the schema CI gate (`validate-schemas.mjs`)

No slice ships unwitnessed.

---

## Rule 10: Say This

When performing a file operation, AI says:

> "Done. I modified/created/deleted [file]. Here's what changed: [one-line summary]. **✅ Success**"

**Never:** "I just [file operation] for you." (too casual, not specific)

---

## Rule 11: Say This on Failure

When a command fails, AI says:

> "Failed. The exact error: [error message]. What I tried to do: [command]. Next step: [diagnosis or fix]. **❌ Failed**"

**Never:** "That didn't work. Try this instead: [new command]" (dismissive, doesn't name the failure)

---

## Rule 12: Agent/Orchestrator Assignment Badge

When assigning tasks to agents or orchestrators, AI must display:

```
## Agent Assignment

**Agent:** [Name/Role]  
**Task:** [Clear task description]  
**Orchestrator:** [Orchestrator name]  
**Expected Output:** [What success looks like]  
**Deadline:** [Time or "immediate"]  
**Status:** ⏳ Assigned → [Will update to ✅/❌ when complete]
```

After completion:

```
**Status:** ✅ Success (completed in 2.3s)  
**Output:** [Actual output or link to file]
```

or

```
**Status:** ❌ Failed at step 3  
**Error:** [Exact error message]
**Retry:** [Yes/No] — [Reason]
```

---

## Rule 13: Operator-Intent Protocol — Leave Loud Notes for the Next Agent

<system_reminder>
Every time you deliberately stop, disable, mask, remove, block, or alter the state of a service / container / port / firewall rule / mount / scheduled job on any operator host, you MUST write an operator-intent note that the next agent landing on the box cannot miss. **Recording the decision only in a PR description, a chat log, or git history is not enough.** PR descriptions are invisible to an agent SSH'd into the box. The intent must live where the next agent will look — on the box itself.
</system_reminder>

### Why this rule exists

On 2026-05-21, an agent stopped `n8n-nephew.service` on the production VPS for a sound reason (it was the OOM trigger from runbook 05). The decision was recorded in a PR description. A later agent landing on the box saw a stopped service with no posted intent and helpfully restarted it. The OOM trigger came back online unannounced. The operator paid the cost.

**Verbatim operator directive:**

> "that n8n install issued by another agent was very bad. you must add that rule to make good notes so other people and other IA know what you are doing so they can know what to do. global rule please now."

### ✅ REQUIRED

When you change the deliberate state of anything on a host, in the **same session** that you made the change:

1. **Write an intent file on the host** at `/etc/yousirjuan/operator-intent.d/<topic-slug>.md` using the LEDGER-0014 `intent.sh` playbook:

   ```bash
   sudo bash <repo>/ledger/LEDGER-0014-operator-intent-protocol/playbooks/intent.sh add \
     <topic-slug> "<short description of what>" "<why — link to LEDGER / runbook>" \
     [--mask-service <unit>]
   ```

2. **Verify it's visible.** Reconnect via SSH to confirm the MOTD hook dumps the new intent banner before the prompt.

3. **For services that should NEVER come back without explicit operator action**, pass `--mask-service <unit>` so `systemctl start` fails with `"Unit is masked"`.

### ❌ FORBIDDEN

- Stopping a service and only mentioning it in a PR description.
- Closing a session with a deliberate state change that isn't reflected in an intent file on the box.
- Restarting / unmasking / re-enabling a service without first checking `/etc/yousirjuan/operator-intent.d/`. **Read before "fixing."**
- Removing an intent file by hand (e.g. `rm /etc/yousirjuan/operator-intent.d/x.md`) — always use `intent.sh remove <topic>` so the systemd unit gets unmasked too.

### Before "fixing" anything that looks broken

```bash
ssh <host> 'ls /etc/yousirjuan/operator-intent.d/ 2>/dev/null && \
            cat /etc/yousirjuan/operator-intent.d/*.md 2>/dev/null'
```

If any intent file mentions what you're about to touch, **STOP.** Quote the intent to the operator and ask explicitly before proceeding.

### Why the systemd mask matters

`systemctl mask <unit>` replaces the unit file with a `/dev/null` symlink. A casual `systemctl start <unit>` then fails:

```
$ sudo systemctl start n8n-nephew.service
Failed to start n8n-nephew.service: Unit n8n-nephew.service is masked.
```

That failure is the loud reminder. An agent will not silently override it; they have to deliberately `systemctl unmask` first, which is the moment they're forced to stop and check the intent file.

### Scope

This rule applies to every AI system, LLM, IDE agent, automated tool, and human worker operating on operator hosts. It is enforced at the repo level by [`.claude/rules/operator-intent-protocol.md`](../.claude/rules/operator-intent-protocol.md) and at the host level by the LEDGER-0014 MOTD hook + systemd masking.

### Cross-references

- LEDGER-0014 in marvelousempire/yousirjuan — the playbook + MOTD hook + concrete instances
- LEDGER-0007 runbook 05 — the OOM incident that triggered the original n8n stop
- `.claude/rules/contracts-and-prudence.md` — the operating philosophy this enforces: visible contracts maintain good; invisible contracts get broken

---

## Rule 14: Dual-Push Protocol — Every `git push` Goes to GitHub AND GitLab

<system_reminder>
When the operator says "push", "push to git", "push everything", or any equivalent — that means push to **BOTH** GitHub (`origin`) **AND** GitLab (`gitlab` at `git.yousirjuan.ai:2424`). Pushing to only one is a broken contract. GitLab is the sovereign mirror per LEDGER-0005; GitHub is the public source. **Both must receive every push.** Silently pushing to only GitHub leaves the GitLab mirror behind and breaks the source-of-truth posture.
</system_reminder>

### Why this rule exists

On 2026-05-21, an agent (Claude Code) ran an entire multi-PR session pushing only to GitHub. The operator caught it after the fact: *"when i ask you to push everything to git, you must push everything to my github repo and my gitlab - make sure that is what you have been doing."*

The mirror posture established in LEDGER-0005 was being silently eroded. Three of the four primary local clones didn't even have a `gitlab` remote configured — so the dual-push was structurally impossible without setup. Rule 14 closes both the procedural gap (you must dual-push) and the setup gap (you must add the `gitlab` remote if it's missing).

### ✅ REQUIRED

Use the dual-push tool whenever you would have run `git push`:

```bash
bash tools/git-dual-push.sh                  # current branch
bash tools/git-dual-push.sh <branch>         # explicit
bash tools/git-dual-push.sh --backfill       # retry pending entries after GitLab returns
```

After every `gh pr merge` (which only touches `origin/main` server-side), follow up with:

```bash
git fetch origin && git reset --hard origin/main && bash tools/git-dual-push.sh main
```

That mirrors the new main commit to GitLab.

### ❌ FORBIDDEN

- Bare `git push` — only goes to one remote; breaks the contract
- `git push origin` alone — only GitHub; breaks the contract
- `gh pr merge` followed by nothing — leaves GitLab behind
- Pretending success when only GitHub received the push

### Graceful degradation when GitLab is down

The dual-push script handles this:

- GitHub push fails → exit non-zero (operator must know)
- GitLab push fails (timeout, container stopped, network) → log to `~/.local/share/yousirjuan/pushes-pending-to-gitlab.log` + warn + exit 0
- Operator runs `tools/git-dual-push.sh --backfill` when GitLab returns to replay all pending entries

This respects the LEDGER-0014 operator-intent file `gitlab-stopped.md` — the script does not unmask or restart GitLab; it just records what's pending for when the operator brings it back deliberately.

### When the `gitlab` remote isn't configured

The script prints the exact `git remote add` command. Add it before next push:

```bash
git remote add gitlab ssh://git@72.167.151.251:2424/marvelousempire/<repo>.git
```

### Cross-references

- `.claude/rules/dual-push-protocol.md` — repo-level binding mirror of this rule
- LEDGER-0005 in marvelousempire/yousirjuan — GitLab as sovereign source-of-truth (the mirror doctrine this enforces)
- LEDGER-0014 — operator-intent protocol (why GitLab might be intentionally stopped during a session)
- `tools/git-dual-push.sh` in marvelousempire/yousirjuan — the implementation

---

## Rule 15: One Tower, One URL — New UI surfaces go INSIDE Nephew Control Tower

<system_reminder>
When you stand up any new app, dashboard, admin panel, or browser-facing UI for this platform, the default is to **embed it INSIDE the Nephew Control Tower** at `https://nephew.yousirjuan.ai/apps/<id>` via the apps-manifest pattern. Do NOT create a new subdomain by reflex. The Tower is the single operator entrypoint; subdomains are the exception, not the default.
</system_reminder>

### Why this rule exists

On 2026-05-21, an agent shipped Uptime Kuma as a standalone `uptime.yousirjuan.ai` subdomain. The operator's verbatim correction was unequivocal: *"can we just add that to the Control Tower which is the Nephew UI instead of 'uptime.yousirjuan.ai'? […] we have nephew.yousirjuan.ai — you need to make this as an app that can play inside of nephew."*

The deeper principle: **proliferation of subdomains is operational debt.** Every new subdomain means a new DNS A record to maintain, a new TLS cert to renew, a new auth boundary, a new cookie scope, a new place for the operator to bookmark. After ten apps you have ten URLs the operator has to remember and ten cert renewals to track. The Tower model collapses that into one URL + ten `/apps/<id>` routes that all live under the same auth + cert + nav.

### How to embed a new app in the Tower

1. **Register in the manifest.** Add an entry to `marvelousempire/nephew` → `data/control-tower-apps.manifest.json`:

   ```json
   {
     "id": "my-app",
     "label": "My App",
     "category": "agents",
     "subtitle": "What it does in one line",
     "embed_url": "https://my-app.yousirjuan.ai",
     "probe_url": "https://my-app.yousirjuan.ai/health",
     "external": true,
     "start_hint": "How to install / run / restore it",
     "route_key": "s-<11-random-chars>"
   }
   ```

2. **Strip X-Frame-Options** at the nginx layer for the embedded app's vhost so the iframe doesn't get blocked by `SAMEORIGIN`:

   ```
   proxy_hide_header X-Frame-Options;
   add_header Content-Security-Policy "frame-ancestors 'self' https://nephew.yousirjuan.ai https://*.yousirjuan.ai" always;
   ```

3. **Visit** `https://nephew.yousirjuan.ai/apps/my-app` → the EmbedAppPage renders the iframe with the Tower chrome around it.

### When a subdomain IS the right call (the exceptions)

| Reason for separate subdomain | Example |
|---|---|
| Non-HTTP protocol on a dedicated port | `git.yousirjuan.ai:2424` (SSH for git) |
| Service explicitly serves third parties / public traffic | `hello.yousirjuan.ai` (public marketing page) |
| Service requires its own TLS termination logic (mTLS, custom alpn) | rare; document why |
| Legacy app that predates the Tower model | grandfathered; don't migrate without reason |
| The operator explicitly directs a subdomain | this rule defers to direct operator decision |

If none of the above apply: **embed in Tower.**

### ❌ FORBIDDEN

- Reflexively creating a new subdomain for a new web UI without considering the embed option
- Standing up a service whose only surface is its own subdomain when the apps-manifest pattern would fit
- Bypassing the manifest by hard-coding routes into the React app for one-off services
- Telling the operator "visit `https://newthing.yousirjuan.ai/`" when it could have been `https://nephew.yousirjuan.ai/apps/newthing`

### ✅ REQUIRED

- Default to the apps-manifest pattern for every new browser-facing UI
- When in doubt, ask the operator: "Embed in Tower (default) or separate subdomain (exception)?"
- Document the embed_url + the X-Frame-Options strip + the manifest entry as a single coordinated PR
- If a subdomain IS justified, write a one-paragraph note in the PR body explaining which exception applies

### Why the operator named this rule

The rule got its phrasing — "one Tower, one URL" — during the Uptime Kuma fix discussion. The operator framed it as a positive choice (the Tower IS the place, by design) rather than a defensive workaround. Naming it that way every time future agents look at this file should reinforce the architecture, not just the prohibition.

### Cross-references

- `.claude/rules/one-tower-one-url.md` — repo-level binding mirror
- `marvelousempire/nephew` → `data/control-tower-apps.manifest.json` — the canonical apps registry
- `marvelousempire/nephew` → `apps/control-tower/src/pages/EmbedAppPage.tsx` — the renderer
- LEDGER-0016 — original standalone Kuma subdomain that violated this rule
- LEDGER-0017 — failed attempt to retrofit via sub-path routing (Kuma 1.x doesn't sub-path)
- `nephew` PR #27 — the embed-via-manifest fix that established the pattern this rule codifies

---

## Rule 16: Intent-Reality Drift Detector — every operator-intent file MUST be paired with a periodic truthfulness check

<system_reminder>
For every operator-intent file under `/etc/yousirjuan/operator-intent.d/`, there MUST be an automated drift check that compares the intent's claim against actual system state at least every 5 minutes. If the file says "X is stopped" but X is actually running (or vice versa), the system MUST surface that drift to the operator (log + JSON report + notification per Phase 2). The intent-file system is only as truthful as its weakest unverified claim.
</system_reminder>

### Why this rule exists

Rule 13 + LEDGER-0014 made operator-intent files visible to future agents via MOTD banners + `systemctl mask`. On 2026-05-21 the operator himself ran `sudo systemctl unmask + start n8n-nephew.service` at 04:39 UTC because he needed n8n for a workflow. He did NOT then run `intent.sh remove n8n-stopped` to update the intent file. Result: for the next ~7 hours, the intent file claimed n8n was stopped while it was actually running, consuming memory toward the OOM threshold. Nothing in the protocol caught the drift until an agent happened to notice during an unrelated health check.

The protocol prevents **careless** mistakes but not **silent overrides**. Rule 16 closes that gap: every intent claim is periodically re-verified against reality.

### ✅ REQUIRED

Every intent file SHOULD include a `## Drift check` section specifying:

```markdown
## Drift check
check_cmd: <shell command that returns single-line status>
match_output: <expected output (or pipe-separated alternatives)>
```

If absent, a built-in heuristic table in `intent-drift-check.sh` covers common cases (n8n-stopped, gitlab-stopped, etc.). Operator-extensible — add to `heuristic_check()` in the script or use the `## Drift check` section per-file.

The `intent-drift-check.sh` script runs every 5 minutes via systemd timer on the VPS. Drift is logged + written to `/var/lib/yousirjuan/intent-drift-report.json` for UI consumption.

### ❌ FORBIDDEN

- Writing an operator-intent file without a drift-check (built-in OR `## Drift check` section)
- Disabling the `yousirjuan-intent-drift.timer` without operator approval
- Treating an intent file as truthful without checking the drift report

### When YOU (operator or agent) need to override an intent

The right workflow is **still** the LEDGER-0014 protocol:

```bash
# Stop honoring the intent first:
sudo bash <repo>/ledger/LEDGER-0014-operator-intent-protocol/playbooks/intent.sh remove <topic>
# THEN do the operational change:
sudo systemctl start <unit>  # or whatever the override action is
```

NOT:

```bash
# Wrong order — leaves the intent file lying
sudo systemctl unmask <unit>
sudo systemctl start <unit>
# (operator-intent file still says "stopped" → DRIFT detected by Rule 16)
```

### Cross-references

- LEDGER-0019 — the implementation (intent-drift-check.sh + systemd timer + Phase 2 notification plan)
- Rule 13 — the operator-intent protocol this rule audits
- LEDGER-0014 — the playbook + MOTD hook + masking system Rule 13 enforces

---

## Enforcement

This document is the **canonical universal ruleset** for all AI agents, LLMs, and orchestration systems. All systems must load these rules before executing any CLI, Git, or agent assignment operations.

Violations are tracked as incidents in `rules/incidents/` across all repositories.

---

## Origin

Rule 1 (Always Take the Terminal) was established by operator directive on 2026-05-16 after an earlier response where Nephew provided paste-ready commands instead of executing them directly. The operator's correction was unequivocal: "you can take my terminal. its what i gave you rules to do."

Rule 4 (Success/Error Badge) was added on 2026-05-16 as a universal standard for all AI systems, inspired by Perplexity's report card badge system. Every task must display ✅ or ❌ prominently.

Rule 13 (Operator-Intent Protocol) was established by operator directive on 2026-05-21 after an agent reinstalled n8n that a prior agent had deliberately stopped. The operator's verbatim correction was unequivocal: *"another agent reinstalled it because you did not leave healthy notes on what you did to play-well with others. you must add that rule to make good notes so other people and other IA know what you are doing so they can know what to do. global rule please now."* The rule + its host-side enforcement (intent files + MOTD hook + systemd mask) shipped the same day as LEDGER-0014 in marvelousempire/yousirjuan.

Rule 14 (Dual-Push Protocol) was established by operator directive on 2026-05-21 after the same session pushed only to GitHub during an entire multi-PR run, breaking the GitLab-as-sovereign-mirror posture from LEDGER-0005. The operator's verbatim correction was: *"when i ask you to push everything to git, you must push everything to my github repo and my gitlab - make sure that is what you have been doing."* The rule + the `tools/git-dual-push.sh` tool + the binding `.claude/rules/dual-push-protocol.md` shipped the same day.

Rule 16 (Intent-Reality Drift Detector) was established by operator directive on 2026-05-21 after the operator himself accidentally created drift (running n8n while the intent file still said "stopped" for ~7 hours) — exposing that Rule 13 prevented careless mistakes but not silent overrides. The operator's verbatim: *"Yes — ship Rule 16: Intent-Reality Drift Detector."* The rule + LEDGER-0019 implementation (systemd timer + intent-drift-check.sh + JSON report + `.claude/rules/intent-reality-drift.md` mirror) shipped the same day.

Rule 15 (One Tower, One URL) was established by operator directive on 2026-05-21 after an agent shipped Uptime Kuma as a standalone `uptime.yousirjuan.ai` subdomain. The operator's verbatim correction was unequivocal: *"can we just add that to the Control Tower which is the Nephew UI instead of 'uptime.yousirjuan.ai'? […] we have nephew.yousirjuan.ai — you need to make this as an app that can play inside of nephew."* The rule + the binding `.claude/rules/one-tower-one-url.md` mirror + the corrective `nephew` PR #27 (registering uptime-kuma in the apps manifest) shipped the same day.

From that moment forward, all AI executes CLI operations directly, displays success/failure badges, leaves loud cross-agent intent notes on every deliberate state change, dual-pushes every `git push` to both GitHub and GitLab, AND defaults new browser-facing UIs to the Nephew Control Tower apps-manifest embed pattern rather than reflexively creating new subdomains — unless explicitly told otherwise.

**Witnessed by:** Nephew CLOAK · Automata Layer 0 · **Universal to All AI Systems, IDE Agents, LLM Agents, and Human Workers**
