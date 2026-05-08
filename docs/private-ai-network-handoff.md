# Private AI Network — Full Conversation Handoff Sheet

**Date:** May 8, 2026  
**Purpose:** Complete handoff document capturing every decision, tool, hardware spec, architecture choice, and open question from the full design conversation. Give this to anyone who needs to pick up where this left off — a developer, an integrator, a future maintainer.

---

## 1. What We're Building

A self-hosted, private AI infrastructure serving three distinct operational domains:

1. **Private Family Office (PFO/FO)** — wealth management, investment research, document intelligence, estate and governance. Highest sensitivity. Data must never leave the local network. Requires attorney + CPA for legal structure; AI infrastructure cannot replace legal or tax counsel.
2. **Private Membership Association (PMA)** — member acquisition, communications, education, retention, and operations. Same network, separate trust domain from FO.
3. **Portfolio Operating Businesses** — all companies the PFO controls. Each gets AI-powered marketing, content, and operations. Portfolio businesses can share a learning layer with each other, but never with the FO.

### Three design principles

- **Local-first inference.** FO workloads run entirely on local hardware. No FO data hits cloud APIs.
- **Trust-domain separation.** FO is walled off from portfolio at the network, storage, and memory layer.
- **Compounding intelligence.** Portfolio businesses share wins, failures, vendor lists, and patterns. The more businesses run on this infrastructure, the smarter the shared layer gets.

---

## 2. The Full Software Stack

### 2.1 Core agent layer

| Tool | What it does | Where it lives |
|---|---|---|
| **Claude Code** | Daily interaction surface: terminal-based AI coding agent | Mac |
| **Ruflo** | Multi-agent orchestration under Claude Code through MCP. Handles swarms, persistent memory, hooks, tools, self-learning, routing, and optional federation. | Mac; optionally VPS for always-on workers |
| **marketingskills** | Markdown skill pack for CRO, copywriting, SEO, email, paid ads, referral, pricing, retention, launch, sales enablement, analytics, and more. | Installed per portfolio business directory |
| **OpenClaw** | Personal assistant front-end bridging messaging apps to local LLMs. Can delegate coding work to Claude Code. | Optional VPS or Mac mini on VLAN 11 |

### 2.2 Ruflo + Claude Code relationship

Ruflo does not replace Claude Code. It runs underneath it. The user still works through Claude Code's terminal. Ruflo plugs in through MCP and handles routing, spawning sub-agents, storing memory, and pulling RAG context in the background.

### 2.3 Ruflo plugins relevant to this build

| Plugin | Role |
|---|---|
| `ruflo-agentdb` | Vector database with HNSW index |
| `ruflo-rag-memory` | RAG layer: hybrid search, graph hops, diversity ranking |
| `ruflo-ruvector` | GPU-accelerated vector search, Graph RAG, and tool layer pointed at the Thors |
| `ruflo-knowledge-graph` | Entity-relationship extraction over the vector store |
| `ruflo-rvf` | Save and restore agent memory snapshots across sessions or machines |
| `ruflo-observability` | Audit log of every agent action; required for FO |
| `ruflo-cost-tracker` | Token budgets and alerts per entity |

### 2.4 Local inference on the Thors

| Software | Role |
|---|---|
| **Ollama** | Simple inference server for personal and utility use, especially Thor #2 |
| **vLLM** | Production-grade serving for concurrent requests, especially Thor #1 |

Both should expose OpenAI-compatible API endpoints that Ruflo's multi-provider router can use.

**Models to pull initially:**

- Thor #1: `Llama 3.3 70B`, `Qwen 2.5 72B` in FP8 or FP16, if hardware supports it.
- Thor #2: `nomic-embed-text` or `bge-large`, `Qwen 2.5 7B`, and a vision model such as `Qwen-VL`.

### 2.5 Mac-side inference fallback

- **MLX runtime** gives Apple-silicon-optimized inference when Thors are unreachable.
- The Mac is not the primary inference node. The Thors carry that role.
- The Mac is the creative workstation and development environment.

### 2.6 Cloud API usage

