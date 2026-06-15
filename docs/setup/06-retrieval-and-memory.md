# Chapter 6 — Retrieval, Memory & Sovereign Vault

**Public-safe:** architecture and discipline only.

> **Deep dive:** [16-knowledge-fabric-rag-quantization.md](./16-knowledge-fabric-rag-quantization.md) · [14-historia-and-operator-memory.md](./14-historia-and-operator-memory.md)

---

## Chapter intents

| Intent | Why |
|---|---|
| **Retrieve before invent** | `nephew_corpus_retrieve` grounds agents in rules/plans |
| **Central bge-m3** | One embed model — identical vectors Mac + DGX |
| **Qdrant on DGX** | Hot index near GPU; NAS holds lake + snapshots |
| **Brain A default** | `nephew-*` collections for agent MCP path |
| **KB cassettes** | Chunks carry provenance — auditable knowledge |
| **Vault + Qdrant pair** | Human wiki + machine index — both sovereign |

---

## Sovereign principle

Family knowledge, rules, plans, financial context, and conversation history are **assets on operator hardware**. Retrieval for agents goes through local Qdrant + local embedding/rerank models — not third-party LLM memory APIs.

Full definition: `marvelousempire/nephew` → `docs/sovereign.md`

---

## Retrieval pipeline (Brain A — agent default)

```text
Agent calls nephew_corpus_retrieve (MCP)
    ↓
tower-api POST /api/v1/retrieve
    ↓
bge-m3 embed query (GPU container)
    ↓
Qdrant vector search (nephew-* collections)
    ↓
bge-reranker-v2-m3 rerank hits (GPU)
    ↓
Ranked chunks returned to agent
```

**Before substantive work:** ground in corpus — rules, plans, app docs — via retrieve, not chat memory alone.

---

## Collection domains (Brain A)

Default collections use the `nephew-` prefix:

| Domain | Typical content |
|---|---|
| `nephew-rules` | Cursor/Claude rules, AI_AGENT_RULES |
| `nephew-historia` | Archive, long-form history |
| `nephew-memory` | Session learnings, meta-library excerpts |
| `nephew-plans` | plans/ folder |
| `nephew-apps` | Sibling app knowledge |
| `nephew-financial` | Family financial docs (gated ingest) |
| `nephew-legal` | Legal reference |
| `nephew-family` | Family-facing guides |
| `nephew-general` | Catch-all |

Reindex: `scripts/index-corpus.mjs` on DGX (systemd timer when installed). Population state varies — verify live before assuming full coverage.

---

## Brain B (doc-rag)

Separate ingestion path for domain document folders:

- Collections named `{financial,legal,family,general,memory}_collection`
- Fed by fleet refresh script rsyncing raw docs → doc-rag ingest API
- Used by graph-service and legacy flows — **not** the default MCP retrieve path

---

## Graph service

LangGraph orchestrator: **classify → retrieve → generate**

- Prefers unified SmartRetriever URL when wired
- Falls back to doc-rag when unset
- Deployed on DGX; wiring is an active integration task

---

## Meta-library (Nephew private brain)

| Store | Location | Role |
|---|---|---|
| Meta-library | `docs/meta-library/` (private submodule) | Compounding teachings, decisions, session artifacts |
| Checkpoints | `data/checkpoints/` | Session resume state |
| Witness chain | `data/witness.json` + `WITNESS.md` | Ed25519 hash-chain sign-offs |
| Deck state | `data/deck-state.json` | In-flight work slices |
| Hermes log | `.nephew/runs/hermes-conversations.jsonl` | Conversation feed for loops |

New lessons: commit inside meta-library submodule first, then bump pointer in nephew parent.

---

## Visual Obsidian / sovereign vault

| Concept | Detail |
|---|---|
| **Vault** | Sovereign Obsidian wiki on NAS-mounted path |
| **Golden profile** | Checked-in Obsidian settings snapshot in nephew `data/obsidian-golden-profile/` |
| **LiveSync** | CouchDB-backed sync for family vault replicas |
| **Cassette library export** | `make vault-sync-cassette-library` → Obsidian wiki tree |
| **Agent knowledge sync** | Scripts push rules/plans/orchestra status into vault |

Visual = wiki/graphs. Jarvis = voice channel only.

Guides: `marvelousempire/nephew` → `docs/family-guides/obsidian-sync.md`, `docs/pockit/Nephew-Max-Obsidian-Sovereign-Front-End.md`

---

## Historia & NAS backups

- NAS holds Historia agent-memory sources and Qdrant snapshot backups
- Hot Qdrant storage remains on DGX for IO/GPU locality (NAS migration = planned)
- Encrypted backup scripts in search-my-engine / fleet refresh tooling

---

## Financial & sensitive corpora

Financial documents ingest into dedicated Qdrant collections with gated access. Never commit secrets — templates use `.env.example` and git hooks block secret-shaped files.

---

## Third retrieval system note

An additional Odysseus + ChromaDB stack may run alongside Brain A/B — reconcile before assuming which brain answers a given query. Documented in operator fleet state map (private).

---

## Related

- [03-software-services.md](./03-software-services.md) — container names and roles
- [05-nephew-orchestration.md](./05-nephew-orchestration.md) — MCP retrieve tool
- [`docs/rag-and-knowledge.md`](../rag-and-knowledge.md) — platform RAG strategy (yousirjuan)
