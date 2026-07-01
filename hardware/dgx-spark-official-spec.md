# NVIDIA DGX Spark — official vendor spec + family unit reconciliation

**Hostname:** `nephew-spark` · **LAN:** `192.168.10.205` · **WG:** `10.1.0.5`  
**Vendor product page:** https://www.nvidia.com/en-us/products/workstations/dgx-spark/  
**Vendor datasheet (PDF):** https://nvdam.widen.net/s/tlzm8smqjx/workstation-datasheet-dgx-spark-gtc25-spring-nvidia-us-3716899-web  
**Handbook chapter:** [`docs/setup/32-hardware-full-spec-sheet.md`](../docs/setup/32-hardware-full-spec-sheet.md) §2  
**Live fleet doc:** [`hardware/dgx-spark-frontier-node.md`](./dgx-spark-frontier-node.md)

> **Canonical vendor table below** — sourced from NVIDIA product page + GTC25 datasheet (July 2026).  
> **Our unit** (`nephew-spark`) is reconciled in §Family install — live probes win when they disagree.

---

## NVIDIA DGX Spark specifications (vendor)

| Field | Value |
|-------|-------|
| **Architecture** | NVIDIA Grace Blackwell |
| **GPU** | Blackwell Architecture |
| **CPU** | 20-core Arm — **10 Cortex-X925** + **10 Cortex-A725** |
| **CUDA Cores** | Blackwell Generation |
| **Tensor Cores** | 5th Generation |
| **RT Cores** | 4th Generation |
| **Tensor performance**¹ | Up to **1 PFLOP FP4** (theoretical, sparsity) |
| **System memory** | **128 GB LPDDR5x** — coherent unified system memory |
| **Memory interface** | **256-bit** |
| **Memory bandwidth** | **273 GB/s** |
| **Storage** | **4 TB NVMe M.2** with self-encryption |
| **USB** | **4× USB Type-C** |
| **Ethernet** | **1× RJ-45** — **10 GbE** |
| **NIC** | **ConnectX-7** @ **200 Gbps** (vendor option / integrated path) |
| **Wi-Fi** | **Wi-Fi 7** |
| **Bluetooth** | **BT 5.4** |
| **Audio** | HDMI multichannel audio output |
| **Power supply** | **240 W** |
| **GB10 TDP**² | **140 W** (CPU + GPU superchip) |
| **Display** | **1× HDMI 2.1a** · up to **3× DisplayPort** over USB-C (DP Alt Mode) |
| **NVENC / NVDEC** | **1× / 1×** |
| **OS** | **NVIDIA DGX™ OS** |
| **Dimensions** | **150 mm** L × **150 mm** W × **50.5 mm** H |
| **Weight** | **1.2 kg** |
| **SKU** | **940-54242-0000** |
| **Product description** | NVIDIA GB10 Grace Blackwell Superchip · 20-core Arm · 128 GB LPDDR5x · 4 TB NVMe M.2 |

¹ Theoretical FP4 TOPS using the sparsity feature.  
² TDP: Thermal Design Power of the GB10 chip, including CPU and GPU.

### Acoustic emissions (ECMA-109, June 2025)

| Mode | L<sub>WA,m</sub> (dB) | L<sub>pA,m</sub> (dB) | K<sub>v</sub> (dB) |
|------|----------------------|----------------------|-------------------|
| **Operating**³ | 35 | 29 | 3 |
| **Idle** | 19 | 13 | 3 |

³ Operating mode: max GPU stress in 25°C ambient.

---

## Family install — `nephew-spark` (live reconciled 2026-07-01)

| Field | Vendor | **Our unit (live)** | Notes |
|-------|--------|---------------------|-------|
| **Unified memory** | 128 GB LPDDR5x | **~122 GB** (`127,600,524 kB` MemTotal) | OS / firmware reservation — treat **121–128 GB** as one pool |
| **CPU cores** | 20 (X925 + A725) | **20** (`nproc`, aarch64) | Grace ARM confirmed |
| **Internal NVMe** | 4 TB encrypted | **Samsung MZALC4T0HBL1-00B07** · **3.7 TB** usable | Matches vendor capacity class |
| **M.2 expansion** | (datasheet: single 4 TB) | **+2 empty internal M.2 PCIe Gen5 ×4** | Hot-tier expansion — not in marketing table |
| **10 GbE RJ-45** | 1× 10 GbE | **Realtek 8127** `enP7s7` · **10 Gb/s** live | ✅ matches vendor RJ-45 class |
| **200 Gbps NIC** | ConnectX-7 | **Not in `lspci`** on this unit | Operator uses USB **1 GbE** dongle for Trusted LAN — see frontier-node doc |
| **USB-C** | 4× Type-C | **USB 3.2 Gen 2×2 (20 Gb/s)** per live audit — **not Thunderbolt** | DP Alt Mode may still apply per port |
| **Wi-Fi** | Wi-Fi 7 | **MediaTek 7925** `wlP9s9` | Present; down when wired |
| **OS** | DGX OS | **Ubuntu 24.04 LTS** aarch64 | DGX OS family / operator image |
| **Console** | HDMI / DP | Headless + **GL.iNet Comet KVM** | Physical console via IP KVM |

**Purchase proof (SME):** Amazon ASIN `B0FWJ16CCH` · 2026-05-24 · $5006.53 — see ch. 32 §13.

---

## Related

- [`docs/setup/31-m5-max-dgx-inference-setup.md`](../docs/setup/31-m5-max-dgx-inference-setup.md) — inference floor + bandwidth-bound model choice
- [`data/hardware-spec-registry.json`](../data/hardware-spec-registry.json) → `devices.dgx-spark`
- Nephew `docs/hardware-dgx-ground-truth.md` — agent coordination index