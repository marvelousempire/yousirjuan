# Chapter 1 — Hardware Inventory

**Status:** living · **Last verified:** 2026-07-01 full live audit (each node probed)
**Physical wiring & Protectli:** see [13-physical-topology-protectli.md](./13-physical-topology-protectli.md)
**Historia / vault memory:** see [14-historia-and-operator-memory.md](./14-historia-and-operator-memory.md)
**Every port / disk / speed / mod, power-ranked:** see [`hardware/fleet-capability-matrix.md`](../hardware/fleet-capability-matrix.md)  
**Full spec sheet (ports, link speeds, drives, cables, docks):** [32-hardware-full-spec-sheet.md](./32-hardware-full-spec-sheet.md) · [`data/hardware-spec-registry.json`](../../data/hardware-spec-registry.json)  
**Purchase proof (Amazon orders):** SME Family Inventory `http://search.localhost/orders` · ch. 32 §13

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
| **CPU** | NVIDIA **20-core Arm — 10× Cortex-X925 + 10× Cortex-A725** (aarch64) |
| **GPU** | **GB10 Grace Blackwell** — 5th-gen Tensor, 4th-gen RT; up to **1 PFLOP FP4** (sparsity); bandwidth **273 GB/s** (bandwidth-bound: MoE ≫ dense) |
| **Memory** | **128 GB LPDDR5x** unified, 256-bit @ 4266 MHz (**121 GB usable** in OS) |
| **Storage** | **4 TB NVMe M.2** self-encrypting (~3.7 TB usable; Samsung MZALC4T0HBL1) — **single M.2 slot, no spare** |
| **OS** | NVIDIA DGX OS (Ubuntu-based, aarch64) |
| **Ports** | **4× USB-C** (1× 240 W power + 3× 20 Gb/s data w/ DisplayPort-alt → up to 3× DP); **HDMI 2.1a**; **1× 10 GbE RJ-45**; **2× QSFP — ConnectX-7 @ 200 Gb/s** (for **Spark-to-Spark clustering**, not the NAS); **WiFi 7 + BT 5.4**. **No Thunderbolt** (USB-C = USB 3.2 Gen2×2) |
| **Network (live)** | **10 GbE** `enP7s7` — direct cable to NAS (`10.77.0.2/30`, NAS side IP pending); **1 GbE** USB dongle `enx…96c6` (in the Anker dock, on a USB 2.0 port) = LAN `.205` + internet; WG `10.1.0.5`; Comet KVM |
| **Best for** | Large-model serving (vLLM), embeddings + reranking, container orchestration, git forge |
| **Not for** | Creative edit station; portable work |

Detail: [`hardware/dgx-spark-official-spec.md`](../hardware/dgx-spark-official-spec.md) (NVIDIA vendor table) · [`hardware/dgx-spark-frontier-node.md`](../hardware/dgx-spark-frontier-node.md) (live fleet)

---

### MacBook Pro M5 Max (`fivemac`) — primary operator workstation · ✅ verified (local, 2026-07-01)

| Attribute | Value (probed on-host) |
|---|---|
| **Role** | Creative workstation, Cursor/Claude Code orchestration (this is the control node), Pockit gateway, M5 Holler voice edge, Obsidian host |
| **Model / chip** | **Mac17,6 — Apple M5 Max**, macOS 26.5.1 |
| **CPU / GPU** | **18-core CPU · 40-core GPU** (Metal 4) + Neural Engine |
| **Memory / Storage** | **128 GB** unified / **8 TB internal SSD** *(corrected — not 4 TB)* |
| **Thunderbolt** | **TB5 — up to 120 Gb/s** (2 ports) |
| **Attached fast storage** | **Samsung 990 Pro 2 TB** in a Hyper Next TB5 enclosure — **TB5 runs it at the drive's full ~7 GB/s** (unlike onemac's TB3 cap) |
| **Note** | Agents run **on** this host (local exec) — no SSH needed here. Authorize the fleet key only if a *remote* node (DGX / another Mac) must reach it for offload. |

---

### MacBook Pro M1 (`onemac`) — small edge node · ✅ verified

| Attribute | Value (probed 2026-07-01) |
|---|---|
| **Model / chip** | **MacBookPro17,1 — Apple M1** (2020, 8-core), macOS 26.5.1 |
| **Memory / Storage** | **8 GB RAM / 256 GB SSD** — *small; embeddings + STT on the ANE only, not the reranker or mid/large LLMs* |
| **Attached fast storage** | **Hyper Next Thunderbolt 5 enclosure + Samsung 990 Pro** (TB-native) — the fast local tier this node offloads to |
| **Best for** | Query embedding, WhisperKit STT, light tasks (capability-matched offload) |

---

### `bigmac` — Late-2012 iMac (legacy x86) · ✅ reachable via LAN

