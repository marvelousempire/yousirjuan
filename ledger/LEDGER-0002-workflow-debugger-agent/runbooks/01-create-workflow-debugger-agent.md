# Runbook 01 — Create the workflow-debugger agent (and extend it later)

**Time:** ~30 seconds to lay down the file. The thinking time to write a *new* agent of this shape is closer to 60 minutes.
**Reversible:** yes (`rm .claude/agents/workflow-debugger.md`)
**Prereqs:** Claude Code installed; this repo cloned at `~/Developer/yousirjuan/`.

## Why

Claude Code supports project-scoped specialist agents at `.claude/agents/<name>.md`. They're invokable via the Agent tool with `subagent_type: <name>` and get a contained reasoning loop with their own tools and system prompt. Useful when:

- The parent agent's task has a sub-task with a deep specialty (e.g. YAML pedantry, security review, performance tuning).
- The sub-task would burn context — letting a sub-agent absorb the rabbit-hole keeps the parent's context window clean.
- The behavior should be reusable across sessions and projects (a single canonical file > re-typing the persona prompt every time).

## Steps

### 1. Decide the agent's shape before writing

Three questions, every time:

- **What's the agent's scope?** (One subject deep, or general-purpose? `workflow-debugger` is one-subject-deep across five languages.)
- **What tools does it need?** Read/Edit/Write/Bash are usually right. Add `WebFetch`/`WebSearch` if the agent will look up syntax docs, error message references, or library docs. Don't grant tools the agent won't use.
- **What's the "knowledge spine"?** The catalog of language-specific gotchas, the diagnostic loop, the anti-patterns — that's what makes the agent specialist, not just "Claude with a sticker." Build the spine first; everything else is delivery.

### 2. Write the file

Path: `.claude/agents/<name>.md`. Structure:

```markdown
---
name: <kebab-case-name>
description: <When to use this agent. One paragraph. The agent's description is what triggers the parent to spawn it — write it as a USE-CASE summary, not a self-description.>
tools: <comma-separated list, OR omit to inherit parent's tools>
---

# <Agent name>

<Identity / scope — 1 paragraph.>

## Mindset — what makes you different

<The single most important section. What distinguishes this agent from "Claude with a different opening line"? Cite the formative experience by name if there is one.>

## The diagnostic loop / The working loop

<Numbered. The agent's step-by-step approach. Encode the *order of operations* the parent will copy-paste-execute.>

## Subject-matter catalog

<By topic. Each topic: 5-15 bullets of known gotchas, edge cases, and high-yield checks. This is where the agent's expertise lives.>

## Anti-patterns — don't do these

<Specific. Cited. Each one corresponds to a real mistake observed in the wild.>

## Verification ritual

<How the agent proves the fix. Should mirror the diagnostic that exposed the bug.>

## When you're invoked

<What the parent should hand the agent. What the agent's output format is.>

## How you relate to other agents/rules in this repo

<Cross-references to .claude/rules/*.md and ledger-discipline.>
```

### 3. Choose tools precisely

For a workflow debugger: `Bash, Read, Edit, Write, Grep, Glob, WebFetch, WebSearch`. Reasoning:

- **Read** — read the failing file
- **Edit** — apply the fix
- **Write** — create test fixtures or minimal repros (used sparingly)
- **Bash** — run the failing thing, run diagnostics (`gh run view`, `python -c '...'`, `bash -n script.sh`)
- **Grep, Glob** — locate references, scan for the bug's footprint
- **WebFetch** — look up specific language docs (YAML 1.2 spec, GitHub Actions runner doc, etc.)
- **WebSearch** — find blog posts or SO answers for cryptic error messages

For other agents the tool set will differ. A code-reviewer might not need `Bash`. A security-reviewer probably needs `Grep` heavily and `Bash` lightly.

### 4. Write the mindset section with a formative example

The agent's mindset is what distinguishes it from a generalist. Cite a real example. For `workflow-debugger`, the formative example is **the PR #9 → PR #10 sequence in this repo**: an em-dash hypothesis that didn't fix the parse error, immediately replaced by a re-look that revealed un-indented lines breaking the YAML literal block. Naming that experience in the agent prompt gives the agent a concrete instance to pattern-match against ("am I doing the PR #9 thing right now?").

When you create a new agent, find the formative experience and cite it in the mindset section. If there isn't one, *the agent isn't ready to write yet* — wait until a real session demonstrates the discipline you want to encode.

