# Fleet Capability Matrix

**Status:** living · **Last verified:** 2026-07-22 (unified CI/Git fleet campaign)
Parent roster: [`setup/01-hardware.md`](../setup/01-hardware.md) · DGX detail: [`dgx-spark-frontier-node.md`](./dgx-spark-frontier-node.md)

The trustworthy "what can each box actually do" sheet — **every device, every port, every disk, real speeds, and the mods applied.** Ordered by compute power. Rows are ✅ **live-verified**, ⚠️ **reachable-but-locked**, 🔴 **unreachable**, ⚪ **offline**.

> **Speeds below are the *link/interface* ceilings** (what the port/bus negotiates). Measured transfer benchmarks (real MB/s via `make storage-bench` / `dd`) are appended per node as they're run — see **Benchmark log** at the end.

---

> **⚠ TRUTH BANNER (2026-07-15):** There is **NO Mac mini M4 Max / M4 Pro** in this fleet — it was **never purchased** (verified against Bank Reader statements + SME; zero hits). Some whitepaper/PRD/roadmap docs still reference it as "Node B / persistent orchestration server" — that is **planning fiction, not deployed hardware**. This matrix (live-probed) is the authoritative list of what exists. Do **not** plan offload duties onto a Mac mini. (Also corrected: **bigmac is the *weakest* node** — a 2012 iMac — not "strongest".)

## Power ranking (compute → usability)

| # | Node | Chip | Cores | RAM | Class | Status |
|---|---|---|---|---|---|---|
| 1 | **DGX Spark** | NVIDIA GB10 Blackwell + Grace | 20 (ARM) + GPU | **128 GB** unified | Frontier AI runtime | ✅ verified |
| 2 | **fivemac** | Apple **M5 Max** (Mac17,6) | 18 CPU + 40-GPU | **128 GB** · 8 TB · TB5 120Gb | Primary workstation / control node | ✅ verified |
| 3 | **twomac** (= iMac 2017) | Intel **i5-7500** (iMac18,2, 2017) | 4 | **64 GB** · macOS 15.7 (OCLP) | Light x86 backend (real RAM) | ✅ verified |
| 4 | **onemac** | Apple **M1** | 8 (4P+4E) | **8 GB** | Small edge (embed/STT) | ✅ verified |
| 5 | **bigmac** | Intel **i7-3770** (2012) | 4 | **8 GB** | Legacy x86 (light) | ✅ verified |
| — | **NAS DXP6800 Pro** | (storage) | — | — | Durable storage tier | ✅ verified |
| — | **VPS** | 4 vCPU x86_64 | 4 | 7 GB | Public edge / Clinic | ✅ verified |

*Note: usability ≠ raw spec. onemac (8 GB) outranks bigmac in practice (Apple Silicon + ANE), but both are "light" nodes. fivemac is #2 by spec but currently unreachable to agents.*

---

## ✅ DGX Spark (`nephew-spark`) — frontier node

| Layer | Detail (verified 2026-07-01) |
|---|---|
| **Compute** | **GB10 Grace Blackwell**; **20-core Arm** (10× Cortex-X925 + 10× Cortex-A725); Blackwell GPU (5th-gen Tensor, up to **1 PFLOP FP4**); bandwidth **273 GB/s** (bandwidth-bound → MoE ≫ dense) |
| **Memory** | **128 GB LPDDR5x** unified, 256-bit @ 4266 MHz (**121 GB usable**) |
| **Internal storage** | **4 TB NVMe M.2** self-encrypting (~3.7 TB usable, ~5 GB/s) — **single M.2 slot, no spare** |
| **USB-C ports** | **4× USB-C**: 1× **240 W power**, 3× **20 Gb/s data** (USB 3.2 Gen2×2 + DisplayPort-alt). **No Thunderbolt** |
| **Other ports** | **HDMI 2.1a**; **1× 10 GbE RJ-45**; **2× QSFP = ConnectX-7 @ 200 Gb/s** (Spark-clustering only — QSFP, not for the NAS); **WiFi 7 + BT 5.4** |
| **Network (live)** | **10 GbE `enP7s7`** cabled direct to NAS (`10.77.0.2/30`, NAS IP pending); **1 GbE USB dongle** (Anker dock, on USB 2.0) = LAN+internet; WG `10.1.0.5` |
| **⚠️ Port defect** | The **1 GbE dongle is plugged into a USB 2.0 (480 Mb/s) port** → NAS capped at **~40 MB/s**. Move it to a 20 Gb/s port → full gigabit today |
| **Mods** | none required; arm64-native Docker fleet |
| **Best for** | vLLM serving, RAG embed/rerank, forge, containers |

