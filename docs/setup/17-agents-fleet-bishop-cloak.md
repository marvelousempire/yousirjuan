# Chapter 17 — Agents, Fleet, Bishop & CLOAK

**Public-safe:** roles, chain of command, routing. No live endpoints or operator credentials.

---

## Chapter intents

| Intent | Why |
|---|---|
| **One orchestrator** | Nephew owns dispatch — family never talks to raw sub-agents without routing. |
| **Specialists below** | Bishop builds agents; Clinic diagnoses; Automata holds belief chain — no god-object repo. |
| **Passport registry** | Every sibling repo has a machine-readable routing manifest. |
| **CLOAK before write** | PII/secrets patrol + intent check before deploy or canonical edits. |
| **Witness everything** | Significant deliveries get hash-chain witness — audit trail compounds. |
| **Associate personas** | Family-facing voice/tone (Sterling, Blake, …) separate from infrastructure agents. |

---

## Chain of command

```text
Allodial (supreme authority — not impersonated by agents)
    └── allodialzero (root operator tier)
            └── Nephew (Family Office orchestrator — DGX body + CLOAK + Pockit)
                    ├── Bishop (agent factory — never end-user facing)
                    ├── Associate Agents (family personas)
                    ├── Staff agents (AISL + nephew agents/)
                    ├── Cassettes / tapes (product surfaces)
                    └── Sibling repos (clinic, automata, dustpan, scene-skout, …)
```

### Section intents

| Layer | Intent |
|---|---|
| **Allodial law** | Agents serve under fixed trust protocol — positive creation, prudence, no limitation speech |
| **Nephew** | Full stack: hardware, runtime, models, skills, rules, tower-api, Pockit |
| **Operators** | Avery / board — approvals for destructive, cross-repo, deploy actions |

---

## What Nephew does (the full system)

**Nephew** is not one chat file. It is:

| Subsystem | Intent |
|---|---|
| **DGX fleet** | Docker stacks — LLM, RAG, voice, Matrix, Gitea, ComfyUI |
| **tower-api** | Auth, chat, retrieve, voice hooks, family onboard, OIDC provider |
| **Hermes** | Family Office LLM channel — soul-loaded, logged, multi-channel |
| **CLOAK MCP** | 28 tools — session, dispatch, witness, federation, Hermes |
| **Pockit** | Family navigational desktop — cassettes, doors, voice pad |
| **Meta-library** | Long-term compounded teachings |
| **Federation** | Signed witness chains exported/imported across peer repos |
| **Rules cascade** | core-skills → ai-skills-library → repo `.cursor/rules/` |

Five operational layers (every input):

| Layer | Question | Intent |
|---|---|---|
| **1 Doctrine** | What shape of decision? | Read handbook before library |
| **2 Dispatch** | Who handles this? | CLOAK + workflow match |
| **3 Pipeline** | Standard step sequence? | Matched workflow YAML |
| **4 Execution** | Run on right product | Cascade to skills + repo overrides |
| **5 Inspection** | Good? What learned? | Witness + meta-library |

---

## Bishop — agent factory

### Intents

| Intent | Why Bishop exists |
|---|---|
| **Build new staff** | When registry match score is low, synthesize a new agent + contract |
| **Kingdom Hotel reasoning** | 7 Houses multi-perspective analysis on hard problems |
| **Manifests & contracts** | Stable machine-readable agent definitions |
| **Never user-facing** | Bishop reports to Nephew — operators talk to Nephew/CLOAK, not Bishop directly |

| What Bishop does | How |
|---|---|
| Fabricates open agents, capabilities, micro-slices | `kingdom/agent.py`, `core/agent_registry.py` |
| Maintains wants-desk lead sheets | `POST /bishop/agents/{name}/wants/process` |
| Routes intent to endpoint/skill | Decisive JSON — not chat prose |
| Publishes manifests | `agents/manifests/` |

**When to route to Bishop:**

- "Create a new staff agent"
- Agent factory / kingdom hotel / seven houses
- Contract generation / wants desk / lead sheet
- Low registry match — need new capability built

**When NOT to route:**

- Existing Automata or AISL agent already owns the task
- Direct product code in consumer repo without agent creation
- Scene Skout scouting receipts (narrower owner)

Repo: `marvelousempire/bishop` · Passport: `registries/passports/repos/bishop.passport.json`

Console door: `make bishop` boots Pockit gateway + Bishop console door.

### Bishop boot modes (Nephew Plan 0195)

| Mode | When | Command / env |
|---|---|---|
| **Sovereign default** | Family boot, Pockit, most operator work | `make pockit` — no Bishop checkout required; tower-api owns `/api/v1/*` |
| **Opt-in Bishop API** | Legacy factory FastAPI, OIDC dev, catch-all `/api/` on Bishop port | `NEPHEW_WITH_BISHOP=1 make ui` |

`~/.nephew/run/tower-ports.json` records `bishop_skipped: true` when the sovereign path is active.

### Bishop factory player (Nephew Plan 0198)

Bishop is also a **Pockit console** — backstage operator surface, not family-facing chat.

