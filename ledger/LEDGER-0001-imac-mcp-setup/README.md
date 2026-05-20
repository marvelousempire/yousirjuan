---
ledgerId: LEDGER-0001
title: iMac MCP development stack — VS Code + Cline + Ollama-as-LaunchAgent
status: shipped
opened: 2026-05-19
closed: 2026-05-19
related-pains: [PAIN-0006, PAIN-0007, PAIN-0008, PAIN-0009, PAIN-0010]
related-tickets: []
triggers:
  - manual-cli: make install
  - launchd:user-login (Ollama serve)
---

# LEDGER-0001 — iMac MCP development stack

## Ask

> "https://code.visualstudio.com/docs/copilot/customization/mcp-servers — Setup my VS Code so i can use MCP Server"

…which then expanded into "do the heads-up items," "what can I do with those now," "any open source options," "let's do all of that with Cline + Ollama," "make Ollama persistent," and "give me a Makefile that does the whole thing." Whole arc captured chronologically in [`journal.md`](journal.md).

## Outcome

The 2017 iMac (Intel i5-7500, 64 GB RAM, macOS Ventura 13.7.8) now has a fully wired-up MCP development stack:

- `code` CLI on PATH at `/usr/local/bin/code` → VS Code 1.120.0
- Cline extension (`saoudrizwan.claude-dev` v3.84.0) installed
- Workspace MCP config at `~/Developer/.vscode/mcp.json` for native VS Code Copilot Chat
- Cline MCP config at `~/Library/Application Support/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json` for the Cline agent
- Both clients see the same two MCP servers: **filesystem** (scoped to `~/Developer`) + **playwright** (browser automation)
- Ollama as a per-user `launchd` LaunchAgent at `~/Library/LaunchAgents/com.ollama.server.plist` (with `RunAtLoad=true` + `KeepAlive=true`), auto-starts on login, auto-restarts on crash
- Single-command idempotent reproducibility via the [Makefile](playbooks/Makefile) (`make install`)

Discovered en-route: Ollama.app cannot launch on macOS Ventura ([PAIN-0006](../../pain-journal/PAIN-0006-ollama-app-incompatible.md)), the `code` CLI isn't on PATH after a stock `.dmg` install ([PAIN-0007](../../pain-journal/PAIN-0007-code-cli-not-on-path.md)), Copilot Chat is the only first-party MCP-capable VS Code UI and it's paywalled ([PAIN-0008](../../pain-journal/PAIN-0008-copilot-paywall.md)), every MCP client uses its own config file with different wrapping keys ([PAIN-0009](../../pain-journal/PAIN-0009-mcp-config-fragmented.md)), and this CPU-only Intel iMac is too slow for tool-calling local models ([PAIN-0010](../../pain-journal/PAIN-0010-intel-cpu-no-gpu.md)).

## Runbooks

Five atomic steps, each replayable in isolation:

- [01-install-code-cli.md](runbooks/01-install-code-cli.md) — symlink VS Code's bundled `code` CLI onto PATH
- [02-workspace-mcp-config.md](runbooks/02-workspace-mcp-config.md) — write `.vscode/mcp.json` with filesystem + playwright servers
- [03-cline-install-and-mcp.md](runbooks/03-cline-install-and-mcp.md) — install Cline extension + write its `cline_mcp_settings.json`
- [04-ollama-launchagent.md](runbooks/04-ollama-launchagent.md) — Ollama as a persistent `launchd` LaunchAgent
- [05-makefile-wrapper.md](runbooks/05-makefile-wrapper.md) — the Makefile that bundles all of the above

## Playbooks

- [Makefile](playbooks/Makefile) — `make install` (idempotent). Targets: `install`, `uninstall`, `status`, `start`, `stop`, `restart`, `check-prereqs`, `help`. Overridable vars: `DEV_DIR`, `FS_MCP_SCOPE`. **Canonical installed copy** on this iMac lives at `~/Developer/mcp-setup/Makefile` (outside the repo); the file in this folder is the source of truth.
- [install.sh](playbooks/install.sh) — shell-only sibling of the Makefile, for environments without `make`. Idempotent, logs to `~/yousirjuan-ledger.log`.
- [com.ollama.server.plist](playbooks/com.ollama.server.plist) — canonical LaunchAgent plist. Installed at `~/Library/LaunchAgents/com.ollama.server.plist` via `make ollama-agent` or `bash install.sh ollama-agent`.

## Replay (zero-AI)

On a fresh iMac with VS Code + Node + Ollama already installed:

```bash
git clone https://github.com/marvelousempire/yousirjuan.git ~/Developer/yousirjuan && \
cd ~/Developer/yousirjuan && \
make -C ledger/LEDGER-0001-imac-mcp-setup/playbooks install
```

For just one piece (e.g. re-installing the Ollama LaunchAgent only after losing it):

```bash
make -C ledger/LEDGER-0001-imac-mcp-setup/playbooks ollama-agent
```

## Verification

```bash
make -C ledger/LEDGER-0001-imac-mcp-setup/playbooks status
```

…should print every section with `✓`:
- `code` CLI symlink exists
- Cline extension installed
- Workspace MCP config exists
- Cline MCP config exists
- Ollama LaunchAgent loaded (`launchctl list | grep com.ollama.server`)
- Ollama HTTP responding on `:11434` with at least one model

## Undo

```bash
make -C ledger/LEDGER-0001-imac-mcp-setup/playbooks uninstall
```

This unloads + removes the LaunchAgent, removes the workspace MCP config, resets Cline's MCP config to empty, and removes the `code` CLI symlink. The Cline extension is left installed — remove via VS Code's Extensions UI if desired.

## Notes

- **Why the local Makefile and the canonical one drift.** On this iMac, the Makefile actually used day-to-day lives at `~/Developer/mcp-setup/Makefile` (outside this repo). The copy at [`playbooks/Makefile`](playbooks/Makefile) is the canonical source-of-truth. They should be kept identical — running `diff ~/Developer/mcp-setup/Makefile ledger/LEDGER-0001-imac-mcp-setup/playbooks/Makefile` should produce no output. Consider a follow-up that consolidates: either (a) move the live Makefile into the repo and symlink from `~/Developer/mcp-setup/`, or (b) drop the standalone `~/Developer/mcp-setup/` and always run `make -C ledger/.../playbooks` from a `yousirjuan` clone.
- **Operator follow-ups not in this entry.** OpenRouter signup (unautomatable), first-run MCP trust prompts in Cline (interactive UI consent), and adapting the symlink target for Apple Silicon Macs (`/opt/homebrew/bin` instead of `/usr/local/bin`).
- **Why this is LEDGER-0001.** This entry was the embryo of the ledger pattern itself — the [`ledger/README.md`](../README.md) format-choice guide, helper-function snippet, and triggers table all crystallized from the work done here.
