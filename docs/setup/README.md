# Operator Setup — Complete System Reference (Public-Safe)

**Status:** living document · **Last updated:** 2026-06-15 (reconciled — ch. 00/19–21/24 + enterprise audit)  
**Audience:** operators, family members, and every agent (Nephew, Cursor, Claude Code, Grok, Perplexity, enterprise GitHub-only agents)  
**Privacy rule:** this tree avoids operator credentials, WG keys, and public WAN identifiers. **Internal LAN addressing** (192.168.10.x) appears in chapter 13 where needed for accurate cabling — same as [`home-network-full-architecture-report.md`](../home-network-full-architecture-report.md). Secrets stay in `ledger/` and private nephew infra runbooks.

This folder is the **single front door** for understanding how the Family Office hardware, You-Sir Juan platform, and Nephew orchestration fit together.

---

## Source of truth — Gitea master, GitHub mirror

| Remote | Role | Who uses it |
|---|---|---|
| **Gitea** `marvelousempire/yousirjuan` on DGX | **Master** | `make forge-push` · push-mirror → GitHub |
| **GitHub** `origin` | **Mirror + enterprise agent lane** | Agents without VPN |

**Sync discipline (automated):**

1. Enterprise agents push/merge to **GitHub `main`**.
2. **`forge-sync` timer** (every 5 min on DGX) fast-forwards **Gitea** when GitHub is ahead.
3. Operator runs **`make forge-push`** for immediate master + mirror.
4. **Push mirror** on Gitea syncs to GitHub on every Gitea commit.
5. **Gitea Actions** runs `.gitea/workflows/verify.yml` on push — not GitHub Actions.

Full detail: [23-forge-sync-automation.md](./23-forge-sync-automation.md)

---

## What this documents

| Chapter | File | Covers |
|---|---|---|
| 0 | [00-system-blueprint-audit-2026-06.md](./00-system-blueprint-audit-2026-06.md) | **Enterprise audit index** — Redis, zero-trust Caddy, ANE, diarization roadmap |
| 1 | [01-hardware.md](./01-hardware.md) | Every machine, its role, specs, and workload split |
| 2 | [02-network-security.md](./02-network-security.md) | Family Office Sandwich, mesh, VLANs, bind model, doors |
| 3 | [03-software-services.md](./03-software-services.md) | Containers, inference, RAG, voice, git forge, edge |
| 4 | [04-repo-ecosystem.md](./04-repo-ecosystem.md) | nephew, yousirjuan, ai-skills-library, clinic, siblings |
| 5 | [05-nephew-orchestration.md](./05-nephew-orchestration.md) | CLOAK, five layers, MCP, Pockit, cassettes, players |
| 6 | [06-retrieval-and-memory.md](./06-retrieval-and-memory.md) | Brain A/B, Qdrant, embeddings, sovereign vault |
| 7 | [07-git-and-deploy.md](./07-git-and-deploy.md) | Gitea forge, dual-push, SSH git, ship discipline |
| 8 | [08-daily-operator-workflows.md](./08-daily-operator-workflows.md) | Make targets, boot order, agent ritual, verification |
| 9 | [09-talking-to-your-machines.md](./09-talking-to-your-machines.md) | SSH, doors, tower-api, Cursor/MCP, Visual vs Jarvis, Apple hands-on |
| 10 | [10-m5-max-sovereign-edge.md](./10-m5-max-sovereign-edge.md) | M5 Nephew Max — edge daemon, hybrid routing, Obsidian, failover |
| 11 | [11-voice-parakeet-premium-stack.md](./11-voice-parakeet-premium-stack.md) | Kokoro demoted → Holler premium, Parakeet, F5 clone, routing tiers |
| 12 | [12-pockit-non-vanilla-surfaces.md](./12-pockit-non-vanilla-surfaces.md) | Suite bar, Comet motion, cassettes, Jarvis hub — non-vanilla UI synthesis |
| 13 | [13-physical-topology-protectli.md](./13-physical-topology-protectli.md) | **Live cabling**, `.10` LAN, 10GbE DGX↔NAS, VLAN plan, **Protectli migration** |
| 14 | [14-historia-and-operator-memory.md](./14-historia-and-operator-memory.md) | Historia, sovereign vault, Qdrant, Grok pump — **where chat history lives** |
| 15 | [15-doors-cassettes-pockit-navigation.md](./15-doors-cassettes-pockit-navigation.md) | **Doors**, cassette taxonomy, Pockit as family desktop / wildcard navigator |
| 16 | [16-knowledge-fabric-rag-quantization.md](./16-knowledge-fabric-rag-quantization.md) | **RAG**, bge-m3, Qdrant, quantization, KB cassettes, Brain A/B |
| 17 | [17-agents-fleet-bishop-cloak.md](./17-agents-fleet-bishop-cloak.md) | **Nephew**, Bishop, fleet passports, CLOAK MCP, chain of command |
| 18 | [18-wireguard-matrix-nas-gitea-why.md](./18-wireguard-matrix-nas-gitea-why.md) | **WireGuard**, Matrix/Element, NAS Docker, **Gitea vs GitLab — reasons** |
| 19 | [19-zero-trust-caddy-doors.md](./19-zero-trust-caddy-doors.md) | Zero-trust Caddy + mTLS doors (enterprise audit — planning) |
| 20 | [20-mobile-surfaces-ios17.md](./20-mobile-surfaces-ios17.md) | iPhone 17 / iPad Pro voice surfaces (enterprise audit — planning) |
| 21 | [21-redis-persistence.md](./21-redis-persistence.md) | Redis STM hybrid persistence (enterprise audit + `infrastructure/redis/`) |
| 24 | [24-apple-neural-engine-voice-optimization.md](./24-apple-neural-engine-voice-optimization.md) | ANE voice optimization stub — expand from audit |
| 22 | [22-doc-era-reconciliation.md](./22-doc-era-reconciliation.md) | **Stale branches / whitepapers** — what is live vs superseded |
| 23 | [23-forge-sync-automation.md](./23-forge-sync-automation.md) | **Gitea ↔ GitHub automation** — forge-push, timer, Actions, push-mirror |
| 25 | [25-cassette-update-agent-bridge.md](./25-cassette-update-agent-bridge.md) | **YSJ ↔ Nephew bridge** — Update the Cassette ritual, agent pastes, elevations map |
| 26 | [26-family-sso-and-door-tickets.md](./26-family-sso-and-door-tickets.md) | **Family SSO** — one hub sign-in, door tickets, recovery when SSO breaks |
| 27 | [27-cassette-factory-and-brain-proxy.md](./27-cassette-factory-and-brain-proxy.md) | **Cassette Factory** — one-tap GitHub ingest, `NEPHEW_BRAIN_PROXY`, brain merge |
| 28 | [28-voice-containers-whisper-fish-speech.md](./28-voice-containers-whisper-fish-speech.md) | **DGX voice containers** — Whisper, Fish Speech vs M5 Holler/Parakeet |
| 29 | [29-sovereign-egress-default-deny.md](./29-sovereign-egress-default-deny.md) | **Default deny egress** — no cloud LLM phoning home (Plan 0231) |