### 5. Build the subject-matter catalog by collecting real bugs

For each language / subject the agent covers, list the **high-yield checks** — the things you'd grep for first when symptoms point at that layer. Don't try to be exhaustive. Try to be **first-look useful.**

The `workflow-debugger.md` catalog covers:
- YAML literal-block scalar rules (the #1 bug class)
- Bash quoting tiers, heredocs, BSD vs GNU
- JS CommonJS vs ESM, hoisting, async forEach
- Python indentation, mutable defaults, `__name__`, GIL
- Excel `#VALUE!` / `#REF!` / array spilling / volatile functions

Each topic gets 5–15 bullets. When a new bug surfaces that the catalog missed, **edit the agent file to add the bullet**. The agent learns the way the ledger learns: by carving each new lesson into the canonical file.

### 6. Cross-reference repo rules

Every agent in this repo should explicitly call out:

- `.claude/rules/dev-discipline.md` — staging discipline, pipeline-stage language, no web UI for git ops.
- `.claude/rules/ledger-discipline.md` — non-trivial fixes get a ledger entry.
- `.claude/rules/cli-snippet-formatting.md` — when emitting shell snippets for the human, format as one fenced block.

This keeps the rule layer alive across spawned subagents. Without these references, a sub-agent might commit with `git add -A` or hand the operator four separate code blocks. The whole point of the rule layer is that it's contagious.

### 7. Verify the file loads

```bash
ls .claude/agents/<name>.md && \
head -5 .claude/agents/<name>.md
```

Should print the file and the YAML frontmatter with the `name:` field.

In a Claude Code session inside this repo, the parent agent should now be able to invoke:

```
Agent({ subagent_type: "<name>", description: "...", prompt: "..." })
```

If `<name>` isn't recognized, the agent file isn't being read. Check the path and the frontmatter syntax.

### 8. Promote to user scope (optional)

By default the agent lives at `.claude/agents/` (project scope). To make it available in any Claude Code session on this machine, copy it to `~/.claude/agents/`:

```bash
mkdir -p ~/.claude/agents && \
cp .claude/agents/<name>.md ~/.claude/agents/<name>.md
```

Or use the install playbook: `bash ledger/LEDGER-0002-workflow-debugger-agent/playbooks/install-user-scope.sh`.

## How to extend the agent later

When a new bug pattern surfaces that the agent didn't catch the first time:

1. **Edit `.claude/agents/<name>.md`** — add a bullet to the relevant subject-matter section. Date the addition in a comment if you want lineage (`<!-- added 2026-MM-DD after LEDGER-NNNN -->`).
2. **Don't add a runbook just for the bullet.** That's over-bureaucratization. The agent file is the source of truth; bullets are cheap to add.
3. **If the new pattern is large enough to deserve its own section** (e.g. a whole new language, or a whole new subject like "GraphQL schema bugs"), then yes — extend the catalog, and consider whether the agent's scope has stretched too far (in which case spin off a sibling agent).
4. **If the agent's mindset itself needs updating** (e.g. a new anti-pattern observed), edit the Mindset / Anti-patterns sections. These changes carry more weight than catalog additions, so document them in the ticket of whatever LEDGER entry surfaced the pattern.

## Success criteria

- `.claude/agents/workflow-debugger.md` exists, parses (`head -5` shows the frontmatter), and is reachable via Claude Code's Agent tool.
- The agent's subject-matter catalog covers all 5 listed languages (YAML / Bash / JS / Python / Excel).
- The agent's mindset section cites the PR #9 → PR #10 sequence as its formative experience.
- The agent's "when you're invoked" section specifies the required handoff: failing input, error message, environment, what's been tried.

## Undo

```bash
rm .claude/agents/workflow-debugger.md && \
rm -f ~/.claude/agents/workflow-debugger.md
```

## Related

- Playbook: [`playbooks/install-user-scope.sh`](../playbooks/install-user-scope.sh) — promotes project-scope to user-scope
- Playbook: [`playbooks/agent-definition.md`](../playbooks/agent-definition.md) — durable canonical copy of the agent file
- Rules cited by the agent: [`.claude/rules/dev-discipline.md`](../../../.claude/rules/dev-discipline.md), [`.claude/rules/ledger-discipline.md`](../../../.claude/rules/ledger-discipline.md), [`.claude/rules/cli-snippet-formatting.md`](../../../.claude/rules/cli-snippet-formatting.md)
