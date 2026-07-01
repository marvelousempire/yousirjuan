# Chapter 1 — Hardware Inventory

**Status:** living · **Last verified:** 2026-07-01 full live audit (each node probed)
**Physical wiring & Protectli:** see [13-physical-topology-protectli.md](./13-physical-topology-protectli.md)
**Historia / vault memory:** see [14-historia-and-operator-memory.md](./14-historia-and-operator-memory.md)

> **Verification legend** — every row below carries a live-probe status, not marketing:
> ✅ **verified** (probed 2026-07-01) · ⚠️ **reachable but not fully verified** (SSH/creds blocked) ·
> 🔴 **known but unreachable now** (needs mesh/key/power) · ⚪ **offline** (not on the network) ·
> 📋 **planned / not acquired**.

---

## Design philosophy

Different hardware **specializes**. The stack avoids running heavy inference on creative workstations or treating laptops as always-on servers. Workloads route to the node that matches compute, storage, and availability.

| Principle | Meaning |
|---|---|
| **Sovereign** | Core AI, data, and voice run on operator-owned hardware — not rented cloud for the family path |
| **Complementary nodes** | Apple Silicon excels at dev, ANE voice front-end, orchestration; NVIDIA GB10 excels at CUDA inference |
| **Durable vs fast storage** | NAS holds git objects, backups, archives; NVMe on compute nodes holds models and hot datasets |
| **Capability-matched offload** | Reserve the GB10 for what only it can do; provision every other node for the work it can handle (RL-FLEET-OFFLOAD-001) |

---

## Machine roster

### DGX Spark (`nephew-spark`) — frontier compute node · ✅ verified

| Attribute | Value (probed 2026-07-01) |
|---|---|
| **Role** | Nephew's **body** — production inference, RAG, Docker fleet, git forge, Matrix, voice servers |
| **CPU** | NVIDIA **Grace ARM, 20 cores** (aarch64) |
| **GPU** | NVIDIA **GB10 Grace Blackwell** (CUDA-native) — memory-bandwidth ~273 GB/s (bandwidth-bound: MoE ≫ dense) |
| **Memory** | **121 GB unified** LPDDR5X (one pool shared by GPU + CPU) |
| **Storage** | **3.7 TB internal NVMe** (Samsung MZALC4T0HBL1) **+ 2 empty internal M.2 Gen5 ×4 slots** (spare hot tier — a Gen4 NVMe here runs ~7 GB/s) |
| **OS** | Ubuntu LTS (aarch64) |
| **Network** | **1× 10 GbE RJ45** (Realtek 8127) — currently on a **dead point-to-point link** `10.77.0.2/30`, **NOT cabled to the NAS**; LAN + NAS run over a **1 GbE USB ethernet dongle** (`.205`) — the real bottleneck; WiFi (MediaTek 7925); WG mesh `10.1.0.5`; Comet KVM console. **No Thunderbolt** (USB-C = USB 3.2 Gen 2×2 / 20 Gbps); **no ConnectX/QSFP** present |
| **Best for** | Large-model serving (vLLM), embeddings + reranking, container orchestration, git forge |
| **Not for** | Creative edit station; portable work |

Detail: [`hardware/dgx-spark-frontier-node.md`](../hardware/dgx-spark-frontier-node.md)

---

### MacBook Pro M5 Max (`fivemac`) — primary operator workstation · ⚠️ reachable, SSH not authorized

| Attribute | Value |
|---|---|
| **Role** | Creative workstation, Cursor/Claude Code orchestration, Pockit gateway, M5 Holler voice edge, Obsidian host |
| **CPU / GPU / ANE** | M5 Max — high-core CPU, 40-core GPU, 16-core Neural Engine *(per spec — not re-probed 2026-07-01: SSH publickey denied)* |
| **Memory / Storage** | 128 GB unified / 4 TB SSD *(per spec)* |
| **Attached fast storage** | **Hyper Next Thunderbolt 5 enclosure + Samsung 990 Pro** (TB-native here → ~5–6 GB/s) |
| **Action item** | **SSH access is locked (publickey denied)** — authorize the fleet key so agent-comms + capability-offload can reach the primary workstation |

---

### MacBook Pro M1 (`onemac`) — small edge node · ✅ verified

| Attribute | Value (probed 2026-07-01) |
|---|---|
| **Model / chip** | **MacBookPro17,1 — Apple M1** (2020, 8-core), macOS 26.5.1 |
| **Memory / Storage** | **8 GB RAM / 256 GB SSD** — *small; embeddings + STT on the ANE only, not the reranker or mid/large LLMs* |
| **Attached fast storage** | **Hyper Next Thunderbolt 5 enclosure + Samsung 990 Pro** (TB-native) — the fast local tier this node offloads to |
| **Best for** | Query embedding, WhisperKit STT, light tasks (capability-matched offload) |

---

### `bigmac` — Mac fleet node · 🔴 unreachable now

| Attribute | Value |
|---|---|
| **Address** | `192.168.10.182` · SSH alias `bigmac-claude` |
| **Status** | **Host down / timeout** on 2026-07-01 probe. Strongest Mac offload candidate when up — verify specs + provision on next contact |

### `twomac` — Mac fleet node · 🔴 unreachable now (access exists)

| Attribute | Value |
|---|---|
| **Address** | WG `10.1.0.6` · SSH alias `twomac-claude` |
| **Status** | **WG down + host key changed** (reimaged?). Operator has access — needs mesh/key re-establishment to bring online |

### `zeromac` — Mac fleet node · 🔴 unreachable now

| Attribute | Value |
|---|---|
| **Status** | Does not resolve (no mDNS / not on the network on 2026-07-01). Exists per operator — register + probe when connected |

