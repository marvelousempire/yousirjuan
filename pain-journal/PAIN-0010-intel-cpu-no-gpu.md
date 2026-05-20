# PAIN-0010 — Local-model inference on Intel/CPU-only Macs is too slow for tool-calling agents

**Logged:** 2026-05-19
**Surfaced during:** [iMac MCP setup session](../docs/sessions/2026-05-19-mcp-setup/journal.md)
**Severity:** medium — doesn't block "use local models" but quietly degrades agent UX to the point of frustration.

## The pain

The iMac (i5-7500, 64 GB RAM, integrated Intel HD 630 graphics only) runs Ollama happily — but in CPU-only mode. The Ollama log makes it explicit:

```
inference compute id=cpu library=cpu compute="" name=cpu description=cpu
```

For chatting, CPU inference is fine: a 7B model on this CPU generates roughly 3–5 tokens/sec; a 14B closer to 1–2 tok/s. Tolerable for "ask a question, get a paragraph."

For **agent / tool-calling** workflows, it's much worse. Cline-style agents emit lots of tokens per step (think, then call tool, then think about result, then call next tool). A single MCP-driven task that takes 5 seconds on a hosted model can take 2–3 *minutes* on a CPU-only Mac. The model also makes more mistakes on tool format, because the smaller local models that fit comfortably in RAM are weaker at structured output than frontier hosted ones.

## Why it matters

- **One of yousirjuan's premises** is "use the hardware you already own." A 2017 iMac with 64 GB RAM is in that category — but the experience the operator gets locally is markedly worse than the experience on a Sonoma+ Apple Silicon machine.
- **Operators can't tell where the slowness comes from.** They blame the prompt, the model, the tool — when it's actually the absence of GPU acceleration.
- **The pain is silent.** No error, no warning. Just bad latency that erodes trust.

## What worked

The session ended up recommending a **two-mode setup**:

- **Primary path: OpenRouter free tier in Cline.** Free, hosted, fast, GPT-4-class capability for tool-calling. Rate-limited but real.
- **Fallback path: Local Ollama in Cline.** Free, offline, slow — but real when there's no internet or operator doesn't want hosted models seeing the prompt.

Cline can switch providers mid-conversation, so operators can lean on the hosted path for tool-heavy work and the local path for sensitive text.

## Potential feature

**"yousirjuan inference router."** A small local router that exposes a single MCP-client-friendly endpoint and decides per-request which backend to use based on:
- network availability
- prompt sensitivity (tagged by client or detected by classifier)
- expected output length
- preferred model family

Operator picks defaults once; daily flows feel fast on the hosted backend, sensitive flows are kept local, and the failure mode of one backend doesn't block the other.

The VPS Ollama (which has 7.8 GB RAM but a real network connection) and the future M1 Macbook on the tailnet are obvious upstreams for this router. The iMac becomes a thin client into the mesh rather than the inference brain.

## Closely related to

- The decision in HANDOFF.md to make the M1 Macbook the "real Ollama brain" once it's on tailnet.
- [PAIN-0008](PAIN-0008-copilot-paywall.md) — without that pain there's no pressure to use local models at all.

## Where the partial fix lives

No code fix in this session — just a documented recommendation in [runbook 03](../docs/sessions/2026-05-19-mcp-setup/runbooks/03-cline-install-and-mcp.md) to lead with OpenRouter free tier on this iMac, with Ollama as fallback.
