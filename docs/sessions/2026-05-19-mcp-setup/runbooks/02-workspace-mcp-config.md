# Runbook 02 — Wire VS Code workspace for native MCP

**Time:** ~30 seconds
**Reversible:** yes (delete the file)
**Prereqs:** VS Code ≥ 1.102 (MCP GA), `npx` on PATH

## Why

VS Code's native Copilot Chat (Agent mode) can call MCP servers, but only if a config tells it which ones to start. Workspace config (`.vscode/mcp.json`) is the right scope when the servers are specific to one project root — it travels with the repo and can be shared via git.

This runbook sets up two general-purpose servers:
- **filesystem** — read/write/search files under a scoped directory.
- **playwright** — browser automation (navigate, click, fill, screenshot).

These two compose well: agents can scrape something with Playwright and write the output via filesystem.

## File location

```
$DEV_DIR/.vscode/mcp.json
```

On this iMac, `$DEV_DIR` is `/Users/averygoodman/Developer`.

## Steps

1. Decide your filesystem-MCP scope. Default: the same directory as the workspace root. Broader scope = more agent power = more blast radius if it misbehaves. Narrow scope = safer.

2. Create the directory:
   ```
   mkdir -p "$DEV_DIR/.vscode"
   ```

3. Write the file with this exact content:
   ```json
   {
     "servers": {
       "filesystem": {
         "command": "npx",
         "args": [
           "-y",
           "@modelcontextprotocol/server-filesystem",
           "/Users/averygoodman/Developer"
         ]
       },
       "playwright": {
         "command": "npx",
         "args": [
           "-y",
           "@playwright/mcp@latest"
         ]
       }
     }
   }
   ```

4. Open VS Code at the workspace root:
   ```
   code "$DEV_DIR"
   ```

5. Start the servers — ⇧⌘P → **MCP: List Servers** → select each → **Start**. The first start downloads the npm packages (~20s each).

6. Accept the **trust** prompt VS Code shows for each server (one-time, per server).

## Success criteria

- ⇧⌘P → **MCP: List Servers** shows both `filesystem` and `playwright` as **Started**.
- In Copilot Chat (⌃⌘I), Agent mode, click the **Tools** button and confirm filesystem + playwright tools are listed.

## Verifying with an actual prompt

In Agent-mode chat:

```
List every README.md under this workspace and give me a one-sentence summary of each.
```

This exercises only the filesystem server. To exercise Playwright too:

```
Open anthropic.com, take a screenshot, save it to scratch/anthropic.png in this workspace.
```

## Undo

```
rm "$DEV_DIR/.vscode/mcp.json"
```

If `.vscode/` is otherwise empty after that, you can remove it too.

## Notes and gotchas

- **`servers` vs `mcpServers`** — VS Code's `mcp.json` uses the top-level key `servers`. Cline / Claude Desktop use `mcpServers`. Same server entries inside, different wrapper. Maintain both if you want both clients pointed at the same MCP servers. The Makefile in [runbook 05](05-makefile-wrapper.md) writes both.
- **API keys in this file are bad practice.** If you ever add an MCP server that needs a secret, use the `inputs` mechanism or environment variables — never hardcode.
- **Scope is enforced by the server, not VS Code.** Whatever path you pass as the filesystem-server arg is the agent's accessible root. Narrow it if you don't trust the model.

## Related

- Makefile target: `workspace-mcp`. See [05-makefile-wrapper.md](05-makefile-wrapper.md).
- Pain that motivated this: [PAIN-0009](../../../../pain-journal/PAIN-0009-mcp-config-fragmented.md).