- Anthropic Claude API and optionally OpenAI may be used only from the portfolio trust domain.
- FO data must never go to cloud APIs.
- Every project `CLAUDE.md` must state which workloads may use cloud APIs and which may not.

---

## 3. Hardware

### 3.1 Compute

| Device | Role | Key specs | Approx cost |
|---|---|---|---|
| **NVIDIA Jetson AGX Thor #1** | Primary large-model inference | 128GB unified memory, Blackwell GPU class | ~$3,500 |
| **NVIDIA Jetson AGX Thor #2** | Embeddings, small models, vision | Same class of hardware | ~$3,500 |
| **Mac Studio M5 Ultra** or **MacBook Pro M5 Max 16-inch** | Creative workstation and development surface | Studio: high stationary headroom. MBP: mobile build surface. | ~$5,500–$8,000 |

### Mac decision

- Two Thors handle AI duties, so the Mac does not need to be the primary inference monster.
- MacBook Pro M5 Max, 16-inch, 128GB RAM, 4TB storage is the mobile-forward choice.
- Mac Studio M5 Ultra is the stationary powerhouse path if maximum local GPU headroom matters.
- There is no MacBook with an Ultra chip; Ultra-class chips are reserved for desktop-class Macs.

### Why two Thors, not one

- Memory does not pool across boxes. Two 128GB nodes do not become one 256GB node.
- The benefit is specialization: Thor #1 for heavy reasoning, Thor #2 for embeddings, fast classification, and vision.
- Ruflo swarms can parallelize work instead of queueing all work on one node.
- If one node goes down, the other can keep serving.

### 3.2 Storage

| Device | Role | Approx cost |
|---|---|---|
| 2TB NVMe SSD, Thor #1 | LLM model files and active vector DB | ~$200 |
| 2TB NVMe SSD, Thor #2 | Embedding models and small models | ~$200 |
| Synology DS923+ or UGREEN DXP4800 | Source document repository | ~$500–$700 |
| 2x 8TB NAS HDDs, mirrored | Bulk storage | ~$400 |
| 8TB external backup drive | Offline rotation | ~$150 |

### NAS structure

- `/family-office/` share: VLAN 10 access only, separate SMB credentials, separate encryption key.
- `/portfolio/` share: VLAN 11 access only, separate SMB credentials, separate encryption key.

### RAG storage math

- One indexed chunk is about 6KB total, including vector, source text, and metadata.
- 1 million chunks is about 6GB, roughly 50,000 pages of text.
- 10 million chunks is about 60GB.
- 2TB NVMe per Thor is more than enough for active indices and model files.

### 3.3 Networking

| Device | Role | Approx cost |
|---|---|---|
| **GL.iNet Flint 2 AX6000** | Primary gateway: VLANs, WireGuard server, AdGuard Home, routing | ~$300 |
| **GL.iNet Flint / Slate AX AX1800** | Travel router with auto-tunnel | ~$120 |
| 8-port managed switch | VLAN-capable switching | ~$50 |
| Cat6 cabling | Physical network | ~$100 |

### 3.4 Total hardware cost range

| Path | Total |
|---|---|
| Now-build with MBP M5 Max | ~$14,500 |
| Wait-build with M5 Ultra Mac Studio | ~$16,000–$18,000 |

---

## 4. Network Architecture

### 4.1 VLAN plan

| VLAN | Name | Members | Internet egress |
|---|---|---|---|
| 10 | FO-Trusted | FO workstations, FO NAS share | Restricted DNS allowlist |
| 11 | Portfolio-Trusted | PMA + portfolio workstations, portfolio NAS share | Standard |
| 20 | AI-Compute | Thor #1, Thor #2 | None; LAN-only inbound from VLAN 10 and 11 |
| 30 | IoT | Smart devices | Restricted |
| 40 | Guest | Visitors | Internet only |

**Load-bearing security decision:** AI-Compute VLAN has no internet egress. The Thors physically cannot exfiltrate data. Model downloads happen during controlled maintenance windows with temporary egress exceptions.

