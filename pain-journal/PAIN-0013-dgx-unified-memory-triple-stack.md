# PAIN-0013 — DGX unified memory triple-stack (swap pegged, RAG slows)

**First seen:** 2026-07-01  
**Status:** monitored — handbook shipped; **also compounding factor** for NFS git-store failures (PAIN-0014)

---

## Symptom

- DGX Spark reports **~95% RAM**, **swap 100% full**
- Three zombie processes (two under vLLM parent, one harmless `gnome-remote-de`)
- RAG `/api/v1/retrieve` may spike to 15s+ when reranker is evicted off GPU
- Box feels "hot" even when unrelated work (e.g. permissions) is fine

## Diagnose (30 seconds)

```bash
free -h
nvidia-smi --query-compute-apps=pid,process_name,used_gpu_memory --format=csv
ollama ps
docker ps --format '{{.Names}}' | grep -E 'vllm|higgs'
```

If you see **vLLM prime + Ollama fast + Higgs TTS** together → triple-stack.

## Root cause

The GB10 has **one 121 GiB unified pool**, not separate CPU/GPU banks. Three heavy GPU consumers were pinned simultaneously:

| Stack | ~Size |
|-------|-------|
| vLLM `nephew:prime` | ~50 GB |
| Ollama `nephew:fast` | ~20 GB |
| Higgs sgl-omni TTS | ~26 GB |

Plus always-on RAG sidecars (~11 GB). Swap fills; reranker gets evicted; zombies accumulate under vLLM.

## Fix (structural — not "add swap")

1. **One big LLM lane** — daily = Ollama `nephew:fast`; prime = vLLM on-demand only
2. **Heavy voice off** when big LLM is hot (`docker stop nephew-fleet-higgs-tts-1`)
3. **Ollama governance** — `deploy/dgx/ollama/memory.conf`: `MAX_LOADED_MODELS=1`, `CONTEXT_LENGTH=65536`
4. **tower-api** — `NEPHEW_INFERENCE_BACKEND=dgx-ollama` → Ollama path for daily driver

## Prevention

- Handbook: `docs/setup/31-m5-max-dgx-inference-setup.md` §9
- Nephew: `deploy/dgx/ollama/memory.conf`, `scripts/dgx-big-llm-lane.sh`, heavy cassette contract
- Rule: RL-FLEET-OFFLOAD-001 — offload sidecars to Mac where possible; never leave triple-stack running

## Evidence

After heal (2026-07-01): RAM available **80 GiB** (from ~3.5 GiB), swap **~65%** used (from 100%), GPU ~32 GB (fast + sidecars only).