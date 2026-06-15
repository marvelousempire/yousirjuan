# Chapter 4 — Repository Ecosystem

**Public-safe:** repo roles, boundaries, and data flow. No clone paths with usernames or live hostnames.

---

## The three-repo core

| Repo | GitHub | Role | Tagline |
|---|---|---|---|
| **yousirjuan** | `marvelousempire/yousirjuan` | Private AI **infrastructure platform** | "Your AI lives on your hardware." |
| **nephew** | `marvelousempire/nephew` | **Orchestrator agent** + family experience | Multi-agent CLOAK, meta-library, witness, federation |
| **ai-skills-library** | `marvelousempire/ai-skills-library` | Shared **skills, rules, agents, workflows** | Engineering stacks, dashboard doctrine, You-Sir Juan pack |

Contract: [`REPOS-CONTRACT.md`](../../REPOS-CONTRACT.md)

---

## What lives where (hard boundaries)

### You-Sir Juan owns

- Hardware specs and topology docs (`hardware/`, `docs/setup/`, `docs/hardware-*`)
- Network architecture and ledger runbooks (`ledger/`, `vps/`)
- Deployment bootstrap (`tools/`, `bootstrap.sh`, docker-compose in this repo)
- Platform PRD, features ledger, pain journal
- Broker, ingestion, runtime scaffolding
- Vendor submodules (ai-skills-library, ruflo, claude-mem, marketingskills)

### Nephew owns

- CLOAK orchestration (`src/mcp/`, `bin/nephew`, dispatch pipeline)
- Meta-library (private submodule), witness chain, deck state
- Personas and Associate Agents (Sterling, Blake, Cipher, Full)
- Pockit shell, cassette framework, tower-api, Control Tower
- Family onboarding, product stack glossary, cassette SOPs
- DGX deploy composes (`deploy/dgx/`, `containers/`, `docker-compose.dgx.yml`)

### ai-skills-library owns

- Reusable skills under `skills/engineering/`, `skills/yousirjuan/`, etc.
- Rules packs propagated to consumer repos
- Agent definitions (dealer, nephew, cinematic-reality-ui-guardian, …)
- Tech stack ledgers and dashboard shell doctrine

**Rule:** edit the library first for shared skills; bump submodule in app repos — no forked copies.

---

## Sibling repos (fleet)

| Repo | Role |
|---|---|
| **clinic** | Universal diagnostic hospital — cases, fixes, rules register |
| **automata** | Belief system + Pad product — Automata philosophical flow |
| **dockyard** | Container management surface |
| **scene-skout** | Scene scouting / dustpan suit operations |
| **dustpan** | Cassette/tape framework (Python web cassettes) |
| **historia** | Long-form memory / archive |
| **red-e-play-app** | ReadyPlay product (separate business domain) |

Nephew routes to siblings via `src/sibling-bridge.js` — explicit capability providers, not hidden shell assumptions.

Passport registry: `marvelousempire/nephew` → `registries/passports/index.json`

---

## Data flow (family request)

```text
Family member
    ↓
Pockit / Control Tower / iOS / iMessage
    ↓
tower-api (auth, retrieve, chat)
    ↓
┌───────────────┬────────────────┬─────────────────┐
│ Hermes/Ollama │ Qdrant RAG     │ Voice containers│
│ (DGX)         │ (DGX)          │ (DGX)           │
└───────────────┴────────────────┴─────────────────┘
    ↓
Associate Agent persona response
    ↓
Witness + meta-library lesson (Nephew)
```

Infrastructure underneath: You-Sir Juan hardware + mesh + containers.

---

## Git remotes pattern

| Remote | Purpose |
|---|---|
| `origin` | GitHub (SSH) — protected `main`, PR gate |
| `gitea` / forge alias | Self-hosted forge on DGX — direct push, no PR |
| GitLab | Optional CI mirror on self-hosted runner |

Push forge first when configured; mirror to GitHub without force-push. See parallel git tracking rule in nephew repo.

---

## Submodule & vendor workflow

```bash
git clone https://github.com/marvelousempire/yousirjuan
cd yousirjuan
git submodule update --init --recursive
```

Vendor bumps: edit inside `vendor/<name>`, push fork branch, commit pointer in yousirjuan.

---

## Agent discovery mirrors

| Mirror | Purpose |
|---|---|
| `marvelousempire/pockithub` | Static Pockit shell export for study — **not** runtime |
| `docs/agent-pastes/*` in nephew | Paste blocks for Grok/Perplexity/Cursor attach |

Runtime always requires the **nephew** monorepo checkout on an operator or DGX machine.

---

## Handbook framework

Cross-repo handbooks indexed in `handbook-framework/` and `data/framework-handbook.manifest.json` in nephew. You-Sir Juan handbook entry: `handbook/chapter-01-start/`.

---

## Related

- [05-nephew-orchestration.md](./05-nephew-orchestration.md) — how Nephew uses this ecosystem
- [07-git-and-deploy.md](./07-git-and-deploy.md) — push and ship discipline
- [`ecosystem/upstream-repositories-master-ledger.md`](../../ecosystem/upstream-repositories-master-ledger.md)
