# Tickets — 2026-05-19 session

Work units delivered in this session, plus the pain entries that motivated each. Every TICKET below has a corresponding artifact (runbook, config file, or Makefile target) that lets a future agent replay or verify the work.

---

## TICKET-2026-05-19-01 — Wire VS Code workspace for native MCP

**Status:** done
**Pains addressed:** [PAIN-0008](../../pain-journal/PAIN-0008-copilot-paywall.md), [PAIN-0009](../../pain-journal/PAIN-0009-mcp-config-fragmented.md)
**Runbook:** [02-workspace-mcp-config.md](runbooks/02-workspace-mcp-config.md)
**Artifact:** `/Users/averygoodman/Developer/.vscode/mcp.json`

Created the workspace MCP config so VS Code's native chat (Copilot Chat in Agent mode) can call MCP servers when the operator opens `~/Developer`. Filesystem server scoped to `~/Developer`; Playwright server with no scope (drives a real browser).

**Verification:** open VS Code → ⇧⌘P → **MCP: List Servers** → both should appear and be startable.

---

## TICKET-2026-05-19-02 — Install `code` CLI on PATH

**Status:** done
**Pains addressed:** [PAIN-0007](../../pain-journal/PAIN-0007-code-cli-not-on-path.md)
**Runbook:** [01-install-code-cli.md](runbooks/01-install-code-cli.md)
**Artifact:** symlink `/usr/local/bin/code` → `/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code`

Without the shim, you can't run `code .` to open a project from the terminal, and you can't run `code --install-extension` from scripts (which the Cline install step needs).

**Verification:** `code --version` returns `1.120.0 …`.

---

## TICKET-2026-05-19-03 — Install Cline + wire its MCP config

**Status:** done
**Pains addressed:** [PAIN-0008](../../pain-journal/PAIN-0008-copilot-paywall.md), [PAIN-0009](../../pain-journal/PAIN-0009-mcp-config-fragmented.md)
**Runbook:** [03-cline-install-and-mcp.md](runbooks/03-cline-install-and-mcp.md)
**Artifacts:**
- Cline extension `saoudrizwan.claude-dev@3.84.0` installed in VS Code
- `~/Library/Application Support/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json` populated with filesystem + Playwright

Cline's MCP config uses the `mcpServers` key (Claude Desktop format), distinct from VS Code's `servers` key. Same server entries; different wrapper.

**Verification:** open Cline panel in VS Code → MCP Servers section → both servers listed.

**Open follow-up:** operator needs to either (a) sign up for OpenRouter and paste an API key into Cline, or (b) select Ollama as the provider with `gemma4:latest`. The signup is unautomatable.

---

## TICKET-2026-05-19-04 — Persistent Ollama via LaunchAgent

**Status:** done
**Pains addressed:** [PAIN-0006](../../pain-journal/PAIN-0006-ollama-app-incompatible.md), [PAIN-0010](../../pain-journal/PAIN-0010-intel-cpu-no-gpu.md)
**Runbook:** [04-ollama-launchagent.md](runbooks/04-ollama-launchagent.md)
**Artifact:** `~/Library/LaunchAgents/com.ollama.server.plist` (loaded)

The Ollama.app wrapper fails on macOS Ventura 13.x, but the `ollama` CLI binary still serves correctly. A LaunchAgent gives us auto-start at login and auto-restart on crash without the broken .app.

**Verification:** `launchctl list | grep com.ollama.server` shows PID + status 0; `curl http://localhost:11434/api/tags` returns the model list.

---

## TICKET-2026-05-19-05 — Single-command Makefile wrapper for the whole stack

**Status:** done
**Pains addressed:** all five PAIN entries — this is the durable artifact that prevents redoing the same dance on another machine
**Runbook:** [05-makefile-wrapper.md](runbooks/05-makefile-wrapper.md)
**Artifact:** `/Users/averygoodman/Developer/mcp-setup/Makefile`

Targets: `install`, `uninstall`, `status`, `start`, `stop`, `restart`, `check-prereqs`, `help`. Idempotent — guards against existing state. Variables `DEV_DIR` and `FS_MCP_SCOPE` overridable on the command line for redeployment.

**Verification:** `cd ~/Developer/mcp-setup && make status` reports every piece as `✓`.

---

## TICKET-2026-05-19-06 — Capture this session as durable repo knowledge

**Status:** in-progress (this ticket creates itself)
**Pains addressed:** institutional memory — the canonical yousirjuan concern
**Artifacts:**
- This [journal](journal.md)
- This file ([tickets.md](tickets.md))
- Five [runbooks](runbooks/)
- Five new PAIN entries (`PAIN-0006` … `PAIN-0010`) in [`pain-journal/`](../../pain-journal/)
- Day-4 entry appended to [HANDOFF.md](../../HANDOFF.md) §7

Goal: any future agent (or future-Avery) opening the yousirjuan repo can replay any single piece of this session, understand why each decision was made, and find the related operational pain it solved.

---

## Naming convention used

`TICKET-YYYY-MM-DD-NN` — date of the session, two-digit sequence within the session. Local to the session folder rather than a global counter, so multiple sessions can be captured in parallel without collision. PAIN IDs remain global (`PAIN-NNNN`) because they're cross-cutting.
