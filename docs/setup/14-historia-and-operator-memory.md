# Chapter 14 — Historia, Vault & Operator Memory

**Why this chapter exists:** Hardware and software docs tell you **what runs where**. **Historia** tells you **what you decided, said, and learned** across sessions — Grok exports, vault notes, agent homes, and the Qdrant `nephew-historia` / `nephew-vault` collections. When onboarding an agent, check Historia **after** `docs/setup/` and **before** improvising.

---

## What Historia is (three layers)

| Layer | What | Where |
|---|---|---|
| **Historia repo / app** | Long-form memory product in the fleet | CT cassette; VPS `/opt/historia`; DGX checkout `~/Developer/historia` |
| **Sovereign Obsidian vault** | Human + agent wiki — Visual-Home, plans, Clinic mirrors, Pockit wiki | NAS → `/Volumes/historia/nephew-sovereign-vault` (Mac) · `/mnt/nas/historia/nephew-sovereign-vault` (DGX) |
| **RAG collections** | Searchable chunks for agents | Qdrant `nephew-historia`, `nephew-vault` (Brain A via tower-api retrieve) |

**Visual** = Obsidian vault front-end. **Jarvis** = voice only. The vault home note is **Visual-Home.md** (retired name: Jarvis-Home).

---

## Vault layout (high-signal paths)

| Path in vault | Contents |
|---|---|
| `Visual-Home.md` | Landing — graphs, links, orchestra HUD |
| `03-Wiki/` | Pockit taxonomy, Clinic case mirrors, runbooks |
| `06-Graphs/` | Live knowledge graph exports |
| `07-Agent-Routing/` | Orchestra registry, agent paste blocks (Cursor, Grok, Claude, …) |
| `NEPHEW-AGENT.md`, `AGENTS.md`, `CLAUDE.md` | Agent context stubs synced from repos |
| `02-Live-Capture/` | Gap-heal reports, session pumps |
| `.obsidian/` | Golden profile — themes, plugins, LiveSync config |

**Golden profile in git (no secrets):** `marvelousempire/nephew` → `data/obsidian-golden-profile/`  
Apply on fresh Mac: `make bootstrap-obsidian` / `make visual-obsidian-full`

---

## NAS agent homes

| Path | Role |
|---|---|
| `/mnt/nas/historia/agent-homes` | Per-agent memory / plan sync on NAS |
| Historia NFS exports | Durable backing for vault + backups |

Mac operators mount **`/Volumes/historia`** — required before vault scripts run.

---

## How chat history becomes memory

```text
Grok / Cursor / Claude sessions
    ↓
Grok Session Pump (~/.grok/sessions → Micro Slices)
    ↓
Vault staging + watchers (vault-watcher LaunchAgent on Mac)
    ↓
index-vault-corpus.mjs / index-corpus.mjs
    ↓
Qdrant nephew-vault + nephew-historia
    ↓
nephew_corpus_retrieve / tower-api /api/v1/retrieve
```

**Operator phrase:** if an agent needs "everything we said," start with:

1. **`nephew_corpus_retrieve`** — domains `vault`, `historia`, `rules`, `plans`  
2. **Vault search** — Obsidian or exported `06-Graphs/live-knowledge-graph.md`  
3. **Journal/reports** in nephew repo — dated audit receipts (e.g. 2026-06-15 hardware audit)  
4. **Clinic cases** mirrored under `03-Wiki/Clinic/` in vault  

---

## Qdrant collections (agent retrieval — Jun 2026 audit)

| Collection | Approx points | Source |
|---|---|---|
| `nephew-rules` | ~3400+ | Rules, AI_AGENT_RULES |
| `nephew-vault` | ~500+ | Sovereign vault ingest |
| `nephew-historia` | ~32+ | Historia app / archive (partial — reindex expands) |
| `memory_collection` (Brain B) | ~12000+ | doc-rag domain docs |

**Mac rule:** Qdrant is **not** reachable from LAN Wi-Fi (Plan 0180 bind). Mac agents **must** use tower-api retrieve on DGX — not direct `:6333`.

---

## Mac LaunchAgents tied to memory (FIVEMAC pattern)

| Agent | Role |
|---|---|
| `com.nephew.tower-api` | Local API proxy |
| `com.marvelousempire.nephew.vault-watcher` | Vault change → fabric |
| `ai.marvelousempire.nephew.sovereign-vault-bridge` | Vault sync bridge |
| `ai.yousirjuan.nephew.livesync-bridge` | LiveSync bridge |
| `ai.nephew.m5-voice-edge` | Voice edge (related — voice turns also become slices) |

---

## What to check when you feel something is "missing from setup docs"

| Gap type | Check here |
|---|---|
| **Physical wiring / Protectli** | [13-physical-topology-protectli.md](./13-physical-topology-protectli.md), `home-network-full-architecture-report.md` |
| **Live fleet truth** | Nephew `Journal/reports/2026-06-15-hardware-sovereign-audit.md` |
| **Voice / M5 decisions** | [11-voice-parakeet-premium-stack.md](./11-voice-parakeet-premium-stack.md), nephew CHANGELOG Intent sections |
| **Session decisions** | Vault `02-Live-Capture/`, meta-library (private submodule in nephew) |
| **Clinic fixes** | Vault `03-Wiki/Clinic/`, clinic repo |
| **Plans not yet shipped** | Nephew `plans/` — e.g. 0197 NAS Docker, 0151 Trust Spine, 0156 DXP6800 buildout |

---

## Historia vs GitHub setup docs

| | `docs/setup/` (yousirjuan) | Historia / vault |
|---|---|---|
| **Audience** | Public-safe operator + agent onboarding | Full operator memory + family wiki |
| **Updates** | Committed when stack shape changes | Continuous via pumps + watchers |
| **Secrets** | Never | Never in git — LiveSync creds stripped from golden profile |
| **Chat verbatim** | Summarized into chapters | Raw + sliced in vault / Qdrant |

**Best practice:** ship **stable architecture** in `docs/setup/`; let Historia hold **session-level** detail and verbatim operator intent.

---

## Related

- [06-retrieval-and-memory.md](./06-retrieval-and-memory.md) — Brain A/B pipeline  
- [10-m5-max-sovereign-edge.md](./10-m5-max-sovereign-edge.md) — `/Volumes/historia` mount  
- [13-physical-topology-protectli.md](./13-physical-topology-protectli.md) — NAS `.119` on LAN  
- Nephew: `plans/0119-historia-and-search-my-engine.md`, `docs/pockit/Obsidian-Autoflow-Quickstart.md`
