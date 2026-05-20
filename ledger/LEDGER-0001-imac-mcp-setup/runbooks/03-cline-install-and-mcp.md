# Runbook 03 — Install Cline + wire its MCP config

**Time:** ~1 minute (extension install) + ~2 minutes (manual provider setup)
**Reversible:** yes
**Prereqs:** `code` CLI on PATH ([runbook 01](01-install-code-cli.md)), `npx` on PATH

## Why

VS Code's native Copilot Chat requires a paid GitHub Copilot subscription. Cline is an open-source VS Code extension that gives you the same agent-mode UX (read/write files, run commands, drive MCP servers) but with **bring-your-own-model**: free local via Ollama, or free-tier via OpenRouter, or paid via Anthropic/OpenAI/etc.

This runbook installs Cline and gives it the same two MCP servers as VS Code's native config, so both clients can use the same toolset.

## Steps

### Install the extension

```
code --install-extension saoudrizwan.claude-dev
```

You'll see `Extension 'saoudrizwan.claude-dev' v<version> was successfully installed.` Already-installed cases print "is already installed" — both outcomes are fine.

### Write Cline's MCP config

Cline reads from `~/Library/Application Support/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json` on macOS. The format uses the `mcpServers` key (Claude Desktop convention) — **different from VS Code's `servers` key**.

1. Ensure the directory exists:
   ```
   mkdir -p ~/Library/Application\ Support/Code/User/globalStorage/saoudrizwan.claude-dev/settings/
   ```

2. Write this content:
   ```json
   {
     "mcpServers": {
       "filesystem": {
         "command": "npx",
         "args": [
           "-y",
           "@modelcontextprotocol/server-filesystem",
           "/Users/averygoodman/Developer"
         ],
         "disabled": false,
         "autoApprove": []
       },
       "playwright": {
         "command": "npx",
         "args": [
           "-y",
           "@playwright/mcp@latest"
         ],
         "disabled": false,
         "autoApprove": []
       }
     }
   }
   ```

   `autoApprove: []` means Cline will prompt before each tool call. Add tool names to that array if you want to skip prompts for safe ones (`["list_directory", "read_file"]` is a common starter set).

### Pick a model provider

Open VS Code, click the **Cline** robot icon in the activity bar. The first launch shows a welcome panel where you pick an API provider.

**Option A — OpenRouter free tier (recommended on this iMac because Intel CPU + no GPU)**

1. Go to https://openrouter.ai → sign in (Google login OK)
2. Profile menu → **Keys** → **Create Key** → copy
3. In Cline: API Provider → **OpenRouter** → paste key
4. Model: `deepseek/deepseek-chat-v3.1:free` (best free tool-caller) or `google/gemini-2.5-flash-preview:free` (faster, weaker)

**Option B — Local Ollama (free, offline, slower on CPU-only machines)**

Requires the LaunchAgent from [runbook 04](04-ollama-launchagent.md) to be loaded, or you can run `ollama serve` manually.

1. In Cline: API Provider → **Ollama**
2. Base URL: `http://localhost:11434` (default)
3. Model: select one returned by `ollama list` — on this iMac as of 2026-05-19 that's `gemma4:latest`, `llama3.2:3b`, or `gemma2:2b`. Larger model = better tool calling = slower on CPU.

## Success criteria

- Cline icon visible in VS Code's activity bar.
- Opening Cline shows a chat panel (not the welcome screen) with your selected provider's model name in the header.
- The Cline panel's **MCP Servers** section lists both `filesystem` and `playwright` with green status indicators.
- A prompt like *"list the projects in ~/Developer"* triggers a tool-call confirmation for `filesystem.list_directory`.

## Approve trust prompts

The first time Cline launches each MCP server, it shows a trust dialog. Approve once per server. This is intentional — local MCP servers can run arbitrary code.

## Undo

```
code --uninstall-extension saoudrizwan.claude-dev
rm -rf ~/Library/Application\ Support/Code/User/globalStorage/saoudrizwan.claude-dev
```

(Removing the whole extension directory deletes chat history and MCP config — back it up first if you care.)

## Notes and gotchas

- **First-run MCP trust prompt cannot be pre-approved programmatically.** It's an interactive consent dialog by design.
- **Cline can edit files outside VS Code's normal edit/undo flow.** Use `git status` / `git diff` to audit after agent runs. Don't run it on uncommitted work you care about.
- **Provider switching mid-conversation is supported.** You can start a chat on Ollama (free, slow) and switch to OpenRouter (faster) when you hit a tricky step.

## Related

- Makefile target: `cline-ext` + `cline-mcp`. See [05-makefile-wrapper.md](05-makefile-wrapper.md).
- Pains that motivated this: [PAIN-0008](../../../pain-journal/PAIN-0008-copilot-paywall.md), [PAIN-0009](../../../pain-journal/PAIN-0009-mcp-config-fragmented.md).