---

## ✅ onemac — MacBook Pro M1 (small edge)

| Layer | Detail (verified 2026-07-01) |
|---|---|
| **Compute** | Apple **M1**, 8 cores (4P+4E); MacBookPro17,1 (2020), macOS 26.5.1 |
| **Memory** | **8 GB** unified (small — ANE embeddings + STT only) |
| **Internal storage** | **256 GB** (APPLE SSD AP0256Q, TRIM) |
| **Ports** | **2× Thunderbolt 4 / USB4 @ 40 Gb/s** (one per bus) |
| **Attached fast disk** | **2 TB Samsung 990 Pro** in a **HyperDrive Thunderbolt 5 Dock** — ⚠️ **M1 negotiates only TB3/USB4 = 40 Gb/s** (not TB5), so the 990 Pro runs to its ~3.5 GB/s NVMe ceiling, not TB5's 80 Gb/s |
| **Mods** | stock Apple Silicon |
| **Best for** | query embedding, WhisperKit STT, light tasks |

---

## ✅ bigmac — Late-2012 iMac (legacy x86)

| Layer | Detail (verified 2026-07-01) |
|---|---|
| **Compute** | **Intel Core i7-3770** quad @ 3.4 GHz (Ivy Bridge, 2012); iMac13,2; **NVIDIA GTX 675MX 1 GB** |
| **Memory** | **8 GB** |
| **Internal storage** | **1 TB 7200-RPM HDD** (APPLE HDD ST1000DM003) on **SATA-II, negotiated 3 Gb/s** → ~120 MB/s. **The main limiter — an internal SSD swap matters more than the OS** |
| **Ports** | **1× USB 3.0 (5 Gb/s)**, **2× USB 2.0 (480 Mb/s)**, **2× Thunderbolt 1 (10 Gb/s)**, built-in Gigabit Ethernet |
| **OS / mods** | **macOS Catalina 10.15.8** (last natively supported). Has a **`Dortania` folder** (OCLP touched) but is **not yet running a patched newer OS** — needs a full **OpenCore Legacy Patcher** pass to modernize (like twomac) |
| **Best for** | light x86 Docker / CPU-only small tasks; not an inference node |

---

## ✅ NAS — UGREEN DXP6800 Pro (storage)

| Layer | Detail (verified from UGOS 2026-07-01) |
|---|---|
| **Pool 1 (fast)** | **2× 1.8 TB M.2 SSD, RAID 1 → 1.8 TB** (nearly empty) — model-cache tier |
| **Pool 2 (bulk)** | **4× 3.6 TB HDD, RAID 5 → 10.8 TB** + **2 empty HDD bays** |
| **Ports** | **10 GbE RJ45** (+ additional NIC), USB |
| **Link to DGX** | **1 GbE now** (over the DGX USB dongle, ~40–125 MB/s); **plan: direct 10 GbE cable** → ~1.25 GB/s |
| **Access** | NFS mounts on DGX (`/mnt/nas-media`, `/mnt/nas-docker`); `nephew` user for rw |

---

## ✅ VPS (`nephew-ct`) — public edge

| Layer | Detail (verified 2026-07-01) |
|---|---|
| **Compute** | **4 vCPU · x86_64** (GoDaddy `…secureserver.net`) |
| **Memory** | **7 GB** |
| **Role** | Public HTTPS edge, Clinic, WG reverse-proxy — not a compute node |