| Attribute | Value (probed 2026-07-01) |
|---|---|
| **Address** | LAN `192.168.10.182` · SSH `bigmac-claude` (user `abrownsanta`, key `id_ed25519_bigmac`) |
| **Spec** | **iMac13,2 — Intel i7-3770 quad @ 3.4 GHz, 8 GB RAM, GTX 675MX 1 GB, 1 TB 7200 HDD (SATA-II)**, macOS Catalina 10.15.8. *Legacy/weak — light x86 tasks only, not an offload powerhouse. Needs OCLP for a newer OS; internal SSD is the real upgrade.* No WireGuard needed — LAN + key |

### `twomac` — iMac18,2 (2017, OCLP'd) · ✅ verified (2026-07-01) · **= the "iMac 2017" node**

| Attribute | Value (probed 2026-07-01) |
|---|---|
| **Address** | **LAN `192.168.10.166`** (`id_ed25519_twomac` key). *Repoint the `twomac`/`twomac-claude` SSH alias off dead WG `10.1.0.6` → this LAN IP.* No WireGuard needed |
| **Model / CPU** | **iMac18,2 — 27″ Retina 5K iMac (2017)** · Intel **i5-7500** quad @ 3.4 GHz · **AMD Radeon Polaris 4 GB** |
| **Memory / Storage** | **64 GB RAM** (most of any Intel Mac here) · ~1 TB internal |
| **Thunderbolt** | TB3 (40 Gb/s) + **Sonnet Echo 11 TB4 dock** |
| **OS / mod** | **macOS 15.7.7 Sequoia via OpenCore Legacy Patcher** (Dortania present — OCLP running; 2017 iMac can't run 15.7 natively) |
| **Best for** | Light x86 node with real RAM — Docker services, CPU tasks, always-on background (64 GB ≫ bigmac's 8 GB) |

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
| **Link to DGX** | **Storage: 10 GbE** direct DGX `enP7s7` ↔ NAS 10GbE — **~1.25 GB/s** live (2026-07-01 `ethtool`). **LAN/management:** 1 GbE via DGX USB dongle `.205`. *DGX has one built-in 10 GbE port — bulk NFS should use the direct leg.* |

Notes: [`hardware/ugreen-dxp6800-pro-spec.md`](../hardware/ugreen-dxp6800-pro-spec.md) · legacy vault plan: [`hardware/ugreen-nas-code-vault.md`](../hardware/ugreen-nas-code-vault.md)

---

### VPS (`nephew-ct`) — public edge + Clinic · ✅ verified

| Attribute | Value (probed 2026-07-01) |
|---|---|
| **Spec** | **4 vCPU · 7 GB RAM · x86_64** (GoDaddy / `…secureserver.net`) |
| **Role** | Only intentionally **public** family edge (HTTPS); Clinic diagnostic hospital; reverse-proxy to mesh over WireGuard |
| **Security** | fail2ban, nftables, no raw internal service exposure |

---

### iMac 2017 (Intel, 64 GB) — **= `twomac`** (see above)

The "iMac 2017 · 64 GB" node **is the same physical machine as `twomac`** (iMac18,2, probed 2026-07-01). Not a separate box — this entry was double-counted. See the **`twomac`** row for verified specs. Role: light always-on x86 backend (Docker services, Postgres/Redis/Qdrant, CPU tasks) — now on **macOS 15.7 via OCLP** and reachable on the LAN.

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
DGX Spark (runtime, models, vLLM serving — 4TB NVMe M.2 hot tier)
    ↕ 10 GbE direct (enP7s7 ↔ NAS) — bulk storage/NFS
    ↕ 1 GbE USB dongle — Trusted LAN .205
NAS DXP6800 Pro (SSD Pool 1 = model cache · HDD Pool 2 = git objects/media/backups)
```

---

## Open action items (from the 2026-07-01 audit)

1. **Confirm NFS/SMB mounts bind to the 10 GbE path** — `enP7s7` is live at 10 Gb/s; verify bulk I/O does not accidentally route over the 1 GbE USB leg.
2. **Authorize the fleet SSH key on `fivemac`** (publickey denied) — the primary workstation is unreachable to agents.
3. **Bring `twomac` / `bigmac` / `zeromac` onto the mesh** (WG + keys) — three Mac nodes currently unreachable.
4. **990 Pros stay in the Mac TB enclosures** — the DGX has one M.2 slot (occupied); no internal storage expansion.

---

## Related

- [32-hardware-full-spec-sheet.md](./32-hardware-full-spec-sheet.md) — every port, link speed, drive, cable, dock
- [02-network-security.md](./02-network-security.md) — how machines connect
- [03-software-services.md](./03-software-services.md) — what runs on each node
- [`hardware/dgx-spark-frontier-node.md`](../hardware/dgx-spark-frontier-node.md) — DGX detail
