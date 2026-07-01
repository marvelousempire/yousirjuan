# Chapter 1 — Hardware Inventory

**Status:** living · **Last verified:** 2026-06-15 hardware audit  
**Physical wiring & Protectli:** see [13-physical-topology-protectli.md](./13-physical-topology-protectli.md)  
**Historia / vault memory:** see [14-historia-and-operator-memory.md](./14-historia-and-operator-memory.md)

---

## Design philosophy

Different hardware **specializes**. The stack avoids running heavy inference on creative workstations or treating laptops as always-on servers. Workloads route to the node that matches compute, storage, and availability requirements.

| Principle | Meaning |
|---|---|
| **Sovereign** | Core AI, data, and voice run on operator-owned hardware — not rented cloud for the family path |
| **Complementary nodes** | Apple Silicon excels at dev, ANE voice front-end, and orchestration; NVIDIA excels at CUDA inference and training |
| **Durable vs fast storage** | NAS holds git objects, backups, archives; NVMe on compute nodes holds models and hot datasets |
| **Always-on vs portable** | DGX + NAS + router run 24/7; MacBook is the primary creative and control-plane laptop |

---

## Machine roster

### DGX Spark (`nephew-spark`) — frontier compute node

| Attribute | Value |
|---|---|
| **Role** | Nephew's **body** — production inference, RAG, Docker fleet, git forge compute, Matrix, voice servers |
| **CPU** | NVIDIA Grace ARM (20 cores: performance + efficiency) |
| **GPU** | NVIDIA GB10 Grace Blackwell (CUDA-native) |
| **Memory** | ~122 GB unified LPDDR5X |
| **Storage** | 3.7 TB internal NVMe (Samsung, models/containers/hot indexes) **+ 2 empty internal M.2 NVMe slots (PCIe Gen5 ×4)** — spare hot-tier expansion (a Gen4 NVMe here runs ~7 GB/s, faster than any external enclosure) |
| **OS** | Ubuntu LTS (aarch64) |
| **Network (measured 2026-07-01)** | **1× 10 GbE RJ45** (Realtek 8127) — currently on a **dead point-to-point link** `10.77.0.2/30`, **NOT** cabled to the NAS; **LAN + NAS reached over a 1 GbE USB ethernet dongle** (`.205`, Realtek 8153) — the real current bottleneck; WiFi (MediaTek 7925); WG mesh `10.1.0.5`; Comet KVM. **No Thunderbolt** (USB-C ports are USB 3.2 Gen 2×2 / 20 Gbps); **no ConnectX/QSFP** present. *Correction: earlier "10GbE direct to NAS" was aspirational — see the 10 GbE plan under NAS.* |
| **Best for** | Large-model serving, embeddings + reranking on GPU, fine-tuning, concurrent family workloads, container orchestration |
| **Not for** | Final Cut / DaVinci primary edit station; portable operator work |

Detailed product notes: [`hardware/dgx-spark-frontier-node.md`](../../hardware/dgx-spark-frontier-node.md)

---

### MacBook Pro M5 Max (FIVEMAC) — primary operator workstation

| Attribute | Value |
|---|---|
| **Role** | Creative workstation, coding, Cursor/Claude Code orchestration, Pockit gateway, **M5 Holler voice edge**, Obsidian host |
| **CPU / GPU / ANE** | M5 Max — high-core-count CPU, 40-core GPU, 16-core Neural Engine |
| **Memory** | 128 GB unified |
| **Storage** | 4 TB SSD |
| **Network** | Trusted LAN Wi-Fi or wired; NAS SMB **`/Volumes/historia`**; `OLLAMA_HOST` → DGX; local tower-api proxy |
| **LaunchAgents** | tower-api, vault-watcher, LiveSync bridge, m5-voice-edge (see ch. 14) |
| **Best for** | Blender, Unreal, Resolve, Xcode, agent development, Parakeet voice pad, sovereign vault editing |

---

### MacBook Pro M1 (ONEMAC-2) — legacy operator laptop

| Attribute | Value |
|---|---|
| **Role** | Secondary Mac, travel, light dev |
| **Dock** | HyperDrive TB5 — 2.5G Ethernet + NVMe |
| **Network** | House Trusted LAN |

---

### Mac mini M4 Pro — persistent orchestration node (when deployed)

| Attribute | Value |
|---|---|
| **Role** | Always-on lightweight services, Open WebUI, queue workers, background automation |
| **Memory** | 48 GB unified |
| **Storage** | 4 TB SSD |
| **Network** | 10 Gigabit Ethernet preferred |
| **Best for** | Services that should survive laptop sleep; lighter inference; Tailscale/WireGuard coordination |

---

### UGREEN DXP6800 Pro — network storage tier

