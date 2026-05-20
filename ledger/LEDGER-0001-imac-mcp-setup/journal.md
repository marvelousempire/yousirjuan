# Session journal — 2026-05-19 — iMac MCP development stack

**Operator:** Avery (`averygoodman` on `imac-avery`)
**Agent:** Claude Opus 4.7 (1M context) via Claude Code CLI
**Working directory:** `/Users/averygoodman/Developer`
**Outcome:** iMac now has a fully wired-up Model Context Protocol (MCP) development stack — VS Code + Cline extension + workspace MCP config + Cline MCP config + Ollama as a persistent LaunchAgent, all reproducible via a single `make install`.

---

## What this session is

Not a feature build. A **tooling-and-environment session** that converts the iMac from "operator workstation with VS Code installed" into "operator workstation where any agent (Cline, Copilot, future ones) can read and write files in `~/Developer` and drive a browser via Playwright, with a free local model as the default brain."

Reproducible via: `cd ~/Developer/mcp-setup && make install`

---

## Chronological narrative — each moment

### Moment 1 — Set up VS Code so I can use MCP servers

**Operator:** "https://code.visualstudio.com/docs/copilot/customization/mcp-servers Setup my VS Code so i can use MCP Server"

Read the VS Code MCP docs. Two scopes possible: user-profile (global) or workspace (`.vscode/mcp.json`). Asked operator which scope + which servers.

**Decision:** Workspace config in `/Users/averygoodman/Developer/.vscode/mcp.json`. Servers: filesystem + Playwright.

**Action:** Created `.vscode/mcp.json` with the two server entries, scoping filesystem to `/Users/averygoodman/Developer`.

→ See [runbook 02](runbooks/02-workspace-mcp-config.md).

### Moment 2 — Do the heads-up items for me

**Operator:** "do the heads up stuff for me"

This referred to three follow-ups I'd flagged: install `code` CLI on PATH, verify VS Code ≥ 1.102, and trust MCP servers on first run.

- Verified VS Code 1.120.0 — well past the 1.102 MCP-GA threshold.
- Symlinked `/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code` → `/usr/local/bin/code`. `/usr/local/bin` was user-writable, no sudo needed.
- The trust prompt can't be dismissed programmatically — it's an interactive UI consent. Left for operator.

→ See [runbook 01](runbooks/01-install-code-cli.md).

### Moment 3 — What can I do with those now?

**Operator:** "what can i do with those now?"

Pure explanation moment. Gave concrete agent-prompts that exercise filesystem (list/search/move files in `~/Developer`) and Playwright (browse, screenshot, scrape, test localhost apps) and the composition between them ("visit each repo on GitHub, get star counts, write a stars.md").

Noted the caveat: agent-mode file writes happen outside VS Code's normal edit/undo flow. Treat them like a script — review with `git diff` after.

### Moment 4 — But that costs money, any open source options?

**Operator:** "but that costs money. any open source options?"

Reality check: MCP is open; the cost in Copilot is the LLM, not the protocol. Surveyed open clients (Cline, Continue.dev, Zed, Goose) with the honest tradeoff that local models on Intel CPU will be weaker at tool calling. Recommended Cline + OpenRouter free tier as the primary path, with Ollama as fallback.

### Moment 5 — Yes, let's do that

**Operator:** "all of this - yes = lets do that - Cline ..."

Multi-stage automation:

1. Installed Cline extension via `code --install-extension saoudrizwan.claude-dev` → got v3.84.0.
2. Discovered the machine is **Intel i5-7500 (no GPU)** — local Ollama will be slow.
3. Discovered Ollama.app is installed but **cannot run on macOS Ventura 13.x** (`kLSIncompatibleSystemVersionErr`).
4. Discovered the `ollama` CLI binary still works standalone, and `gemma4:latest` (~9.6 GB) is already pulled.
5. Started `ollama serve` in the background as a temporary process.
6. Wrote Cline's MCP config at `~/Library/Application Support/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json` (uses `mcpServers` key, distinct from VS Code's `servers` key — same data shape otherwise).
7. Gave operator click-by-click instructions for both Cline+Ollama and Cline+OpenRouter paths (the OpenRouter signup is unautomatable).

→ See [runbook 03](runbooks/03-cline-install-and-mcp.md).

### Moment 6 — Make Ollama persistent

**Operator:** "yes" (to LaunchAgent setup)

