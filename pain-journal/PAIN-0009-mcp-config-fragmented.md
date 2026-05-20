# PAIN-0009 — MCP server definitions live in N different files, one per client

**Logged:** 2026-05-19
**Surfaced during:** [iMac MCP setup session](../ledger/LEDGER-0001-imac-mcp-setup/journal.md)
**Severity:** medium — annoying, error-prone, gets worse as more MCP clients adopt the protocol.

## The pain

Each MCP-capable client stores its server list in its own file with its own conventions:

| Client | Config path | Top-level key |
|---|---|---|
| VS Code (native) | `<workspace>/.vscode/mcp.json` or user config via `MCP: Open User Configuration` | `servers` |
| Cline (VS Code extension) | `~/Library/Application Support/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json` | `mcpServers` |
| Claude Desktop | `~/Library/Application Support/Claude/claude_desktop_config.json` | `mcpServers` |
| Cursor | `~/.cursor/mcp.json` (varies) | `mcpServers` |
| Continue.dev | embedded in `~/.continue/config.json` | various |
| Goose | `~/.config/goose/config.yaml` | YAML, not JSON |

The **server entries** inside (command, args, env) are essentially the same. The **wrapping key** differs. The **file format** mostly doesn't, except where it does (YAML in Goose, embedded in larger config in Continue).

There is no canonical source-of-truth — adding a new MCP server means editing N files.

## Why it matters

- **Drift is inevitable.** Operator wires up filesystem MCP in Cline, forgets to update the VS Code copy, then "filesystem doesn't work in Copilot Chat" becomes a phantom bug.
- **Onboarding is fragile.** Setup docs become "edit this file, then this file, then this file, with slightly different syntax in each."
- **Removing a server is hazardous.** Forgetting one client means a dead server keeps trying to start, with confusing failure modes.

## What worked, for now

The session Makefile (`make install`) writes both the VS Code workspace `mcp.json` and Cline's `cline_mcp_settings.json` from the same hardcoded server list. So one `make install` invocation keeps both in sync.

But it's a workaround, not a fix — the Makefile is the source of truth for two clients on one machine. It doesn't help across machines, doesn't help if a third client (Claude Desktop, Cursor) is added, and doesn't help operators who don't use the Makefile.

## Potential feature

**"yousirjuan MCP registry."** A single canonical YAML/TOML/JSON file in the user's profile (`~/.yousirjuan/mcp-registry.yaml`) that lists MCP servers once. A `yousirjuan mcp sync` command (or LaunchAgent) projects that registry into every detected client's native config format. Adding a server is one edit; sync regenerates all client configs.

Bonus: a `yousirjuan mcp install <server>` command that looks the server up in a curated catalog (npm package, env var requirements, scope hints) and adds it to the registry without operators having to memorize npm package names.

This is genuinely yousirjuan-shaped because:
- It's a **memory/orchestration** problem (one truth, projected into many places).
- It crosses clients, which means operator workflows survive client changes.
- It's something individual MCP clients have no incentive to build.

## Where the partial fix lives

- Runbook: [02-workspace-mcp-config.md](../ledger/LEDGER-0001-imac-mcp-setup/runbooks/02-workspace-mcp-config.md) (VS Code side) + [03-cline-install-and-mcp.md](../ledger/LEDGER-0001-imac-mcp-setup/runbooks/03-cline-install-and-mcp.md) (Cline side)
- Reproducible target: `make install` in [the session Makefile](../ledger/LEDGER-0001-imac-mcp-setup/playbooks/Makefile) writes both files in lockstep.
