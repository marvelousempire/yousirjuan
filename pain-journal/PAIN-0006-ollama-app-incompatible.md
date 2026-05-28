# PAIN-0006 — Ollama.app requires macOS Sonoma+, refuses to launch on Ventura

**Logged:** 2026-05-19
**Surfaced during:** [iMac MCP setup session](../ledger/LEDGER-0001-imac-mcp-setup/journal.md)
**Severity:** medium — blocked the "click the menubar tray to start the brain" path, didn't block Ollama entirely.

## The pain

`/Applications/Ollama.app` is installed on the iMac. Double-clicking it (or `open -a Ollama`) produces:

```
kLSIncompatibleSystemVersionErr: The app cannot run on the current OS version
```

This iMac runs macOS Ventura 13.7.8 (the latest supported version for the 2017 Intel i5-7500 hardware — Apple dropped support for this Mac in Sonoma). The current Ollama.app requires Sonoma or Sequoia.

The .app is the canonical entry point that 99% of Ollama tutorials assume. Without it, operators following any tutorial hit a wall on Ventura-or-older Macs.

## Why it matters

- **Older Macs are still useful for local AI.** A 64 GB Intel iMac is a perfectly reasonable home for inference and orchestration — much of yousirjuan's value prop is that you don't need bleeding-edge hardware.
- **Apple's hardware-support cycle is shorter than the useful life of the hardware.** Every yousirjuan operator on a 2017–2019 Mac will hit this.
- **The fallback is not obvious.** Operators don't know that the `/usr/local/bin/ollama` CLI is independent of the .app, or that LaunchAgents are the macOS-native way to keep a service running.

## What worked

The CLI binary at `/usr/local/bin/ollama` still ran fine — only the GUI wrapper is broken. `ollama serve` from a terminal works; `ollama list` works; `curl http://localhost:11434/api/tags` works.

We installed a per-user LaunchAgent at `~/Library/LaunchAgents/com.ollama.server.plist` with `RunAtLoad=true` and `KeepAlive=true`. This restores auto-start at login and auto-restart on crash, without the broken .app.

→ See [runbook 04](../ledger/LEDGER-0001-imac-mcp-setup/runbooks/04-ollama-launchagent.md).

## Potential feature

**"Full LaunchAgent installer for legacy macOS."** A one-shot script (or part of the yousirjuan installer) that detects when the Ollama.app is broken or absent, drops a LaunchAgent plist, loads it, and verifies the HTTP endpoint — so older-Mac operators get the same "it just runs" experience the .app provides on Sonoma+.

This dovetails with the broader yousirjuan goal of running on hardware the user already owns, not forcing upgrades.

## Where the fix lives

- Runbook: [04-ollama-launchagent.md](../ledger/LEDGER-0001-imac-mcp-setup/runbooks/04-ollama-launchagent.md)
- Canonical plist: [com.ollama.server.plist](../ledger/LEDGER-0001-imac-mcp-setup/playbooks/com.ollama.server.plist)
- Reproducible target: `make ollama-agent` in [the session Makefile](../ledger/LEDGER-0001-imac-mcp-setup/playbooks/Makefile) (installed copy lives at `~/Developer/mcp-setup/Makefile`, outside this repo)