**Last updated:** 2026-06-16 (ch. 27–29 factory/voice/egress + Nephew 0231)

---

## One-paragraph summary

The operator runs a **sovereign Family Office stack** on owned hardware: a **DGX Spark** is Nephew's body (inference, RAG, containers, git forge compute), a **UGREEN NAS** holds durable git objects and backups, a **VPS** is the gated public edge and Clinic, and **Mac fleet** nodes orchestrate development and the Pockit player shell. Everything internal binds to **loopback + WireGuard only** — never the open LAN. **Pockit** is the family **navigational desktop** — type `http://pockit.localhost/` for the full pad or `http://<cassette-id>.localhost/` for any cassette full-page. **Nephew** orchestrates via CLOAK; **Bishop** builds agents behind it. Knowledge flows through **bge-m3 → Qdrant → reranker** with **quantized** LLMs on DGX and **Holler** voice on M5. **Gitea** is the daily forge (reasons in ch. 18); **Matrix/Element** is private family chat. **Protectli** replaces the consumer router as the security brain (ch. 13).

---

## How this relates to other docs

| Need | Where |
|---|---|
| **This setup (public, no secrets)** | `docs/setup/` ← you are here |
| Hardware deep-dive (product specs) | `hardware/`, `docs/hardware-topology.md` |
| **Full physical topology + Protectli** | [13-physical-topology-protectli.md](./13-physical-topology-protectli.md) |
| **Historia / chat memory** | [14-historia-and-operator-memory.md](./14-historia-and-operator-memory.md) |
| Strategic architecture (microscopic) | [`home-network-full-architecture-report.md`](../home-network-full-architecture-report.md) |
| Repo boundaries (YSJ vs Nephew) | `REPOS-CONTRACT.md` |
| Tool & upstream registry | `ecosystem/ai-skills-and-repos-registry.md` |
| Ledger runbooks (may contain live wiring) | `ledger/LEDGER-*` |
| Nephew product vocabulary | `marvelousempire/nephew` → `docs/product-stack-glossary.md` |
| **Agent paste (infrastructure)** | `docs/agent-pastes/infrastructure-operator-context.md` |
| **Agent paste (cassettes/voice)** | `marvelousempire/nephew` → `docs/agent-pastes/cassette-update-context.md` |
| Sovereign operating principle | `marvelousempire/nephew` → `docs/sovereign.md` |
| Live fleet ground truth (operator-only) | `marvelousempire/nephew` → `docs/infrastructure/dgx-rag-and-fleet-state.md` |
| Redis / Caddy compose stubs | `infrastructure/redis/`, `infrastructure/caddy/` |

