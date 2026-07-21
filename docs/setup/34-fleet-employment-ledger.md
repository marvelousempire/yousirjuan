# 34 — Fleet Employment Ledger: who runs what, how it's wired, and WHY

**Verified:** Tuesday, July 21, 2026 (live probes + cutover receipts, not folklore).
**Law behind every row:** RL-FLEET-OFFLOAD-001 (right work on the right box) ·
RL-SERVICE-AUTH-001 (one crowned authority per stateful service, consumers follow the
registry) · RL-DGX-RUNTIME-001 (vLLM is the DGX brain; Ollama shines on Mac).

This chapter is the answer to "why is anything where it is?" — every machine's
employment, the end-to-end wiring, and the reasoning, with receipts.

## The one-sentence architecture

**The GPU box thinks, the CPU box remembers, the edge box talks, the NAS keeps, the VPS
greets** — and no consumer ever hand-pins a stateful endpoint: they resolve the crown
from `nephew/data/service-authority-registry.json`.

## Employment ledger (per machine)

| Machine | Employed as | Key services | WHY this placement |
|---|---|---|---|
| **DGX Spark** (GB10, 121 GB unified) | **The thinking brain + forge** | vLLM `nephew:prime` (daily LLM), specialty Ollama seats (on-demand only), Gitea forge + Actions, reindex sweeper compute, embed relay `:9200`, **Qdrant MIRROR** `:6333` | The only GB10 — reserved for what needs it: big-LLM inference and GPU work. Every non-GPU tenant evicted (the load-147 thrash, model evictions, and embedder starvation were the bill for hosting extras). vLLM not Ollama: PagedAttention + continuous batching + FP8 are built for this silicon (measured 2026-07-17: 79–154 s Ollama cold reloads vs 2.5 s vLLM warm) |
| **twomac** (iMac 2017 OCLP, i5, 64 GB, 659 GB free) | **The memory — Qdrant live authority** | Native Qdrant `http://10.1.0.6:6333` (`ai.nephew.twomac-qdrant` KeepAlive) | Vector search is pure CPU/RAM — no GPU, ever. This near-idle 64 GB box **beats the contended DGX on search p50 (7.2 ms vs 9.8 ms, consumer vantage)** while freeing the DGX pool for models. Crowned 2026-07-21 via the governed cutover: registry-first resolvers first, 50/50-collection parity replication (node-to-node snapshots), seven-point receipt, E2E 0.978. Receipt: `nephew/data/receipts/qdrant-cutover-twomac-2026-07-21.json` |
| **fivemac** (M5 Max, 128 GB) | **The operator edge — talks, teaches, serves the family** | tower-api `:8088` (family doors, retrieve, chat, SSO), M5 embeddings/rerank (`ai.nephew.m5-embeddings`), voice edge (ANE STT), dev + Council sessions | Strongest edge with the ANE; the operator sits here. Family-facing serving stays at the edge; heavy generation offloads to the DGX (RL-CAP-EVAL-001 evaluates posture live) |
| **NAS** (DXP6800, high-speed home internet) | **The vault** | Model cold store (`/volume2/media/ai-models`), Qdrant snapshot lake, Historia full-tier agent memory | Pull-once/sync-forever family assets; never inference off NAS mounts (cripples IO). The DGX orchestrates mass downloads at home (RL-LOCAL-XFER: never relay through a traveling machine) |
| **VPS** | **The greeter** | Public HTTPS edge only (`nephew-family-edge`), mTLS + family SSO gates | Only public-facing surface; zero core-stack dependence (Sovereign standard — the family runs on owned hardware) |

## End-to-end wiring (the chains that matter)

**Ask → answer (retrieval):** family door → tower `:8088` → embed (M5/relay) → **Qdrant
on twomac** (resolved registry-first) → rerank → grounded answer. Phrase-lexicon
grounding fires first for declared operator senses (the APESHITT lesson).

**Lesson → memory (learning):** teach/ingest → **hot-slice write-through** embeds the
slice into the crown in ~1 s (sweeper-identical chunker/IDs, retry-queued offline,
verified through the real retrieve path — nephew RL-SLICE-EMBED-001) → the 4 h sweeper
pass is the consistency net, not the learning path → orphan reconciler purges retired
doctrine (`make brain-reconcile`).

**Code → main (shipping):** isolated worktree → ship conductor (CAS version lock) →
Gitea PR → Verify green → squash merge → content-verify on origin/main → journal +
capture harvested nightly (isolated-worktree harvest, CAS-leased pushes).

**Strand → salvage (hygiene):** nothing dies dirty — worktrees/stashes salvage into
forge-pushed `refs/salvage/*` before removal (RL-NO-STRAND-001), daily named timer.

## The reasons, compressed (what future agents must not re-litigate)

1. **Placement follows measurement, not vibes.** Every row above cites a probe or
   receipt. Re-litigate only with new measurements that beat them.
2. **Authority is a registry fact, not an env var.** The July fork happened because
   consumers pinned endpoints independently; the fix was structural (registry-first
   resolvers shipped BEFORE the flip), so a cutover is now one registry edit.
3. **The scarce resource defines the architecture.** The GB10's unified pool is the
   family's rarest asset — everything that doesn't need it moves off it.
4. **Learning must not wait on maintenance.** Write-through beats batch for lessons;
   the batch pass exists for consistency, deletes, and enrichment.
5. **Recoverability precedes deletion, always.** Salvage refs, mirrors, rollback
   owners — the fleet deletes only what is provably held elsewhere.

## Cross-references

- ch. 01 hardware (per-node specs + employment lines) · ch. 06 retrieval wiring ·
  ch. 31 inference floor (vLLM/Ollama law)
- nephew: `Nephew/Understandings/RAG/WIRING.md` (ruling banner) ·
  `docs/infrastructure/rag-edge-offload.md` · `data/service-authority-registry.json`
- standard-rag-stack: `understandings/CURRENT-STATE.md` + `WHY-GUIDE.md` 2026-07-21 rulings

**Signed:** Claude Code (Council) > claude-fable-5
