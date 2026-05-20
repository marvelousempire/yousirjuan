# AGENTS.md

**Tool-neutral entrypoint** for any AI agent (Claude Code, Cursor, Aider, Continue, Goose, future tools) landing in this repository. Read this first.

This file is what every other agent surface in this repo points at as the canonical orientation. It's deliberately tool-agnostic — no `claude` / `cursor` / `aider` specifics — so a new tool that hasn't been integrated yet still gets the same starting picture.

---

## What this repo is

**You-Sir Juan** is a private AI infrastructure platform. Hardware + servers + network topology + deployment runbooks + the runtime stack on top. Infrastructure-only by contract — see [`REPOS-CONTRACT.md`](REPOS-CONTRACT.md) for the explicit boundary between this repo and the sibling `nephew` repo (orchestration / personas) and `ai-skills-library` (shared catalogue).

The current platform version is in [`docs/CHANGELOG.md`](docs/CHANGELOG.md) (newest entry at top). The state-of-the-world snapshot for any new session lives in [`HANDOFF.md`](HANDOFF.md).

---

## How knowledge is organized in this repo

| Surface | Path | What you'll find |
|---|---|---|
| **The ledger** (canonical) | [`ledger/`](ledger/) | Every non-trivial task captured as a ticket + runbook(s) + executable playbook(s). Single source of truth for "how to do thing X here." Index + format-choice guide at [`ledger/README.md`](ledger/README.md). |
| **Pain journal** | [`pain-journal/`](pain-journal/) | Problems / frustrations / bottlenecks the operator hit. Each entry points at a yousirjuan-shaped feature. |
| **Rules + discipline** | [`.claude/rules/`](.claude/rules/) | Cross-cutting rules for sessions in this repo: dev-discipline (session opener/closer), changelog-and-versioning, ledger-discipline, cli-snippet-formatting, go-live-path, parallel-surfaces-from-day-one. |
| **Specialist agents** | [`.claude/agents/`](.claude/agents/) | Claude Code agent definitions. Currently: `workflow-debugger` (LEDGER-0002) for YAML/Bash/JS/Python/Excel pipeline failures. |
| **Cursor-readable rules** | [`.cursor/rules/`](.cursor/rules/) | The same conventions exposed in Cursor's rule format. Each file points at the relevant `/ledger/` entry as the deep dive. |
| **Vendored skills catalogue** | [`vendor/ai-skills-library/`](vendor/ai-skills-library/) | Git submodule. Shared skills (engineering, infra, marketing, mobile, visual). Consume by reference; never copy out. |
| **Feature status grid** | [`docs/Feature Ledger.md`](docs/Feature%20Ledger.md) | ✅/✔️/🔜/❌ per feature. Update when status changes. |
| **Incident / near-miss log** | [`docs/Issue-Log.md`](docs/Issue-Log.md) | Lessons learned from bugs. Add entries when something cost time. |
| **State-of-the-world** | [`HANDOFF.md`](HANDOFF.md) | Multi-day session log. Day-by-day timeline. |

---

## How to find what you need

Match the kind of task to the right starting point:

| If the user wants… | Start at | Why |
|---|---|---|
| To replay a task that's been done before | [`ledger/README.md`](ledger/README.md) index → matching `LEDGER-NNNN-*/` entry | The replay command is in the entry's README under "Replay (zero-AI)." |
| To do a new task that's non-trivial | [`.claude/rules/ledger-discipline.md`](.claude/rules/ledger-discipline.md) | Read this rule; create a new `LEDGER-NNNN-*/` from [`ledger/_template/`](ledger/_template/) when finished. |
| To understand a past failure | [`docs/Issue-Log.md`](docs/Issue-Log.md) | Searchable lessons. Often the answer is "this exact thing failed before — here's why." |
| To diagnose a CI / shell / YAML / Python / JS / Excel bug | Invoke the `workflow-debugger` agent | Specialist with the gotcha catalog; [`LEDGER-0002`](ledger/LEDGER-0002-workflow-debugger-agent/) has the full definition. |
| To open a remote VS Code (or Cursor) on the production VPS | [`ledger/LEDGER-0003-vscode-remote-vps/`](ledger/LEDGER-0003-vscode-remote-vps/) | Three runbooks + a triage runbook + an idempotent install playbook. |
| To set up the local dev MCP stack (Cline + Ollama LaunchAgent + workspace MCP) | [`ledger/LEDGER-0001-imac-mcp-setup/`](ledger/LEDGER-0001-imac-mcp-setup/) | `make install` reproduces the whole stack on a fresh Mac. |
| To know what's allowed / forbidden in this repo | [`REPOS-CONTRACT.md`](REPOS-CONTRACT.md) | yousirjuan is infrastructure-only. Personas, orchestration, UX content belong in `nephew`. The `Contract Enforcement` CI workflow blocks PRs that cross this boundary. |
| To match the repo's existing CLI / commit / file-edit conventions | [`.claude/rules/dev-discipline.md`](.claude/rules/dev-discipline.md), [`.claude/rules/cli-snippet-formatting.md`](.claude/rules/cli-snippet-formatting.md) | These are stable across sessions and across agents. |

