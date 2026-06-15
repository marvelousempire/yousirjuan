# Chapter 16 — Knowledge Fabric: RAG, Quantization & KB Cassettes

**Public-safe:** architecture, model tiers, and ingestion discipline. No collection secrets or live API keys.

---

## Chapter intents

| Intent | Why |
|---|---|
| **Sovereign memory** | Family knowledge stays on owned hardware — not third-party LLM memory APIs. |
| **One embed model** | Identical vectors everywhere (Mac edge + DGX brain) so retrieval is consistent. |
| **Central Qdrant** | Single source of truth for hot indexes; NAS holds lake + snapshots. |
| **Ground before invent** | Agents call retrieve before substantive work — chat is not source of truth. |
| **KB as cassettes** | Every ingested chunk is a *cassette* with provenance — auditable, replayable, federatable. |
| **Quantize for headroom** | AWQ/FP8 on DGX frees GPU for RAG + voice + multiple models concurrently. |

---

## The knowledge fabric (end-to-end)

```text
Sources (git, vault, Grok pump, Matrix, voice, plans, rules)
        │
        ▼
Micro-slice / chunker (Make-Sense — H2, turn, commit, room context)
        │
        ▼
Embeddings sidecar (:9200) — bge-m3 (canonical vectors)
        │
        ▼
Qdrant on DGX (:6333) — hot index (Brain A + Brain B collections)
        │
        ├─► tower-api POST /api/v1/retrieve
        │         └─► bge-reranker-v2-m3 (:9201) rerank
        │
        ├─► MCP nephew_corpus_retrieve (Cursor / CLOAK agents)
        │
        └─► Hermes / graph-service / matrix-ai-bot consumers
```

### Section intents — pipeline stages

| Stage | Intent | Component |
|---|---|---|
| **Ingest** | Capture everything we learn, continuously | `index-corpus.mjs`, vault-watcher, Grok pump, fleet-refresh |
| **Slice** | Atomic chunks with provenance | Make-Sense micro-slice, H2 walks, git diff hunks |
| **Embed** | Same vectors on every node | bge-m3 GPU container `:9200` |
| **Index** | Fast vector search | Qdrant `nephew-*` and `{domain}_collection` |
| **Rerank** | Quality over raw cosine | bge-reranker-v2-m3 `:9201` (not Qwen3-Reranker-4B on Spark) |
| **Retrieve** | Agent-facing API | tower-api `/api/v1/retrieve` |
| **Learn loop** | Conversations → meta-library → reindex | Hermes log, `nephew_memory_write`, systemd reindex timer |

---

## Brain A vs Brain B

### Intents

| Brain | Intent | When to use |
|---|---|---|
| **Brain A** (`nephew-*`) | Agent default — rules, plans, apps, Historia | **`nephew_corpus_retrieve`** before every substantive agent task |
| **Brain B** (`*_collection`) | Domain document folders — financial, legal, family raw docs | graph-service, doc-rag legacy flows, fleet refresh rsync |

| Brain | Ingestion | Query | Collections |
|---|---|---|---|
| **A** | `scripts/index-corpus.mjs` | tower-api + MCP | `nephew-rules`, `nephew-historia`, `nephew-plans`, `nephew-vault`, … |
| **B** | `fleet-refresh-brain.sh` → doc-rag | doc-rag API `:8004` | `financial_collection`, `legal_collection`, … |

**Agent rule:** Brain A first. Brain B when domain doc-rag is explicitly wired.

Population state varies — verify live collections before assuming full coverage. As of mid-2026, rules + historia are populated; full federation reindex is tracked in nephew plans.

---

## Quantization & inference tiers

### Intents

| Intent | Why quantize |
|---|---|
| **GPU headroom** | DGX Spark runs LLM + embeddings + reranker + voice + ComfyUI — AWQ/FP8 avoids OOM. |
| **RAG latency** | Smaller KV cache + speculative decoding speeds retrieve-augmented chat. |
| **Hybrid routing** | Heavy reasoning on DGX; fast voice/chat on M5 edge (Holler, faster-whisper). |
| **Same prompts everywhere** | Soul + system prompts identical across Hermes, MCP, iMessage — only model tier changes. |

| Tier | Model class | Role | Notes |
|---|---|---|---|
| **Primary chat (Hermes)** | Qwen2.5-32B-Instruct **AWQ** as `nephew:fast` | Family Office daily LLM | vLLM path optional: CUDA graphs, FP8 KV, 32K ctx, ngram speculative decoding for RAG |
| **Deep reasoning** | `nephew:70b`, `nephew:code`, vision variants | Operator / code / vision tasks | Ollama on DGX |
| **Embeddings** | **bge-m3** | Dense + sparse vectors | **Always** `:9200` sidecar — never split embed models across nodes |
| **Rerank** | **bge-reranker-v2-m3** | Cross-encoder after Qdrant hit | GPU `:9201` |
| **Edge STT** | faster-whisper (M5 ANE path roadmap) | Mac-local Jarvis when DGX busy | Plan: CoreML Whisper |
| **Edge TTS premium** | **Holler** (Qwen3-TTS) on M5 | Grok-class daily speech | Kokoro demoted to fallback |
| **Edge TTS clone** | F5-TTS + NeMo Riva on DGX | Operator voice clone | Reference WAV on NAS |