### 4.2 WireGuard remote access

- WireGuard server runs on AX6000.
- AX1800 travel router establishes auto-tunnel from hotel, airport, or remote Wi-Fi.
- Laptop on the road operates like it is at home, using the same Thor endpoints, NAS, and RAG stores.

### 4.3 DNS

- AdGuard Home runs on AX6000.
- Custom rules: `*.thor.local` to internal IPs; `*.fo.local` to internal IPs.
- Optional: AI-Compute VLAN cannot resolve public DNS.

---

## 5. Memory and RAG Architecture

### 5.1 RAG vs fine-tuning

RAG does not train models. It indexes documents into a vector database. At query time, it retrieves relevant chunks and feeds them to the LLM as context. "Training a RAG for X" really means indexing documents into a namespace. Switching between domains is switching which namespace is queried.

Fine-tuning changes model weights. It is slower, more expensive, and overkill for most uses in this architecture.

### 5.2 Ingest flow

```text
Documents -> Chunker (~500-word chunks) -> Embedding model -> HNSW vector index
                                                               |
Question -> Embedding model -> Nearest-neighbor search -> Top chunks
                                                               |
                                      LLM answers using chunks as context
```

### 5.3 Namespace plan — Family Office, VLAN 10 only

```text
fo:investments:active
fo:investments:diligence
fo:legal:trusts
fo:legal:entities
fo:tax:current-year
fo:tax:archive
fo:family:governance
fo:advisors
fo:insurance
fo:property
```

### 5.4 Namespace plan — PMA

```text
pma:members:active
pma:members:applications
pma:content:published
pma:content:drafts
pma:legal:agreements
pma:operations:playbooks
pma:marketing:assets
```

### 5.5 Namespace plan — Portfolio shared layer

```text
shared:brand:family-holdco
shared:investment-thesis
shared:playbooks:wins
shared:playbooks:failures
shared:vendors:approved
```

### 5.6 Namespace plan — Per portfolio business

```text
{biz}:customers
{biz}:competitors
{biz}:campaigns
{biz}:product:current
{biz}:product:roadmap
```

### 5.7 Critical rule: never cross trust domains

Nothing from `fo:*` namespaces ever flows into `shared:*` or `{biz}:*`. Enforce this at three layers:

1. OS and NAS share permissions.
2. Network VLAN routing.
3. Ruflo, with separate `.claude-flow/` instances per trust domain.

---

## 6. Trust Domains

| Domain | Devices | NAS share | RAG instance | Should touch |
|---|---|---|---|---|
| **FO** | Dedicated FO workstation on VLAN 10, Thor #1 read-only | `/family-office/` | `fo:*` only | FO work only; never PMA or portfolio |
| **Portfolio** | PMA + portfolio workstations on VLAN 11, both Thors | `/portfolio/` | `pma:*`, `shared:*`, `{biz}:*` | PMA + portfolio businesses |

**Ideal:** dedicated FO workstation that only connects to VLAN 10.

**Minimum:** same Mac, separate user accounts, separate VPN profiles, documented risk acceptance, and strict workflow controls.

---

## 7. Project Directory Layout

### 7.1 Portfolio side

```text
~/portfolio/
├── _shared/
│   ├── brand-system/
│   ├── investment-thesis/
│   └── playbooks/
│
├── pma/
│   ├── .agents/skills/
│   ├── .claude-flow/
│   ├── product-marketing-context.md
│   └── CLAUDE.md
│
├── ecom-co/
│   ├── .agents/skills/
│   ├── .claude-flow/
│   ├── product-marketing-context.md
│   └── CLAUDE.md
│
├── saas-co/
│   └── ...
│
└── services-co/
    └── ...
```

### 7.2 FO side

```text
~/family-office/
├── .agents/skills/
├── .claude-flow/
├── CLAUDE.md
└── projects/
    ├── investments/
    ├── tax/
    ├── legal/
    └── reporting/
```

---

## 8. marketingskills Repo

**Repo:** https://github.com/coreyhaines31/marketingskills  
**Use:** Portfolio business marketing skills for agent workflows.