---

### Mac mini M4 Pro — persistent orchestration node · ⚪ offline

| Attribute | Value |
|---|---|
| **Spec** | 48 GB unified / 4 TB SSD / 10 GbE *(per spec)* |
| **Status** | **Not on the network** 2026-07-01 (no mDNS). Role when deployed: always-on light services, Open WebUI, queue workers |

---

### UGREEN DXP6800 Pro — network storage tier · ✅ verified (UGOS)

| Attribute | Value (from UGOS 2026-07-01) |
|---|---|
| **Role** | Durable storage — git objects, Historia/vault, media, model-cache tier |
| **Pool 1 (fast)** | **2× 1.8 TB M.2 SSD, RAID 1 → 1.8 TB** (nearly empty — the right home for the **family model cache**) |
| **Pool 2 (bulk)** | **4× 3.6 TB HDD, RAID 5 → 10.8 TB** + **2 empty HDD bays** |
| **LAN** | `192.168.10.119` (`nasa.local`); has a **10 GbE RJ45 port**; SSH via UGOS |
| **Link to DGX** | **Current: 1 GbE** (DGX reaches it over its USB dongle, ~125 MB/s). **Plan: direct 10 GbE cable** DGX `enP7s7` ↔ NAS 10 GbE (`/30`) → ~1.25 GB/s (10×). *DGX has only one 10 GbE port.* |

Notes: [`hardware/ugreen-nas-code-vault.md`](../hardware/ugreen-nas-code-vault.md)

---

### VPS (`nephew-ct`) — public edge + Clinic · ✅ verified

| Attribute | Value (probed 2026-07-01) |
|---|---|
| **Spec** | **4 vCPU · 7 GB RAM · x86_64** (GoDaddy / `…secureserver.net`) |
| **Role** | Only intentionally **public** family edge (HTTPS); Clinic diagnostic hospital; reverse-proxy to mesh over WireGuard |
| **Security** | fail2ban, nftables, no raw internal service exposure |

---

### iMac 2017 (Intel, 64 GB) — legacy x86 node · ⚪ offline

| Attribute | Value |
|---|---|
| **Role** | Optional always-on x86 backend (Postgres, Redis, Qdrant, nginx, light Ollama) |
| **Status** | **Not on the network** 2026-07-01. CPU-only — small models only |

Notes: [`docs/hardware/imac-2017-intel-i5.md`](../hardware/imac-2017-intel-i5.md)

---

### Jetson Thor — edge AI · 📋 planned (not acquired)

Architecture slot reserved for edge multimodal AI (robotics, vision, edge voice). Acquire when edge workloads justify it.

---

## Network & KVM hardware

| Device | Role | Status |
|---|---|---|
| **Verizon 5G Business Gateway** | WAN — IP passthrough to router | live |
| **GL-MT6000 (Flint 2)** | **Sole router / firewall / Wi-Fi / WG server** (`192.168.10.1`) | ✅ up |
| **GL-MT5000 (Brume 3)** | 2.5 G switch on MT6000 LAN; future travel WG client | live |
| **Protectli VP6670** | OPNsense firewall/router/WG — i7-1255U, 32 GB+, 1 TB NVMe | 📋 arriving |
| **Apple AirPort Extreme ×2** | Bridge APs for coverage | live |
| **Comet GL-RM10RC** | **KVM only** to DGX (not a router) | live |
| **HyperDrive TB5 / Sonnet Echo 11 / Anker Prime 14-in-1** | MacBook desk docks | — |

Full cabling: [13-physical-topology-protectli.md](./13-physical-topology-protectli.md)

---

## Workload routing table

| Workload | Preferred node |
|---|---|
| Family LLM inference (production) | DGX Spark (vLLM) |
| RAG embed + rerank | DGX Spark |
| Voice STT/TTS (production) | DGX Spark containers |
| Query embedding / STT (offload) | Mac ANE (onemac; fivemac when SSH fixed) |
| Agent dev (Cursor/Claude), creative | MacBook M5 Max (fivemac) |
| Git forge compute | DGX Spark |
| Git object durability / backups / model-cache | NAS (SSD Pool 1 for cache, HDD Pool 2 for bulk) |
| Public HTTPS edge · Clinic | VPS |
| Light always-on APIs | Mac mini (when deployed) or iMac |

---

## Storage topology (conceptual)

```text
MacBooks (active projects, dev trees, 990 Pro TB5 fast local tiers on onemac/fivemac)
    |  git push
DGX Spark (runtime, models, vLLM serving — 3.7TB NVMe hot tier + 2 empty M.2)
    ↕ 1 GbE now (USB dongle)  ->  PLAN: direct 10 GbE cable
NAS DXP6800 Pro (SSD Pool 1 = model cache · HDD Pool 2 = git objects/media/backups)
```

---

## Open action items (from the 2026-07-01 audit)

1. **Cable DGX 10 GbE (`enP7s7`) ↔ NAS 10 GbE** → 10× NAS throughput (currently 1 GbE via USB dongle).
2. **Authorize the fleet SSH key on `fivemac`** (publickey denied) — the primary workstation is unreachable to agents.
3. **Bring `twomac` / `bigmac` / `zeromac` onto the mesh** (WG + keys) — three Mac nodes currently unreachable.
4. **Populate a DGX internal M.2 slot** (or use a 990 Pro) as a dedicated model-weights hot tier.

---

## Related

- [02-network-security.md](./02-network-security.md) — how machines connect
- [03-software-services.md](./03-software-services.md) — what runs on each node
- [`hardware/dgx-spark-frontier-node.md`](../hardware/dgx-spark-frontier-node.md) — DGX detail
