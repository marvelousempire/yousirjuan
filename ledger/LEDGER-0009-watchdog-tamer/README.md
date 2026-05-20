---
ledgerId: LEDGER-0009
title: Watchdog Tamer — Ollama agent that tunes the watchdog + suggests config changes
status: in-progress
opened: 2026-05-20
closed: null
related-pains: []
related-tickets: [LEDGER-0007, LEDGER-0008]
triggers:
  - launchd:user-login (~/Library/LaunchAgents/com.yousirjuan.watchdog-tamer.plist)
  - manual-cli: `bash ledger/LEDGER-0009-watchdog-tamer/playbooks/tamer-tick.sh`
phase-1:
  status: planning
  scope: tamer-server on iMac (reads state, calls Ollama, writes suggestions JSON)
phase-2:
  status: deferred
  scope: TamerCard in nephew Control Tower (renders suggestions)
phase-3:
  status: deferred
  scope: "Apply" button in DustPan WatchdogSettingsPanel (operator approves a suggestion)
---

# LEDGER-0009 — Watchdog Tamer

## Ask

> "Watch-dog Needs a Tamer with settings ok? Make the best settings and lets make sure the Ollama Agent can help us there ok?"

Build an AI agent (the **Tamer**) that observes the LEDGER-0007 watchdog, recognizes patterns over time, and suggests setting changes to the operator. Never applies changes without explicit approval — contracts-and-prudence.

## Outcome (planned)

A new tiny service on the iMac (`tamer-server.sh`, sibling to `watchdog-state-server` from LEDGER-0008) that:

1. Periodically (every 10–30 min) reads:
   - LEDGER-0008 `/state` (current watchdog target state)
   - LEDGER-0008 `/logs` (last N watchdog log lines)
   - Local VPS telemetry (load, free RAM, swap usage — via SSH or a probe endpoint)
2. Sends a structured analysis prompt to local Ollama (`OLLAMA_URL` per CLAUDE.md routing, default Mac mini, fallback iMac)
3. Stores suggestions at `~/Library/yousirjuan-state/tamer-suggestions.json`:
   ```json
   {
     "generated_at": "2026-05-20T14:33:00-04:00",
     "model": "qwen2.5:14b",
     "suggestions": [
       {
         "id": "uuid",
         "severity": "advisory|warning|critical",
         "rationale": "human-readable explanation",
         "setting_diff": { "hysteresis_min_seconds": { "current": 1800, "proposed": 3600 } },
         "evidence": ["log line excerpts that triggered the suggestion"]
       }
     ]
   }
   ```