### 8.1 Install

```bash
cd ~/portfolio/{business}
npx skills add coreyhaines31/marketingskills

# Selective install
npx skills add coreyhaines31/marketingskills --skill page-cro copywriting email-sequence

# Claude Code plugin path
/plugin marketplace add coreyhaines31/marketingskills
/plugin install marketing-skills
```

### 8.2 How it works

Each skill should read `product-marketing-context.md` first. That file describes the business, audience, voice, and offer. The same skill can produce completely different output for each business because each business has different context.

### 8.3 Skill-to-need map

| Need | Skill(s) |
|---|---|
| Landing page / membership page | `page-cro`, `copywriting`, `marketing-psychology` |
| Membership/pricing tiers | `pricing-strategy`, `paywall-upgrade-cro` |
| Application / signup flow | `signup-flow-cro`, `onboarding-cro` |
| Welcome email series | `email-sequence` |
| Newsletter / educational content | `content-strategy`, `copy-editing` |
| Referral program | `referral-program` |
| Community building | `community-marketing` |
| Retention + save flows | `churn-prevention` |
| SEO audit | `seo-audit`, `schema-markup`, `site-architecture` |
| AI search optimization | `ai-seo` |
| Programmatic SEO | `programmatic-seo` |
| Paid ads | `paid-ads`, `ad-creative` |
| A/B testing | `ab-test-setup`, `analytics-tracking` |
| Cold outreach | `cold-email` |
| Sales docs | `sales-enablement` |
| Customer research | `customer-research` |
| Competitor analysis | `competitor-profiling`, `competitor-alternatives` |
| Launch strategy | `launch-strategy` |
| AI images | `image` |
| AI video | `video` |
| App store optimization | `aso-audit` |
| RevOps | `revops` |
| Lead magnets | `free-tool-strategy`, `lead-magnets` |
| Brainstorming | `marketing-ideas` |
| Marketing psychology | `marketing-psychology` |

---

## 9. OpenClaw Optional Layer

OpenClaw is a local gateway that bridges messaging apps to a local LLM. It is best treated as a personal assistant layer, not the core engineering layer.

### How it complements the stack

- OpenClaw: chat-facing front end for personal and admin tasks.
- Claude Code + Ruflo: engineering and marketing workhorse at the desk.
- OpenClaw can delegate coding tasks to Claude Code through a `coding-agent` skill.

### Where it runs

- VPS or always-on Mac mini on VLAN 11.
- Not the creative workstation, because it should be always on.

### Model endpoint

Use Thor #2 for local-only inference:

```text
http://thor2.local:11434
```

For portfolio-only work, Anthropic/OpenAI APIs may be configured as backup providers if the project `CLAUDE.md` allows them.

---

## 10. Creative Workflow

Cloud video tools such as Higgsfield run inference on vendor servers and should not receive FO data. Local hardware still matters around the cloud workflow:

- Final Cut Pro and DaVinci Resolve on Mac for editing.
- After Effects and Motion on Mac for compositing.
- Topaz Video AI on Mac for upscaling.
- Stable Video Diffusion or Wan on Thor #1 or MLX for local video generation.
- Blender, Cinema 4D, ARKit, Reality Composer Pro, Vision Pro tooling, and Xcode on Mac.

The Mac is the creative tool. The Thors are the LLM inference tools. They complement each other.

---

## 11. Implementation Roadmap

### Phase 1 — Network foundation

- [ ] Procure AX6000, AX1800, and managed switch.
- [ ] Install AX6000 as primary gateway.
- [ ] Configure VLANs 10, 11, 20, 30, and 40.
- [ ] Configure AdGuard Home for DNS filtering.
- [ ] Set up WireGuard server on AX6000.
- [ ] Pair AX1800 as travel router with auto-tunnel.

### Phase 2 — First Jetson Thor