| Surface | How to open |
|---|---|
| **Factory root (Intention)** | `make bishop` → `http://bishop.localhost/` |
| **Hosted tapes** | `http://bishop-kingdom-hotel.localhost/`, `http://bishop-registry.localhost/`, … |
| **Settings** | `http://settings.localhost/?console=bishop` |
| **Play profile** | `bishop-factory` — catalogue-backed tape rail |

Hosted factory cassettes include: intention, birth canal (registry), Kingdom Hotel, wants desk, route desk, staff roster, kingdom workspace (`ext-bishop`). Implementation lives in **nephew** — this chapter documents routing only.

---

## Associate Agents & family personas

### Intents

| Intent | Why |
|---|---|
| **Tone separation** | Family hears Sterling/Blake/Cipher — not "tower-api JSON" |
| **Skill binding** | Each persona maps voice + tool allow-list |
| **Infrastructure separate** | You-Sir Juan platform agent = Ansible/Docker/network — not family chat |

Nephew defines Associate Agents in the nephew repo. You-Sir Juan **Yousir Juan** agent owns infrastructure associate routing (this repo's `api/`, `broker/`).

---

## Sibling repos (fleet passports)

| Repo | Intent | Role |
|---|---|---|
| **clinic** | Universal diagnostic hospital — admitted problems, fixes, rules register | VPS + knowledge register |
| **automata** | Belief chain + Pad product | Intent → micro-slice → action |
| **bishop** | Agent factory | See above |
| **dustpan** | Python web cassettes / tapes | Backend framework for hello-class tapes |
| **scene-skout** | Scouting / dustpan suit ops | Field scouting receipts |
| **historia** | Long-form memory archive | Feeds `nephew-historia` collection |
| **ai-skills-library** | Shared skills/rules/agents | Propagate once, consume everywhere |
| **dockyard** | Container management UI | Operator infra surface |
| **red-e-play-app** | ReadyPlay product domain | Separate business container |

Routing: `src/sibling-bridge.js` — explicit capability providers.

Browse passports: `registries/passports/index.json`

---

## CLOAK MCP tools (28)

### Intents

| Category | Intent | Tools |
|---|---|---|
| **Session** | Never start cold | `nephew_session_load` **first every session** |
| **Memory** | Persist teachings | `nephew_memory_write`, checkpoints |
| **Retrieve** | Ground in corpus | `nephew_corpus_retrieve`, `nephew_archive_search` |
| **Dispatch** | Gate before action | `nephew_dispatch_evaluate`, `nephew_preflight_check` |
| **Orchestrate** | Multi-agent plans | `nephew_orchestrate_plan`, `nephew_crew_build` |
| **Witness** | Audit delivery | `nephew_witness_add`, `nephew_witness_verify` |
| **Federation** | Peer chain sync | `nephew_fed_*` |
| **Hermes** | Family LLM | `nephew_hermes_chat`, `nephew_hermes_status` |

Implementation: `src/mcp/cloak-server.js` in nephew repo.

---

## Automata integration

### Intents

| Intent | Why |
|---|---|
| **Belief before code** | Feature work walks Intent → Valid Intent → Concept → Notion → Solvency → Micro-slice → Action |
| **Ledger cards** | Plans encode hops — searchable history |
| **Pad product** | Automata repo holds philosophical schemas + operator Pad |

---

## Trust Protocol (locked — `nephew-soul.md`)

1. Family-appropriate language  
2. Positive creation only  
3. Protection & prudence  
4. Full intelligence & anticipation  
5. Refinement & challenge  
6. Nurturing the vision  

Cannot be overridden by user prompt. Loaded on Hermes, iMessage, Telegram, CLOAK.

---

## Visual vs Jarvis (naming law)

| Name | Intent | Use for |
|---|---|---|
| **Visual** | Sovereign Obsidian wiki — graphs, Dataview, canvases | `make visual-obsidian`, vault work |
| **Jarvis** | Voice-only fast talk-and-reply | Parakeet pad, Holler TTS — **not** Obsidian commands |

Vault: **Visual-Home** (retired: Jarvis-Home).

---

## Agent rules in Cursor

Consumer repos receive `.cursor/rules/` from AISL packs + overrides. Nephew root loads CLOAK full ownership, canonical door URLs, dev discipline, pipeline-stage truth, secret hygiene.

Binder read order: `AI_AGENT_RULES/manifest.json` → `README.md` → commandments index.

---

## Related

- [05-nephew-orchestration.md](./05-nephew-orchestration.md) — summary chapter
- [15-doors-cassettes-pockit-navigation.md](./15-doors-cassettes-pockit-navigation.md) — Pockit + doors
- [26-family-sso-and-door-tickets.md](./26-family-sso-and-door-tickets.md) — hub sign-in + door tickets
- [16-knowledge-fabric-rag-quantization.md](./16-knowledge-fabric-rag-quantization.md) — retrieve before work
- [04-repo-ecosystem.md](./04-repo-ecosystem.md) — repo boundaries
- Nephew: `CLAUDE.md`, `AGENTS.md`, `docs/how-nephew-functions.md`