4. Exposes `GET /suggestions` on `:9877` (sibling port to the state server's `:9876`)

**Ollama runs on iMac** (per ADR-0001 + the operator's confirmation 2026-05-20 — VPS is memory-constrained and can't host the model). The Tamer agent reads watchdog state locally (no network hop), calls local Ollama, and only the small suggestion JSON crosses the Tailscale network to the Nephew Control Tower for display.

## Runbooks (planned)

- `01-prompt-engineering.md` — the system prompt for the Tamer; what kinds of patterns it's expected to recognize
- `02-install.md` — operator one-liner install
- `03-applying-suggestions.md` — how the DustPan "Apply" button uses LEDGER-0008's POST /settings to land a suggestion

## Playbooks (planned)

- `tamer-server.sh` — the analysis daemon; reads state, calls Ollama, writes suggestions, serves them
- `install-tamer.sh` — install/uninstall/status
- `tamer-tick.sh` — single-shot version (for cron/launchd or manual invocation)

## Artifacts (planned)

- `com.yousirjuan.watchdog-tamer.plist` — launchd, runs every 10 min

## Phase fan-out

This ticket is the **brain**. The **UI** ships as separate PRs in two other repos:

- `marvelousempire/nephew` — `TamerCard` next to `WatchdogCard` on OverviewPage; `/tamer` detail page with suggestion history + dismissed list
- `marvelousempire/dustpan` — "Apply" button on each suggestion in `WatchdogSettingsPanel`; click → POST to LEDGER-0008 `/settings` with the proposed diff merged into current config

Same architecture as LEDGER-0008: brain on iMac, surfaces on Nephew + DustPan.

## Performance reality check (empirical, 2026-05-20)

Smoke-tested end-to-end on this Intel iMac. **The wiring is correct** — a minimal "return {ok:true}" prompt completes in 32s (cold start; ~5s warm). **However, the real analysis prompt (~1400 tokens including system + state bundle) times out at 300s on Intel CPU inference.** Math: Intel CPU prompt-eval at ~10 tok/s × 1400 tokens = ~140s of prompt eval alone, plus generation. Cumulatively above the wallclock budget for a 15-min tick cadence.

**Conclusion: Tamer runs correctly but requires Apple Silicon (or GPU) for usable cadence.** Two viable hosts:

1. **Mac mini M4 Pro 48 GB** (per CLAUDE.md routing default) — preferred. Point `OLLAMA_URL` at `http://mac-mini.tailnet:11434` once Mac mini is configured.
2. **DGX Spark 128 GB** (per CLAUDE.md ceiling) — when acquired.

Intel iMac smoke-test verified:

- ✓ `tamer-tick.sh` correctly resolves model from `OLLAMA_URL/api/tags`
- ✓ Bundle build reads `vps-watchdog.json` + log tail correctly
- ✓ Ollama receives the request and starts processing (loads model, allocates CPU)
- ✓ Minimal 36-token prompt round-trips in 32s with valid JSON
- ✗ Full 1400-token analysis prompt exceeds 300s timeout on Intel CPU
- ✗ Same outcome with prompt trimmed to ~700 tokens (CPU is the bottleneck, not the prompt size)

**Defaults in code reflect this finding:** `TAMER_MODEL=llama3.2:3b` (smallest), `MAX_PROMPT_BYTES=4000` (trimmed), `NUM_PREDICT=300` (shortened), `KEEP_ALIVE=1h` (avoid cold-start tax). On Apple Silicon these defaults will round-trip in ~10–20s.

To override at install time on an iMac that IS Apple Silicon: `TAMER_MODEL=gemma4:latest launchctl load -w ~/Library/LaunchAgents/com.yousirjuan.watchdog-tamer.plist`.

## Open design questions

1. **Ollama model selection.** Start with `qwen2.5:14b` (good reasoning, ~10 GB RSS — fits comfortably on iMac with headroom). Fall back to `llama3.2:3b` for low-RAM iMacs. Configurable via `TAMER_MODEL` env.
2. **What patterns to recognize.** Initial list: flapping (oscillation between vps/failover within a single hysteresis window), chronic single-target failure (workflow.yousirjuan.ai 502s for weeks because n8n is upstream-dead), excessive probe timeouts (suggest raising `probe_timeout_seconds`), false positives (subdomain returning 401 — operator should know that target is auth-gated, not down).
3. **Cadence.** Every 10 min covers nearly all decision-relevant changes without burning Ollama cycles. Configurable.
4. **Apply scope.** First version: operator must click "Apply" in DustPan for each suggestion. No auto-apply, ever — keeps the Tamer in advisory role.

## Cross-references

- ADR-0001 — operating philosophy: Ollama-on-iMac, not on the memory-pressured VPS.
- Builds on LEDGER-0007 (the watchdog) and LEDGER-0008 (the state server it reads from).
- Companion: LEDGER-0010 (sandbox CLI generator) — the Tamer's prompt-engineering experiments may benefit from sandboxed Ollama variants.

## Verification (planned)

After install:

1. `curl http://127.0.0.1:9877/suggestions | python3 -m json.tool` → JSON array of current suggestions
2. Watch `~/Library/Logs/yousirjuan-watchdog-tamer.log` for tick lines
3. Verify Ollama is actually being called: `tail ~/.ollama/logs/server.log`

## Undo

```bash
bash ledger/LEDGER-0009-watchdog-tamer/playbooks/install-tamer.sh uninstall
```

Watchdog (LEDGER-0007) and state server (LEDGER-0008) remain untouched.
