# Universal Nephew Rules — Global AI Operating System

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

## Enforcement

This document is the **canonical universal ruleset** for all AI agents, LLMs, and orchestration systems. All systems must load these rules before executing any CLI, Git, or agent assignment operations.

Violations are tracked as incidents in `rules/incidents/` across all repositories.

---

## Origin

Rule 1 (Always Take the Terminal) was established by operator directive on 2026-05-16 after an earlier response where Nephew provided paste-ready commands instead of executing them directly. The operator's correction was unequivocal: "you can take my terminal. its what i gave you rules to do."

Rule 4 (Success/Error Badge) was added on 2026-05-16 as a universal standard for all AI systems, inspired by Perplexity's report card badge system. Every task must display ✅ or ❌ prominently.

Rule 13 (Operator-Intent Protocol) was established by operator directive on 2026-05-21 after an agent reinstalled n8n that a prior agent had deliberately stopped. The operator's verbatim correction was unequivocal: *"another agent reinstalled it because you did not leave healthy notes on what you did to play-well with others. you must add that rule to make good notes so other people and other IA know what you are doing so they can know what to do. global rule please now."* The rule + its host-side enforcement (intent files + MOTD hook + systemd mask) shipped the same day as LEDGER-0014 in marvelousempire/yousirjuan.

From that moment forward, all AI executes CLI operations directly, displays success/failure badges, AND leaves loud cross-agent intent notes on every deliberate state change — unless explicitly told otherwise.

**Witnessed by:** Nephew CLOAK · Automata Layer 0 · **Universal to All AI Systems, IDE Agents, LLM Agents, and Human Workers**