---

## Operating philosophy — read this FIRST

**Good contracts → good. Careless = stupid. Prudence first; act second.**

Stated by the operator: *"Remember that good contracts are important to maintaining the good, anything else is less than good and we'd want to remain good by being good — prudence is good; careful is opposite careless and careless is equal to stupid and stupid is opposite of good."*

This is the standard against which every action in this codebase is measured. Before any non-trivial action, every agent in this repo runs the pre-action check from [`.claude/rules/contracts-and-prudence.md`](.claude/rules/contracts-and-prudence.md) (mirrored in [`.cursor/rules/contracts-and-prudence.md`](.cursor/rules/contracts-and-prudence.md)):

1. Am I keeping every contract I've stated in this session? If breaking one, re-negotiate first.
2. Can I articulate why this specific action is careful (not careless)?
3. Is the action prudent — reversible or with a stated revert path?
4. If unsure on any of the above: ASK before acting.

Carelessness is, definitionally, stupidity. Stupid is the opposite of good. So we are not careless here.

---

## Universal rules (apply to every agent in this repo)

1. **The ledger is the canonical place for replayable knowledge.** Don't duplicate content elsewhere — link to the relevant ledger entry. New ledger entries copy [`ledger/_template/`](ledger/_template/) and bump the counter in [`ledger/README.md`](ledger/README.md) in the same commit.
2. **Playbooks must be strictly AI-free.** If a task can't be expressed without AI in the loop, ship the runbook only and note `no playbook because <reason>` in the ticket.
3. **Shell snippets emitted to the human go in ONE fenced code block** with `\` continuations and `&&` chaining. Never split a sequence into multiple blocks the operator has to paste separately.
4. **`gh` CLI for every GitHub operation.** Never instruct the operator to open the web UI for commits / merges / pushes / PRs / comments — they're CLI-only.
5. **No mutations to `~/.ssh/config`, `~/.gitconfig`, `~/.zshrc`, `~/.bashrc`, or any home-directory config file without explicit per-edit consent.** If you stated caution about a file earlier in the session, do not edit it next turn without re-asking.
6. **Every commitment ("I'll X" / "I won't Y") is a contract.** Re-negotiate before breaking. Quiet breaks are worse than loud breaks.
7. **State the pipeline stage when reporting "done"** — *committed → pushed → PR'd → merged → deployed* — but inline in the relevant sentence, not as a trailing victory-lap line.
8. **Contract-enforcement CI blocks PRs** that contain persona / interface-UX / onboarding / meta-library content unless the file is allowlisted in [`.github/workflows/contract-enforcement-no-persona.yml`](.github/workflows/contract-enforcement-no-persona.yml). Adding to that allowlist requires explaining why in the workflow file's header comment.
9. **Prudence is required.** See the operating philosophy above. If a planned action can't be defended as careful, it doesn't get taken.

---

## When you're new to this repo

```bash
git status                                         # what's in flight
git log --oneline -10                              # recent shape
gh pr list --state open                            # active PRs
cat HANDOFF.md | head -60                          # state-of-the-world
ls ledger/                                         # task catalog
cat ledger/README.md | head -60                    # ledger conventions + format-choice guide
ls .claude/agents/                                 # specialist agents available
ls .claude/rules/                                  # the rules
cat REPOS-CONTRACT.md | head -40                   # what's allowed
```

Run those once. After that, you know where everything is.

---

## Where this file lives in the agent-knowledge hierarchy

| Layer | Path | Audience |
|---|---|---|
| Canonical (per-task) | `ledger/LEDGER-NNNN-*/` | Anyone replaying a specific task. Has runbooks + playbooks + artifacts. |
| Repo-wide (tool-neutral) | **`AGENTS.md`** (this file) | Any agent landing in the repo. Lists the surfaces and rules without tool-specific hooks. |
| Claude Code-specific | `CLAUDE.md` + `.claude/rules/` + `.claude/agents/` | Claude Code sessions. Same content as AGENTS.md plus Claude-specific configuration (settings.json hooks, agent definitions). |
| Cursor-specific | `.cursor/rules/` | Cursor sessions. Mirrors the conventions in Cursor's rule format. |
| Skills (shared, tool-neutral) | `vendor/ai-skills-library/` | Submodule. Reusable skill catalogues that aren't yousirjuan-specific. |

If you're an agent that doesn't know about `.claude/` or `.cursor/`, you should still get oriented by reading this `AGENTS.md`, then the relevant ledger entry, then the relevant runbook. That's the whole protocol.