---

## ⚠️/🔴 Pending access (rows to complete)

| Node | Blocker | Unblock |
|---|---|---|
| **zeromac** | not on the network | connect + register |

*(fivemac ✅ verified 2026-07-01 — it's the control node; agents run on it locally, no SSH needed. Mac17,6 M5 Max · 18C/40G · 128 GB · 8 TB · TB5 120 Gb/s · 990 Pro 2 TB.)*

Full specs for these land in a follow-up PR once reachable (per the "ship reachable now, append later" plan).

---

## 🔧 Action items surfaced by this audit

1. **Move the DGX 1 GbE dongle off its USB 2.0 port** → a 20 Gb/s USB port = ~3× NAS throughput *today* (before the 10 GbE cable).
2. **Cable DGX 10 GbE (`enP7s7`) ↔ NAS 10 GbE** → ~1.25 GB/s NAS.
3. **bigmac: internal SSD swap** (the SATA-II 7200 HDD is the bottleneck) **+ OCLP** to modernize the OS.
4. **990 Pros stay in the Mac TB enclosures** — the DGX has one (occupied) M.2 slot; no internal expansion.
5. **Authorize SSH on fivemac + twomac** to complete this matrix.

---

## Benchmark log (measured — appended as run)

### Unified CI/Git workload (`ci.git.fleet` 1.1.0, 2026-07-22)

All reachable Macs and Spark ran Benchlab 0.3.0 at identical Git SHA `223d46e` with Node 22.23.1.
The workload covers local clone/fetch/push/checkout, dependency installation, test, build, durable
write, queue delay, service health, and simulated failure recovery. All 200 authoritative samples
passed. Zeromac remained unreachable and was not assigned synthetic results.

| Node | Cold overall p95 | Warm overall p95 | Warm durable write | Placement finding |
|---|---:|---:|---:|---|
| Spark | 615.79 ms | 610.06 ms | 24.02 ms | Keep forge authority; fastest baseline |
| onemac | 991.95 ms | 978.43 ms | 21.87 ms | Best Mac CI worker; concurrency 1 |
| bigmac | 2110.12 ms | 2075.10 ms | 405.56 ms | Light warm-cache jobs only |
| twomac | 2331.05 ms | 2434.99 ms | 398.42 ms | Memory-resident services/background isolation |
| zeromac | — | — | — | Register and provision before testing |

Canonical evidence: `marvelousempire/standard-benchmark-stack`, campaign
`fleet-ci-git-expanded-2026-07-22`.

### DGX ↔ NAS over the direct 10 GbE link (`dd`, 2026-07-01)

| Config | Write | Read (cache-cleared) | Read (O_DIRECT) |
|---|---|---|---|
| MTU 1500 | 1.0 GB/s | 809 MB/s | 631 MB/s |
| **MTU 9000 (jumbo)** | **1.1 GB/s** | **~1.2 GB/s** | — |
| *(old path — NAS via DGX USB-2.0 dongle)* | ~40 MB/s | — | — |

Jumbo ping `ping -M do -s 8972 10.77.0.1` → 0% loss, 0.4 ms. Net result: **~20–30× the old NAS path**, at 10 GbE line rate. Setup + persistence: [`../runbooks/dgx-nas-10gbe-direct-link.md`](../runbooks/dgx-nas-10gbe-direct-link.md).

> **NAS MTU:** only **LAN2** (the direct 10 GbE link to the DGX) is MTU 9000. **LAN1** (the 2.5 GbE LAN/router port) stays **1500** to match the LAN.

*Still to record: DGX internal NVMe, onemac 990 Pro, bigmac HDD, NAS pools direct (`make storage-bench MOUNT=<path>`).*

---

## Related

- [`setup/01-hardware.md`](../setup/01-hardware.md) — roster
- [`dgx-spark-frontier-node.md`](./dgx-spark-frontier-node.md) — DGX detail
- Nephew `make storage-bench MOUNT=<path>` — the transfer-speed benchmark
