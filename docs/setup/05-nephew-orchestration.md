# Chapter 5 — Nephew Orchestration

**Public-safe:** architecture, vocabulary, and agent behavior. No live URLs or ports.

> **Deep dive:** [17-agents-fleet-bishop-cloak.md](./17-agents-fleet-bishop-cloak.md) · [15-doors-cassettes-pockit-navigation.md](./15-doors-cassettes-pockit-navigation.md)

---

## Chapter intents

| Intent | Why |
|---|---|
| **Nephew = full stack** | Hardware + runtime + Pockit + CLOAK — not one chat file |
| **Five layers** | Doctrine before library — every input classified and witnessed |
| **Pockit = family shell** | One navigational desktop for all cassettes |
| **Manifest-driven** | Hosts read JSON — never hardcode cassette IDs |
| **MCP session load first** | Agents ground in meta-library before acting |
| **Visual ≠ Jarvis** | Wiki vs voice — naming prevents operator confusion |

---

## What "Nephew" means

**Nephew** is the full Family Office AI system — not a single chat persona or one repo file:

- DGX Spark hardware and Docker fleet
- tower-api, Hermes LLM, RAG, voice
- CLOAK dispatch, MCP tools, witness chain
- Pockit family shell and cassette catalogue
- Skills, rules, meta-library, federation

Chain of command (Allodial law): **Allodial** → **allodialzero** (root operator) → **Nephew** → agents/cassettes below.

---

## Five operational layers

Every input flows through five jobs (see `marvelousempire/nephew` → `docs/how-nephew-functions.md`):

| Layer | Question | Reads |
|---|---|---|
| **1 Doctrine** | What shape of decision is this? | `orientation/`, AI_AGENT_RULES, SOPs |
| **2 Dispatch** | Who handles this? | CLOAK, workflows in ai-skills-library |
| **3 Pipeline** | What's the standard step sequence? | Matched workflow YAML |
| **4 Execution** | Run this step on the right product | Cascade: core-skills → library → repo overrides |
| **5 Inspection** | Was it good? What did we learn? | Inspector agents, witness, meta-library |

Plain words: *You speak → Nephew reads the handbook → routes cards → patrols → signs → files lessons.*

---

## CLOAK MCP tools (28)

Session agents call **`nephew_session_load` first** every session.

| Category | Tools (examples) |
|---|---|
| Session & memory | `nephew_session_load`, `nephew_memory_write`, `nephew_archive_search`, `nephew_corpus_retrieve`, `nephew_checkpoint_*` |
| Dispatch | `nephew_dispatch_evaluate`, `nephew_preflight_check`, `nephew_orchestrate_plan`, `nephew_route_model` |
| Witness | `nephew_witness_add`, `nephew_witness_verify` |
| Federation | `nephew_fed_update`, `nephew_fed_export`, `nephew_fed_import` |
| Hermes | `nephew_hermes_chat`, `nephew_hermes_status` |

Full table: `marvelousempire/nephew` → `CLAUDE.md`

---

## Pockit — family player console

| Term | Meaning |
|---|---|
| **Pockit** | Canonical product name (retired: Hub, Pad, Launchpad) |
| **Player** | Runtime that hosts cassettes (`nephew-tape`, `nephew-deck`, …) |
| **Cassette** | Plug-in surface (app, iframe, tape backend) |
| **Console** | Player product with its own door and children (`pockit`, `wordpress`, `bishop`, …) |
| **Door** | Hostname route — `http://<id>.localhost/` after doors bootstrap |
| **Tape** | Cassette being played inside a player |

Boot: `make pockit` from nephew repo on operator Mac.  
Study: `node bin/nephew study` or `docs/product-stack-glossary.md`.

Taxonomy: `marvelousempire/nephew` → `docs/pockit/Cassette-Surface-Taxonomy.md`

---

## Key manifests (nephew repo)

| File | Role |
|---|---|
| `data/cassette-catalogue.json` | Cassette registry |
| `data/cassette-registry.json` | Extended metadata |
| `data/tape-endpoints.json` | Door routing (`local_routes`) |
| `data/control-tower-apps.manifest.json` | CT iframe apps |
| `data/native-cards.manifest.json` | CT native React pages |
| `containers/nephew-ct/family-hub/family-hub-cards.json` | Pockit card pins |

Hosts iterate manifests — they do not hardcode cassette IDs in navigation.

---

## Associate Agents & personas

Nephew defines family-facing personas (Sterling, Blake, Cipher, Full) as Associate Agents — voice, tone, and skill bindings for members. Persona tables live in **nephew**, not yousirjuan.

You-Sir Juan platform agent **Yousir Juan** is the infrastructure Associate — Ansible, Docker, networking, troubleshooting (described in root `README.md`).

---

## Automata integration

Feature-shaped work follows the belief chain:

**Intent → Valid Intent → Concept → Notion → Solvency → Micro-slice → Action**

Ledger cards and plans encode hops. Automata repo holds the Pad product and philosophical schemas.

---

## Trust Protocol (locked)

Nephew's system prompt (`data/nephew-soul.md`) enforces:

1. Family-appropriate language  
2. Positive creation only  
3. Protection & prudence  
4. Full intelligence & anticipation  
5. Refinement & challenge  
6. Nurturing the vision  

Cannot be overridden by user prompt.

---

## Visual Obsidian (sovereign vault)

**Visual** = sovereign Obsidian wiki (graphs, Dataview HUD). **Jarvis** = voice-only — do not conflate.

Vault name: **Visual-Home** (retired: Jarvis-Home).  
Agent command: `make visual-obsidian` from nephew repo when vault work is requested.

---

## Agent rules loaded in Cursor

Consumer repos receive `.cursor/rules/` from ai-skills-library packs + repo overrides. Nephew root loads CLOAK full-ownership rules, canonical door URL copy, dev discipline, pipeline-stage truth, secret hygiene, and more.

Binder: `AI_AGENT_RULES/manifest.json` — read order for every session.

---

## Related

- [03-software-services.md](./03-software-services.md) — tower-api, Hermes, containers
- [06-retrieval-and-memory.md](./06-retrieval-and-memory.md) — `nephew_corpus_retrieve`
- [08-daily-operator-workflows.md](./08-daily-operator-workflows.md) — make targets and rituals