- [ ] Procure Jetson AGX Thor Developer Kit.
- [ ] Mount on AI-Compute VLAN 20 with no internet egress.
- [ ] Install 2TB NVMe SSD.
- [ ] Install Ubuntu + JetPack.
- [ ] Install vLLM and Ollama.
- [ ] Pull `llama3.3:70b`, `qwen2.5:72b`, and `nomic-embed-text` if supported.
- [ ] Verify OpenAI-compatible endpoints from VLAN 10 and 11.

### Phase 3 — NAS + first RAG namespace

- [ ] Procure NAS and mirrored drives.
- [ ] Create `/family-office/` and `/portfolio/` shares.
- [ ] Use separate credentials and encryption keys.
- [ ] Configure nightly snapshots and offline backup rotation.
- [ ] Pick first FO RAG namespace.
- [ ] Ingest first document batch and validate retrieval quality.
- [ ] Document ingest workflow as a repeatable runbook.

### Phase 4 — Mac + Claude Code + Ruflo + first business

- [ ] Procure Mac.
- [ ] Install Claude Code.
- [ ] Configure Ruflo with `npx ruflo@latest init wizard`.
- [ ] Register Ruflo as MCP server:

```bash
claude mcp add ruflo -- npx ruflo@latest mcp start
```

- [ ] Configure Ruflo router to point at Thor #1 endpoints.
- [ ] Install Ruflo plugins: `ruflo-ruvector`, `ruflo-rag-memory`, `ruflo-observability`, `ruflo-cost-tracker`.
- [ ] Set up first portfolio business directory.
- [ ] Install marketingskills.
- [ ] Write `product-marketing-context.md`.
- [ ] Run first end-to-end marketing output test.

### Phase 5 — Second Thor + specialization

- [ ] Procure second Jetson AGX Thor Developer Kit.
- [ ] Install 2TB NVMe.
- [ ] Place on AI-Compute VLAN.
- [ ] Install Ollama.
- [ ] Pull `nomic-embed-text`, `qwen2.5:7b`, and a vision model.
- [ ] Migrate embedding workload from Thor #1 to Thor #2.
- [ ] Dedicate Thor #1 to heavy reasoning.

### Phase 6 — Multi-business portfolio rollout

- [ ] Use `tools/init-portfolio-business.sh` to create each new portfolio business.
- [ ] Onboard PMA first, then each portfolio business one at a time.
- [ ] Write `product-marketing-context.md` before any AI marketing work.
- [ ] Populate `shared:playbooks:wins` from validated outcomes.
- [ ] Confirm audit logging through `ruflo-observability`.
- [ ] Set token budgets in `ruflo-cost-tracker`.

### Phase 7 — OpenClaw

- [ ] Decide whether chat-based assistant access is needed.
- [ ] Procure always-on host if needed.
- [ ] Install OpenClaw on VLAN 11.
- [ ] Connect first messaging app, with Telegram as a recommended starting point.
- [ ] Point OpenClaw at Thor #2 Ollama endpoint.
- [ ] Add cloud API backup only for portfolio work if allowed.

### Phase 8 — Federation

- [ ] Evaluate whether separate physical locations need to exchange agent work.
- [ ] If yes, configure Ruflo federation with mTLS, PII gating, trust scoring, and audit trail.
- [ ] Skip this for single-location builds unless the need becomes real.

---

## 12. Per-Business Setup Template

A reusable script has been added at:

```text
tools/init-portfolio-business.sh
```

Use it like this:

```bash
bash tools/init-portfolio-business.sh ecom-co
```

It creates:

- `~/portfolio/<business>/.agents/skills/`
- `~/portfolio/<business>/.claude-flow/`
- `~/portfolio/<business>/product-marketing-context.md`
- `~/portfolio/<business>/CLAUDE.md`

---

## 13. Recurring Cost Summary

| Item | Monthly |
|---|---|
| Claude Code Pro/Team | $20–$100/seat |
| Anthropic API, portfolio only | ~$50–$500 depending on volume |
| Ruflo, marketingskills, Ollama, vLLM, OpenClaw | $0 software cost; open source |
| Backblaze B2 off-site backup | ~$6/TB |
| Domain + email hosting | ~$50–$200 total |

---

