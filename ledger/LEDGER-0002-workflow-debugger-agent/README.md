---
ledgerId: LEDGER-0002
title: workflow-debugger agent — supreme debugger for YAML/Bash/JS/Python/Excel pipeline bugs
status: shipped
opened: 2026-05-20
closed: 2026-05-20
related-pains: []
related-tickets: [LEDGER-0001]
triggers:
  - manual-cli: invoke via Claude Code's Agent tool with subagent_type=workflow-debugger
---

# LEDGER-0002 — workflow-debugger agent

## Ask

> "I need you to create an agent for me that hones those exact skills and thinking logic and capabilities and the subject-matter focused you showed when you solved that exact issue we had. You just demonstrated. Every skill and rule and feedback you gave yourself among all your agents, harness that into one supreme agent that solves Workflow issues, especially that of yaml flows and Bash series and javascript and python and excel."

Triggered immediately after the agent shipped PR #10 fixing `release-intel-mac.yml`'s un-indented `run: |` block. The operator wanted the diagnostic discipline + cross-language gotcha catalog + verification ritual demonstrated on that bug, captured as a reusable agent.

## Outcome

Created `.claude/agents/workflow-debugger.md` — a Claude Code project-scoped agent definition. Once this entry merges to main, anyone invoking the Agent tool with `subagent_type: workflow-debugger` from a session in this repo gets a specialist that:

- **Diagnoses symptom-first.** Reads error message + behavior + environment + run logs *before* touching code. Maps each signal to a layer (parse vs runtime; YAML vs Bash; BSD vs GNU; Node 18 vs 22).
- **Discards wrong hypotheses fast.** Doesn't elaborate. Doesn't bolt fixes on. Goes back to step 2 with the new evidence the wrong hypothesis produced. (Encoded from the actual PR #9 → PR #10 sequence in this repo: PR #9's em-dash fix didn't fix the parse error; PR #10's heredoc-with-sed-strip did.)
- **Carries a high-yield gotcha catalog** for YAML, Bash, JavaScript/Node, Python, and Excel — the specific known-traps in each language that pipeline bugs cluster on.
- **Verifies with the same diagnostic that revealed the bug** — symptoms can fade for the wrong reason; don't trust silence.
- **States root cause + fix + verification + out-of-scope + pipeline stage** in every report.
- **Follows the repo's existing rules** — `dev-discipline.md`, `ledger-discipline.md`, `cli-snippet-formatting.md`.

## Runbooks

- [01-create-workflow-debugger-agent.md](runbooks/01-create-workflow-debugger-agent.md) — how this agent was conceived and how to extend it as new gotcha patterns are discovered

## Playbooks

- [agent-definition.md](playbooks/agent-definition.md) — canonical copy of `.claude/agents/workflow-debugger.md` (mirrored here as the durable record; the live copy at `.claude/agents/` is what Claude Code loads)
- [install-user-scope.sh](playbooks/install-user-scope.sh) — copies the agent definition to `~/.claude/agents/` so it's available outside this repo (in any Claude Code session, anywhere on this machine)

## Replay (zero-AI)

Already installed at `.claude/agents/workflow-debugger.md` once this entry merges to main. To make it user-scoped (available in any Claude Code session, not just yousirjuan):

```bash
cd ~/Developer/yousirjuan && \
bash ledger/LEDGER-0002-workflow-debugger-agent/playbooks/install-user-scope.sh
```

## Verification

In Claude Code, in any session inside `~/Developer/yousirjuan/`:

```bash
ls .claude/agents/workflow-debugger.md && \
head -5 .claude/agents/workflow-debugger.md
```

Should print the file and the YAML frontmatter (`name: workflow-debugger`, the `description:` line, etc.).

Functional test — give the agent a real workflow bug to chew on and check it returns a report with the five required sections (root cause / fix / verification / out of scope / pipeline stage):

> "Spawn the workflow-debugger agent on this failing GitHub Actions workflow — `.github/workflows/foo.yml` is returning a 0-second failure with no log output."

The agent should ask one clarifying question (or proceed on assumptions) then diagnose, not guess.

## Undo

```bash
cd ~/Developer/yousirjuan && \
rm .claude/agents/workflow-debugger.md && \
rm -f ~/.claude/agents/workflow-debugger.md
```

The agent disappears from the Agent tool's known-types list on next Claude Code session.

## Notes

- **Why this is an agent, not a skill, not a rule.** A skill is a procedure template (how to do task X). A rule is repo discipline (always do Y when shipping). An *agent* is a distinct persona with its own tools, system prompt, and reasoning loop — invokable for a contained task with full delegation. Workflow debugging matches the agent shape: it's a contained task, it benefits from focus, and the parent agent shouldn't lose context to the rabbit-hole of YAML semantics.
- **Why project-scoped first.** Living at `.claude/agents/workflow-debugger.md` means it's only available inside yousirjuan sessions. The install playbook can promote it to user scope (`~/.claude/agents/`) if the operator wants it everywhere. Keeping it project-first avoids polluting the global agent namespace before it's proven.
- **Lineage.** The agent's mindset section names the LEDGER-0001 / PR #9 → PR #10 sequence explicitly as the formative experience. Future agents reading this file will know what "discard wrong hypotheses fast" actually looked like in practice.
- **Subject-matter coverage** is the catalog I'd reach for first — not exhaustive. As real bugs surface that aren't covered, the agent file gets edited and a runbook captures the new pattern. The agent learns the way the ledger learns: by carving each new lesson into the file.
- **No PAIN entries.** This isn't a pain that was solved — it's a capability that was added. PAIN entries describe problems the operator hit; this one describes a permanent capability upgrade.