Killed the session-bound `ollama serve` (PID 31293). Wrote `~/Library/LaunchAgents/com.ollama.server.plist` with `RunAtLoad=true` + `KeepAlive=true`, pointing at `/usr/local/bin/ollama serve`, logging to `~/Library/Logs/ollama.log`. Loaded with `launchctl load -w`. Verified responding on `:11434` with `gemma4:latest` listed.

→ See [runbook 04](runbooks/04-ollama-launchagent.md).

### Moment 7 — Make a Makefile out of all this

**Operator:** "is there a make ui or make go file we can have to do all of this?"

Bundled every step into `/Users/averygoodman/Developer/mcp-setup/Makefile` with targets `install`, `uninstall`, `status`, `start`, `stop`, `restart`, `check-prereqs`, `help`. Targets are idempotent (guards against existing symlinks, already-installed extensions, pre-loaded LaunchAgents). Variables `DEV_DIR` and `FS_MCP_SCOPE` overridable from CLI.

Verified by running `make status` (all green) and `make install` (no spurious changes).

→ See [runbook 05](runbooks/05-makefile-wrapper.md).

### Moment 8 — Do you have access to my yousirjuan repo?

Confirmed three access vectors: (1) the agent directly, (2) Cline/Copilot via the filesystem MCP scope, (3) GitHub API via authenticated `gh` (logged in as `marvelousempire`).

### Moment 9 — Teach yousirjuan everything we did today

The current moment. Capturing this session as durable knowledge inside the yousirjuan repo:

- **Journal:** this file
- **Tickets:** [tickets.md](tickets.md)
- **Runbooks:** [runbooks/](runbooks/) — five replayable how-tos
- **PAIN entries:** PAIN-0006 through PAIN-0010 in [pain-journal/](../../pain-journal/)
- **HANDOFF.md:** appended a Day-4 entry to §7 + frontmatter update

---

## Surprises and pivots

- **Discrete-GPU assumption was wrong.** Initial recommendation leaned Ollama + Cline. After discovering Intel i5-7500 + CPU-only inference + macOS-Ventura-incompatible Ollama.app, the recommendation flipped to "OpenRouter free tier as primary path, Ollama as fallback." The local path still works — it's just sluggish.
- **Two MCP config formats.** VS Code uses `{"servers": {...}}`; Cline/Claude Desktop use `{"mcpServers": {...}}`. Same server entries either way, but the wrapping key differs and you have to maintain both files if you want both clients to see the same servers. The Makefile writes both.
- **Ollama already had three models pulled** — `gemma4:latest` (9.6 GB), `llama3.2:3b`, `gemma2:2b`. The `make status` output surfaced them.
- **Ollama.app being incompatible didn't break Ollama.** The `/usr/local/bin/ollama` CLI binary works fine — only the GUI wrapper fails to launch. Worth knowing for future similar issues.

---

## What's installed on this iMac after this session

| Component | Where | How to inspect |
|---|---|---|
| `code` CLI shim | `/usr/local/bin/code` → VS Code.app | `readlink /usr/local/bin/code` |
| Cline extension | VS Code user profile, v3.84.0 | `code --list-extensions \| grep claude-dev` |
| Workspace MCP config | `~/Developer/.vscode/mcp.json` | `cat` it |
| Cline MCP config | `~/Library/Application Support/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json` | `cat` it |
| Ollama LaunchAgent | `~/Library/LaunchAgents/com.ollama.server.plist` | `launchctl list \| grep ollama` |
| Ollama logs | `~/Library/Logs/ollama.log` | `tail -f` it |
| Setup Makefile | `~/Developer/mcp-setup/Makefile` | `cd ~/Developer/mcp-setup && make status` |

---

## How a future agent (or future-me) replays any single piece

Each [runbook](runbooks/) is self-contained: prereqs, exact commands, success criteria, and a how-to-undo section. Don't replay them all unless rebuilding from scratch — use `make install` for that.

---

## Open follow-ups (not done this session)

- Operator hasn't signed up for OpenRouter yet — that's the unautomatable handoff.
- Cline's first-run MCP trust prompts haven't been clicked yet (will fire when operator first opens VS Code and starts Cline).
- The Makefile assumes `/usr/local/bin` is writable (true on this Intel Mac, not necessarily on Apple Silicon where Homebrew lives at `/opt/homebrew/bin`). If repurposed for the M1 Macbook, that variable will need updating.