**Do not duplicate secrets here.** When a runbook needs a port, IP, or key, it stays in `ledger/` or the private nephew infra mirror — not in this tree.

---

## Visual system map

```text
                    ┌─────────────────────────────────────┐
                    │   Public edge (TLS, auth gate)      │
                    │   VPS — Clinic, family apex         │
                    └──────────────────┬──────────────────┘
                                       │ WireGuard mesh
         ┌─────────────────────────────┼─────────────────────────────┐
         │                             │                             │
  ┌──────▼──────┐              ┌───────▼───────┐            ┌───────▼───────┐
  │ Mac fleet   │              │ DGX Spark     │            │ NAS           │
  │ orchestrate │◄─── WG ─────►│ Nephew body   │◄── 10GbE ─►│ git objects   │
  │ Pockit dev  │              │ LLM RAG voice │            │ backups media │
  │ Cursor/CLI  │              │ Docker stacks │            │ Historia vault│
  └─────────────┘              └───────────────┘            └───────────────┘
         │                             │
         └────────── home router ──────┘
                    VLAN segmentation
                    (Trusted / IoT / Guest)
```

---

## Agent read order

1. This README + chapters 1–5 (minimum before touching infra or cassettes).
2. **Chapters 15–18** before explaining doors, RAG, agents, or WG/Matrix/Gitea to anyone.
3. **Chapter 0 + 19–21** for enterprise audit items (Redis STM, zero-trust Caddy, mobile voice).
4. Chapters 9–12 before voice, M5 edge, or Pockit surface work.
5. **Chapter 13** before any network change or Protectli cutover.
6. **Chapter 14** when you need prior decisions, chat context, or vault truth.
7. `marvelousempire/nephew` → `docs/product-stack-glossary.md` (Pockit, cassette, door vocabulary).
8. `marvelousempire/nephew` → `AGENTS.md` (session hooks, SOP pointers).
9. **Chapter 25** + `docs/agent-pastes/` before cassette/voice cross-repo work.
10. `REPOS-CONTRACT.md` (what lives in which repo).
11. Private runbooks only when executing live changes.

---

## Known gaps (check Historia + nephew plans — not duplicated here yet)

| Topic | Where truth lives |
|---|---|
| Trust Spine outbound-only WG flip | Nephew `plans/0151-network-trust-spine-secure-cutover.md` |
| NAS Docker migration (WP, Gitea, Matrix off DGX) | Nephew `plans/0197-nas-docker-heavy-storage-migration.md` |
| DXP6800 full buildout (mail, chat, 10GbE program) | Nephew `plans/0156` (referenced; verify file on branch) |
| Brume-split AI island (whitepaper target) | Superseded — see [22-doc-era-reconciliation.md](./22-doc-era-reconciliation.md) |
| Redis short-term memory | **Documented** ch. 21 + `infrastructure/redis/` — **not yet deployed** on DGX fleet |
| Zero-trust Caddy mTLS doors | **Documented** ch. 19 — planning; differs from live `make doors` gateway today |
| Open WebUI health | Deployed but unhealthy on DGX — needs heal |
| LiveSync CouchDB edge | Wizard pending — registry notes in Jarvis hub audit |
| MLX / ANE distilled edge models on M5 | ch. 24 stub — Holler path shipped first |

---

## Maintenance

When hardware, services, or repo boundaries change:

1. Update the relevant chapter in `docs/setup/`.
2. Bump `docs/CHANGELOG.md` with an Eastern timestamp.
3. If the change is substantive, add a row to `plans/README.md` or a new `plans/NNNN-*.md`.
4. **Merge to Gitea `main` first**, then mirror to GitHub.
5. Keep secrets in `ledger/` — chapter 13 may include internal LAN IPs for cabling accuracy; never commit WG private keys or credentials.