| Attribute | Value |
|---|---|
| **Role** | Durable storage — git object store, Historia/sovereign vault, media, **target** for Matrix + heavy Docker |
| **LAN** | `192.168.10.119` (`nasa.local`); SSH often non-default port on UGOS |
| **Model / disks (measured 2026-07-01)** | UGREEN **DXP6800 Pro** — **Pool 1: 2× 1.8 TB M.2 SSD, RAID 1 → 1.8 TB fast tier** (nearly empty — the right home for the family model cache); **Pool 2: 4× 3.6 TB HDD, RAID 5 → 10.8 TB bulk**; **+ 2 empty HDD bays**. Has a 10 GbE RJ45 port. |
| **Link to DGX (current vs. plan)** | **Current: 1 GbE** — the DGX reaches the NAS over its **USB gigabit dongle** (~125 MB/s). **Plan: direct 10 GbE** — cable the DGX's single 10 GbE RJ45 ↔ the NAS 10 GbE port (point-to-point `/30`), remount NFS over it for ~1.25 GB/s (10×). The DGX has only **one** 10 GbE port (no "#1/#2"). |
| **Stores** | Gitea repositories (objects on NAS, metadata DB stays on compute node), Qdrant snapshots, raw-docs archives, family media; **family model cache belongs on the SSD Pool 1**, not the HDD pool |
| **Best for** | Anything that must survive a compute-node rebuild |
| **Not for** | Primary GPU inference or live vector index hot path (kept on DGX for latency today) |

Notes: [`hardware/ugreen-nas-code-vault.md`](../../hardware/ugreen-nas-code-vault.md)

---

### VPS (`nephew-ct`) — public edge + Clinic

| Attribute | Value |
|---|---|
| **Role** | Only intentionally **public** family edge (HTTPS); hosts Clinic diagnostic hospital; reverse-proxies to mesh services over WireGuard |
| **OS** | Linux server |
| **Best for** | TLS termination, public apex pages, Clinic cases, outbound-only tunnel endpoints |
| **Security** | fail2ban, iptables/nftables, no raw internal service exposure |

Configs live in `vps/` in this repo.

---

### iMac 2017 (Intel, 64 GB RAM) — legacy runtime node

| Attribute | Value |
|---|---|
| **Role** | Optional always-on x86 backend (Postgres, Redis, Qdrant, nginx, light Ollama) |
| **Limit** | CPU-only inference — small models only; not a replacement for DGX or M5 ANE path |
| **Best for** | Docker x86 services, web hosting, async small-model tasks |

Notes: [`docs/hardware/imac-2017-intel-i5.md`](../hardware/imac-2017-intel-i5.md)

---

### Jetson Thor — edge AI (planned / candidate)

| Attribute | Value |
|---|---|
| **Role** | Edge multimodal AI — robotics, vision pipelines, voice at the edge |
| **Best for** | Embeddings at edge, autonomous systems, distributed experimentation |
| **Status** | Architecture slot reserved; acquire when edge workloads justify it |

---

## Network & KVM hardware

| Device | Role |
|---|---|
| **Verizon 5G Business Gateway** | WAN — IP passthrough to main router (LAN2) |
| **GL-MT6000 (Flint 2)** | **Live:** sole router, firewall, Wi-Fi, WG server (`192.168.10.1`) |
| **GL-MT5000 (Brume 3)** | **Live:** dumb 2.5G switch on MT6000 LAN · **Future:** travel WG client |
| **Protectli VP6670** | **Arriving** — OPNsense firewall/router/WG · i7-1255U, 32GB+, 1TB NVMe |
| **GL-AX1800 (Slate)** | Interim IoT/AP in older plans — retiring |
| **Apple AirPort Extreme ×2** | Bridge APs for coverage |
| **Comet GL-RM10RC** | **KVM only** to DGX — not a router |
| **HyperDrive TB5 / Sonnet Echo 11 / Anker Prime 14-in-1** | Desk docks for MacBooks |

Full cabling ASCII: [13-physical-topology-protectli.md](./13-physical-topology-protectli.md)

---

## Workload routing table

| Workload | Preferred node |
|---|---|
| Family LLM inference (production) | DGX Spark |
| RAG embed + rerank (GPU) | DGX Spark |
| Voice STT/TTS (production) | DGX Spark containers |
| Agent development (Cursor/Claude) | MacBook M5 Max |
| Local ANE Whisper / small models | MacBook M5 Max |
| Creative (video, 3D, Unreal) | MacBook M5 Max |
| Git forge compute | DGX Spark |
| Git object durability | NAS |
| Public HTTPS edge | VPS |
| Clinic diagnostics | VPS |
| Pockit gateway (local doors) | Operator Mac |
| Long-term backups | NAS |
| Light always-on APIs | Mac mini or iMac |

---

## Storage topology (conceptual)

```text
MacBook (active projects, dev trees)
    ↓ sync / git push
DGX Spark (runtime, models, hot Qdrant)
    ↕ 10GbE
NAS (git objects, snapshots, media, vault mirrors)
```

---

## Related

- [02-network-security.md](./02-network-security.md) — how machines connect
- [03-software-services.md](./03-software-services.md) — what runs on each node
- [`docs/hardware-topology.md`](../hardware-topology.md) — generic workload separation reference
