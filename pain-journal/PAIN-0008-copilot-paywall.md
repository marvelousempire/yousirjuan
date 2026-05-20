# PAIN-0008 — VS Code's MCP-capable chat is gated behind paid GitHub Copilot

**Logged:** 2026-05-19
**Surfaced during:** [iMac MCP setup session](../ledger/LEDGER-0001-imac-mcp-setup/journal.md)
**Severity:** high — invalidates the default path for any operator unwilling or unable to subscribe.

## The pain

VS Code 1.102+ ships with native MCP support, which is genuinely excellent — but the UI that talks to MCP servers (**Copilot Chat in Agent mode**) requires a **paid GitHub Copilot subscription**. The MCP protocol is open, the MCP servers are open, the VS Code config format is open — but the only first-party way to *use* MCP from inside VS Code is behind a paywall.

Free-tier operators install VS Code, see the MCP documentation, follow it carefully, write a working `mcp.json` — and then have no way to actually call those servers. Nothing in the docs makes the paywall obvious upfront.

## Why it matters

- **Free-tier operators are yousirjuan's natural audience.** The whole pitch of "private AI on hardware you already own" implies operators who don't want recurring subscriptions to large vendors.
- **The cost isn't even in MCP — it's in the LLM.** The protocol just shuttles tool calls. What costs money is the model that decides which tool to call. Pretending those are the same thing locks free operators out of an otherwise-free protocol.
- **It teaches a wrong mental model.** Operators conclude "MCP = paid feature" when in reality the protocol is provider-neutral.

## What worked

Installed [Cline](https://github.com/cline/cline) (open source VS Code extension, `saoudrizwan.claude-dev`). Cline has the same agent-mode UX as Copilot Chat but is **bring-your-own-model**: plug in any LLM provider — Anthropic API, OpenAI API, OpenRouter, Ollama, Groq, LM Studio, etc.

Practical free paths inside Cline:
- **OpenRouter free tier** — sign up, get an API key, pick a model with `:free` suffix (e.g., `deepseek/deepseek-chat-v3.1:free`). Rate-limited but real.
- **Ollama local** — fully free, fully offline, slower on machines without a GPU.

Cline reads its own MCP config (different file, same data shape as VS Code's `mcp.json`), so the same MCP servers (filesystem, Playwright, etc.) work in both clients.

→ See [runbook 03](../ledger/LEDGER-0001-imac-mcp-setup/runbooks/03-cline-install-and-mcp.md).

## Potential feature

**"yousirjuan-recommended VS Code profile."** A profile that pre-installs Cline + a known-good MCP server set, points at a yousirjuan-hosted or locally-running model by default, and explicitly skips Copilot Chat — so operators get a first-class agent UI without ever encountering the paywall. Distribute via VS Code's [Profile sharing](https://code.visualstudio.com/docs/configure/profiles).

This also serves the broader "operator chooses sovereign defaults" theme.

## Where the fix lives

- Runbook: [03-cline-install-and-mcp.md](../ledger/LEDGER-0001-imac-mcp-setup/runbooks/03-cline-install-and-mcp.md)
- Reproducible target: `make cline-ext` + `make cline-mcp` in [the session Makefile](../ledger/LEDGER-0001-imac-mcp-setup/playbooks/Makefile)
