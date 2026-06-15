# Chapter 3 — Software & Services

**Public-safe:** logical service roles only. No port numbers or live URLs.

---

## Stack overview

The Family Office runs a **Docker-first fleet** on the DGX, orchestrated from git-tracked compose files in the `nephew` monorepo. The Mac fleet runs development gateways, Pockit, and Cursor/Claude sessions. The VPS runs the public edge and Clinic.

```text
Family browser / iOS
    ↓
Public edge (VPS) ──WG──► DGX fleet (containers)
    ↓                           ↓
Pockit / Control Tower      tower-api, RAG, LLM, voice
(local Mac gateway)              ↓
                            NAS backups
```

---

## Core runtime layers

| Layer | Technology | Role |
|---|---|---|
| **Inference** | Ollama on DGX | Local LLM serving (Hermes / family chat models) |
| **API** | tower-api (Node/Express) | Auth, chat, retrieve, voice hooks, family onboard |
| **Vector DB** | Qdrant | Embeddings storage for RAG |
| **Embeddings** | bge-m3 (GPU container) | Dense + sparse vectors for retrieve |
| **Reranker** | bge-reranker-v2-m3 (GPU) | Cross-encoder rerank after Qdrant hit |
| **Doc RAG** | doc-rag service | Brain B — domain document collections |
| **Graph** | LangGraph graph-service | classify → retrieve → generate orchestration |
| **Voice STT** | Whisper container | Speech-to-text |
| **Voice TTS** | Fish Speech / speaches | Text-to-speech |
| **Chat UI** | Open WebUI | Multi-user local chat (deployed; health monitored) |
| **Matrix** | Synapse + Element | Family private chat |
| **Git forge** | Gitea on DGX | Self-hosted git; objects on NAS |
| **Workflows** | n8n | Automation (internal bind) |
| **Observability** | Prometheus + Grafana | Metrics and dashboards |
| **Image gen** | ComfyUI | GPU image workflows |
| **Static vault** | Quartz | Sovereign wiki publish path |
| **Edge proxy** | Caddy / family-edge | Public HTTPS termination on gated stack |
| **Clinic** | clinic repo on VPS | Universal diagnostic hospital |

---

## Nephew-specific surfaces

| Surface | Implementation | Role |
|---|---|---|
| **Pockit** | Vanilla JS shell in `containers/nephew-ct/family-hub/` | Family player console — dual rail (players + cassettes) |
| **Control Tower** | React/Vite app in `apps/control-tower/` | Operator dashboard, cassette grid, hello chat |
| **Tape gateway** | `scripts/family-tape-gateway.mjs` | Hostname-based door routing on operator Mac |
| **Cassette framework** | `src/cassette-framework/` | Registry, resolve, door URLs, changelog badges |
| **CLOAK MCP** | `src/mcp/cloak-server.js` | 28 tools for session, dispatch, witness, Hermes |
| **Loop daemon** | `bin/nephew` | Background tick, learning, federation |

Product vocabulary: `marvelousempire/nephew` → `docs/product-stack-glossary.md`

---

## Brain A vs Brain B (retrieval split)

Two collection schemes coexist in Qdrant:

| Brain | Ingestion | Query path | Collections |
|---|---|---|---|
| **Brain A** | `index-corpus.mjs` (nephew rules, memory, plans, apps) | tower-api `/api/v1/retrieve`, MCP `nephew_corpus_retrieve` | `nephew-*` prefix |
| **Brain B** | `fleet-refresh-brain.sh` → doc-rag ingest | doc-rag API; graph-service fallback | `{domain}_collection` suffix |

Agents doing substantive work should call **`nephew_corpus_retrieve`** (Brain A path) before inventing answers.

---

## Hermes (Family Office LLM)

- Runs as a hardened Docker container on the DGX.
- Serves chat completions via local Ollama (primary model: large Qwen-class family model).
- Every channel loads `data/nephew-soul.md` as system prompt.
- Conversations log to `.nephew/runs/hermes-conversations.jsonl` for meta-library loops.
- Mac M5 Max can run parallel dev inference with identical prompts for agent development (Plan 0040 unification).

Runbook: `marvelousempire/nephew` → `docs/infrastructure/dgx-spark-hermes-docker.md`

---

## Voice stack

| Component | Role |
|---|---|
| Whisper | STT — transcribe operator/family speech |
| Fish Speech / speaches | TTS — reply audio |
| iMessage / Telegram bridges | Channel adapters polling local chat DB or gateway |
| Mac ANE path | Dev/edge low-latency STT on M5 Max without cloud |

Status: voice containers deployed on DGX; VPS edge drop-in may be pending.

---

## WordPress & embed cassettes

Family WordPress mirrors and embed apps (Gitea, Matrix Element, ComfyUI, Vault) register as **cassettes** in the nephew catalogue — iframe or backend-backed surfaces inside Pockit/Control Tower, not separate silos.

SOP: `marvelousempire/nephew` → `docs/sop/update-the-cassette.md`

---

## You-Sir Juan platform services (this repo)

| Area | Path | Role |
|---|---|---|
| API | `api/` | Associate Agent routing, personas |
| Broker | `broker/` | Verb-based local action broker |
| Runtime | `runtime/` | Queue coordination |
| Tools | `tools/` | Init, backup, restore, health |
| VPS configs | `vps/` | nginx, fail2ban, iptables templates |
| Vendor | `vendor/` | ai-skills-library, ruflo, claude-mem submodules |

Bootstrap: `bash tools/init-client-assistant.sh` after submodule init.

---

## Container management preference

- **Colima-backed Docker** on Mac for local dev.
- **Dockyard** as container management surface where applicable.
- **DGX**: native Docker Compose stacks from nephew `deploy/dgx/`.

---

## What is genuinely unbuilt vs deployed (conceptual)

| Area | State (2026-06) |
|---|---|
| RAG Brain A full collections | Partial — rules + historia populated; full reindex tracked in plans |
| Redis short-term memory | Unbuilt — file-based checkpoints today |
| Open WebUI | Deployed — needs health + edge gate polish |
| LangGraph | Deployed — needs unified retriever URL wiring |
| Voice STT/TTS | Deployed on DGX |
| NAS live Qdrant storage | Queued — snapshots on NAS today, hot index on DGX |

Live verification: operator-only `docs/infrastructure/dgx-rag-and-fleet-state.md` in nephew repo.

---

## Related

- [05-nephew-orchestration.md](./05-nephew-orchestration.md) — Pockit + CLOAK
- [06-retrieval-and-memory.md](./06-retrieval-and-memory.md) — RAG detail
- [04-repo-ecosystem.md](./04-repo-ecosystem.md) — which repo owns what code