**Why not one giant unquantized model:** contention — voice + RAG + chat + index jobs share one GPU. Quantization + warm-set discipline is the structural answer, not "buy more cloud."

Mac M5 edge: optional light local index (recent 30–90 day cassettes) for disconnected Jarvis; backfill to central Qdrant on reconnect.

---

## KB cassettes (universal cassette spec)

### Intents

| Intent | Why cassettes for KB |
|---|---|
| **Provenance** | Every chunk carries source, mtime, git commit, domain tag, hash |
| **Federation** | Peer repos export/import signed cassette chains |
| **Obsidian sync** | Vault export + `make vault-sync-cassette-library` → wiki tree |
| **Replay** | Re-index from immutable NAS lake without re-scraping sources |
| **Domain boost** | Retrieval can prefer `nephew-financial` vs `nephew-general` by intent |

A **KB cassette** is a structured chunk (JSONL or Qdrant payload):

| Field | Intent |
|---|---|
| `source` | Which repo, vault path, Matrix room, Grok session |
| `domain` | `family`, `financial`, `legal`, `rules`, `historia`, `play`, `code` |
| `slice_type` | H2 section, chat turn, commit hunk, voice transcript, plan item |
| `embedding_model` | bge-m3 version stamp — detect drift on reindex |
| `hash` | Dedup on incremental ingest |

Ingestion harness (nephew): resumable, delta on mtime/hash, walks git + vault + rules + SKILL.md across federation peers.

---

## Collection map (Brain A domains)

| Collection | Intent | Typical content |
|---|---|---|
| `nephew-rules` | Agent behavior ground truth | `.cursor/rules`, AI_AGENT_RULES, AISL packs |
| `nephew-historia` | Long-form archive | Historia repo, session exports |
| `nephew-vault` | Sovereign Obsidian wiki | Visual-Home markdown after vault-index |
| `nephew-plans` | Decision history | `plans/NNNN-*.md` |
| `nephew-memory` | Session learnings | meta-library excerpts |
| `nephew-apps` | Sibling app knowledge | automata, clinic, dustpan, … |
| `nephew-financial` | Gated financial corpus | bank-reader ingest |
| `nephew-legal` | Legal reference | contracts, filings |
| `nephew-family` | Family-facing guides | sign-in, Pockit, services overview |
| `nephew-general` | Catch-all | everything else |

Reindex: `make vault-index-incremental` (vault), `scripts/index-corpus.mjs` (federation), systemd timer on DGX when installed.

**Mac note:** Qdrant is not on open LAN (Plan 0180). Mac agents set `NEPHEW_RAG_RETRIEVE_URL` to DGX tower-api retrieve endpoint.

---

## Meta-library, witness & Historia

### Intents

| Store | Intent | Location |
|---|---|---|
| **Meta-library** | Compounding teachings — not re-discovered each session | `docs/meta-library/` (private submodule) |
| **Witness chain** | Ed25519 sign-offs — auditable delivery | `data/witness.json` |
| **Deck state** | In-flight work slices | `data/deck-state.json` |
| **Hermes log** | Conversation feed for loops | `.nephew/runs/hermes-conversations.jsonl` |
| **Sovereign vault** | Human-readable wiki of record | NAS-mounted Visual-Home |
| **Qdrant** | Machine-readable index of vault + repos | DGX hot storage |

Flow: Grok/chat → pump → vault markdown → vault-watcher → micro-slice → embed → Qdrant → agent retrieve.

See [14-historia-and-operator-memory.md](./14-historia-and-operator-memory.md).

---

## Graph service (LangGraph)

### Intents

| Intent | Why |
|---|---|
| **Unified front door** | classify → retrieve → generate in one orchestrated path |
| **Retriever wiring** | Prefer SmartRetriever / tower-api; fallback doc-rag when unset |
| **Not default for Cursor** | MCP `nephew_corpus_retrieve` remains agent default |

Deployed on DGX `:8005`; `SME_URL` / retriever URL wiring is active integration work.

---

## Third brain note (Odysseus + ChromaDB)

An additional retrieval stack may run alongside Brain A/B. **Reconcile before assuming which brain answers a query.** Operator fleet state map (private nephew doc) is authoritative.

---

## Agent checklist (before substantive work)

1. Call **`nephew_corpus_retrieve`** (or tower-api retrieve) with task keywords.
2. Read matching rules/plans from hits — not chat memory alone.
3. If vault-specific: ensure `nephew-vault` index is current (`make vault-index-incremental`).
4. Cite door URLs canonically when pointing operators at surfaces.
5. Write learnings back via `nephew_memory_write` + meta-library when teaching lands.

---

## Related

- [06-retrieval-and-memory.md](./06-retrieval-and-memory.md) — summary chapter
- [03-software-services.md](./03-software-services.md) — container roles
- [10-m5-max-sovereign-edge.md](./10-m5-max-sovereign-edge.md) — edge sync
- [14-historia-and-operator-memory.md](./14-historia-and-operator-memory.md) — vault + pump
- Nephew: `docs/sovereign.md`, `docs/runbooks/vault-retrieve.md`, `docs/pockit/Nephew-Max-Plan-Full-Working-Draft.md`
