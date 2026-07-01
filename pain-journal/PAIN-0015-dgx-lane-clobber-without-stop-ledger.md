# PAIN-0015 — DGX lane clobber without stop ledger (ReadyPlay vs Nephew)

**First seen:** 2026-07-01  
**Status:** **resolved** — RL-DGX-LEDGER-001 + lane manifest shipped in Nephew

---

## Symptom

- Agent stops `vllm-qwen3-prime` for PAIN-0013 memory relief; ReadyPlay AI Counsel breaks silently
- Next agent starts Ollama fast; vLLM stays down — no record of **why** prime was stopped
- Operator: "we keep clobbering each other" across ReadyPlay, Nephew voice, and memory heals

## Root cause

No shared **lane contract** or **append-only stop ledger**. Every agent used raw `docker stop` / `ollama evict` with reasons only in chat (lost next session).

## Fix (structural — Nephew repo)

| Piece | Path |
|-------|------|
| Lane manifest | `data/dgx-runtime-lanes.json` — `readyplay-prime` lane keeps vLLM hot |
| Ledger | `~/.nephew/run/dgx-service-ledger.jsonl` |
| Status | `make dgx-lanes-status` |
| Lane switch | `make dgx-lane-switch LANE=… REASON=…` |
| Rule | RL-DGX-LEDGER-001 · runbook `docs/runbooks/dgx-runtime-lanes-and-stop-ledger.md` |

## Prevention

- Agents **read ledger before stop**
- Memory relief → `LANE=daily` with reason citing PAIN-0013, `RESUME_WHEN` for ReadyPlay
- ReadyPlay work → `LANE=readyplay-prime` first

## Related

- PAIN-0013 (triple-stack — why stops happen)
- ch.31 §9 lanes · §10 stop ledger