## 14. Backup and Recovery

### What to back up first

1. NAS source documents. These are not reproducible.
2. `.claude-flow/` directories. Useful for resumption.
3. `product-marketing-context.md` per business.
4. `CLAUDE.md` per business.
5. Vector indices are reproducible from sources and lower backup priority.

### Backup schedule

| Layer | Frequency | Destination |
|---|---|---|
| NAS to external drive | Weekly | Offline external drive, rotated offsite |
| NAS to Backblaze B2 | Daily | Separate buckets per trust domain, separate encryption keys |
| `.claude-flow/` snapshot | Daily | NAS + B2 through `ruflo-rvf` |
| Thor NVMe model files | On change only | External drive |

### Recovery scenarios

| Failure | Impact | Recovery |
|---|---|---|
| Thor #1 down | Heavy reasoning offline | Fall back to Mac MLX or portfolio-only cloud API |
| Thor #2 down | Embeddings and small models offline | Temporarily shift to Thor #1 or Mac MLX |
| NAS drive failure | Single drive loss | Replace drive and rebuild mirror |
| Vector DB corruption | Namespace loses memory | Re-ingest from NAS source documents |
| Mac lost/stolen | Workstation gone | Restore from Time Machine; keep critical data off Mac-only storage |
| Network device compromised | Network trust issue | Rotate WireGuard keys; AI VLAN has no egress; keep FO data local |

---

## 15. Open Decisions

| # | Decision | Options | Recommendation |
|---|---|---|---|
| 1 | Mac timing | Buy mobile Mac now vs wait for Studio | Buy mobile if portability matters; wait for Studio if stationary power matters |
| 2 | One Thor or two | Start with one vs buy both | Buy both if budget allows; parallelism and specialization matter |
| 3 | OpenClaw timing | Add now vs later | Add in Phase 7 after core infrastructure works |
| 4 | FO machine separation | Dedicated FO workstation vs same Mac with separate users | Dedicated FO workstation strongly recommended |
| 5 | Cloud API policy | Written per project in `CLAUDE.md` | Required before portfolio work |
| 6 | Federation | Set up now vs skip | Skip unless separate physical locations need it |

---

## 16. What This Is Not

- **Not legal advice.** PFO and PMA formation, membership agreements, compliance, and tax treatment require qualified attorneys and CPAs.
- **Not a single-vendor commitment.** Each component is replaceable. The architecture should outlive any one product.
- **Not finished.** This is a living document. Update it as the build progresses, decisions get made, and businesses are added.

---

## 17. Key URLs and References

| Resource | URL |
|---|---|
| Ruflo | https://github.com/ruvnet/ruflo |
| marketingskills | https://github.com/coreyhaines31/marketingskills |
| OpenClaw | https://github.com/openclaw/openclaw |
| Claude Code docs | https://docs.claude.com |
| Ruflo demos | https://flo.ruv.io / https://goal.ruv.io |
| NVIDIA Jetson Thor | https://www.nvidia.com/en-us/autonomous-machines/embedded-systems/jetson-thor/ |
| GL.iNet routers | https://www.gl-inet.com |
| Ollama | https://ollama.com |
| vLLM | https://docs.vllm.ai |
| Synology NAS | https://www.synology.com |
| UGREEN NAS | https://www.ugreen.com |
| Backblaze B2 | https://www.backblaze.com/cloud-storage |
| WireGuard | https://www.wireguard.com |
| AdGuard Home | https://github.com/AdguardTeam/AdGuardHome |

---

## 18. Conversation Summary

This handoff came from a design conversation covering:

1. Ruflo overview and Mac setup.
2. Ruflo vs OpenClaw.
3. Private AI network design with GL.iNet routers, two Jetson Thors, and Mac choices.
4. RAG architecture, storage math, namespace design, and indexing vs training.
5. PFO + PMA application and legal caveats.
6. marketingskills installation and skill usage.
7. Multi-business portfolio pattern and shared learning layer.
8. System spec and operational roadmap.

**Status:** Design complete. Ready for Phase 1 procurement.
