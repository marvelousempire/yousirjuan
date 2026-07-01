# Chapter 32 — Full Hardware Spec Sheet (ports, speeds, drives, cables)

**Status:** living · **Last verified:** Wednesday, July 1, 2026 (DGX live probe + UGREEN vendor page)  
**Canonical:** this file + [01-hardware.md](./01-hardware.md) roster · vendor deep-dive: [`hardware/ugreen-dxp6800-pro-spec.md`](../../hardware/ugreen-dxp6800-pro-spec.md)  
**Machine-readable:** [`data/hardware-spec-registry.json`](../../data/hardware-spec-registry.json)

Agents cite hardware **here and in yousirjuan `docs/setup/` first** — not Synology assumptions, not chat memory. When this sheet disagrees with Nephew mirrors, **yousirjuan wins**.

---

## Legend

| Tag | Meaning |
|-----|---------|
| **✅ live** | Measured or read from the device this session |
| **📦 installed** | Operator-confirmed inventory in the rack today |
| **📄 vendor** | Manufacturer datasheet / product page (chassis capability) |
| **🔄 plan** | Approved wiring not yet live |
| **⚠️ confirm** | Fill from UGOS UI, `system_profiler`, or physical label |

---

## 1. UGREEN NASync DXP6800 Pro (`nasa.local` / `192.168.10.119`)

**Product:** [UGREEN NASync DXP6800 Pro](https://nas.ugreen.com/products/ugreen-nasync-dxp6800-pro-nas-storage) · SKU **25898** · OS **UGOS Pro** (not Synology DSM).

### 1.1 Chassis — vendor capability (📄)

| Field | Spec |
|-------|------|
| **CPU** | Intel **Core i5-1235U** — 12th Gen, **10 cores / 12 threads**, x86_64 |
| **RAM (stock)** | **8 GB DDR5-4800** (SO-DIMM) |
| **RAM (max)** | **64 GB DDR5** (expandable) |
| **System disk** | **128 GB SSD** (factory) |
| **SATA bays** | **6× 3.5″/2.5″** (SATA 6 Gb/s) |
| **M.2 slots** | **2× NVMe** (M.2) |
| **Max raw capacity** | **208 TB** vendor rating (6× 32 TB HDD + 2× 8 TB M.2) |
| **RAID** | JBOD / Basic / RAID 0 / 1 / 5 / 6 / 10 |
| **ODECC** | Supported |
| **PCIe** | **1× PCIe ×4** expansion slot |
| **Dimensions** | 11.54 × 10.16 × 7.87 in (L×W×H) |
| **Power** | **43.07 W** (drive access) · **24.91 W** (hibernation) |

### 1.2 Ports — vendor rated speeds (📄)

| Port | Qty | Speed / spec | Notes |
|------|-----|--------------|-------|
| **RJ45 LAN** | **2** | **10 GbE** each | LACP aggregate → **20 Gb/s** theoretical (~2500 MB/s) |
| **Thunderbolt 4** | **2** | **40 Gb/s** (USB4/TBT4) | Front high-speed |
| **USB-A 3.2 Gen 1** | **2** | **10 Gb/s** (5 Gbps class per UGREEN panel diagram) | Rear |
| **USB-A 2.0** | **2** | **480 Mb/s** | Rear |
| **SD card** | **1** | **SD 4.0** | Front |
| **HDMI** | **1** | **8K @ 60 Hz** | Local display |
| **Wi-Fi** | — | None (no radio) | Ethernet only |

### 1.3 Our install — pools & bays (📦 measured 2026-07-01)

| Pool | Drives | RAID | Usable | Role |
|------|--------|------|--------|------|
| **Pool 1 (fast)** | **2× ~1.8 TB M.2 SSD** | **RAID 1** | **~1.8 TB** | Family model cache target, hot tier |
| **Pool 2 (bulk)** | **4× ~3.6 TB HDD** | **RAID 5** | **~10.8 TB** | Media, Historia, git objects, backups |
| **Empty** | **2× HDD bays** | — | — | Expansion ready |

**HDD model (✅ SME Amazon):** **Seagate IronWolf Pro ST4000NT001** · 4 TB · 4-pack (ASIN `B0F1QYWPJK`, ordered 2026-05-30) → Pool 2 RAID5.  
**M.2 model (⚠️ UGOS):** Pool 1 shows **2× ~1.8 TB** — no separate M.2 line item in SME Amazon export; confirm SKU in **UGOS → Storage Manager**.

### 1.4 Family mounts from DGX (📦)

| DGX path | ~Size | Protocol |
|----------|-------|----------|
| `/mnt/nas-docker` | ~1.9 TB | NFS/SMB |
| `/mnt/nas-media` | ~11 TB | NFS/SMB |
| `/mnt/nas/historia` | (vault) | NFS |
| `/mnt/nas-models` | symlink | cold model cache |

**Mac:** `/Volumes/historia` → sovereign Obsidian vault (SMB).

---

## 2. NVIDIA DGX Spark (`nephew-spark` / `192.168.10.205`)

**Vendor deep dive:** [`hardware/dgx-spark-official-spec.md`](../../hardware/dgx-spark-official-spec.md)  
**Product page:** https://www.nvidia.com/en-us/products/workstations/dgx-spark/  
**Datasheet:** https://nvdam.widen.net/s/tlzm8smqjx/workstation-datasheet-dgx-spark-gtc25-spring-nvidia-us-3716899-web  
**SKU:** `940-54242-0000`

### 2.0 Official NVIDIA specifications (vendor datasheet)

| Field | Spec |
|-------|------|
| **Architecture** | NVIDIA Grace Blackwell |
| **GPU** | Blackwell Architecture |
| **CPU** | **20-core Arm** — 10 **Cortex-X925** + 10 **Cortex-A725** |
| **Tensor / RT** | 5th-gen Tensor · 4th-gen RT |
| **Tensor performance**¹ | Up to **1 PFLOP FP4** |
| **System memory** | **128 GB LPDDR5x** unified · **256-bit** · **273 GB/s** |
| **Storage** | **4 TB NVMe M.2** (self-encryption) |
| **Ethernet** | **1× RJ-45 10 GbE** |
| **NIC (vendor)** | **ConnectX-7 @ 200 Gbps** |
| **USB** | **4× USB Type-C** |
| **Display** | **1× HDMI 2.1a** · up to **3× DP** over USB-C Alt Mode |
| **Wi-Fi / BT** | **Wi-Fi 7** · **BT 5.4** |
| **NVENC / NVDEC** | **1× / 1×** |
| **Power** | **240 W** PSU · **GB10 TDP 140 W**² |
| **Dimensions / weight** | **150 × 150 × 50.5 mm** · **1.2 kg** |
| **OS** | **NVIDIA DGX™ OS** |

¹ Theoretical FP4 with sparsity. ² GB10 superchip TDP (CPU + GPU).

### 2.1 Compute & memory (family unit — live)

| Field | Spec | Source |
|-------|------|--------|
| **Platform** | NVIDIA DGX Spark — Grace **Blackwell GB10** | 📄 vendor |
| **CPU** | **20 cores** Arm (vendor: X925 + A725) | ✅ live `nproc` |
| **GPU** | **GB10** Grace Blackwell unified | 📄 · PCI `10de:2e12` |
| **Unified memory** | Vendor **128 GB** · live **~122 GB** (**127,600,524 kB** MemTotal) | 📄 + ✅ live |
| **Memory bandwidth** | **273 GB/s** (vendor — bandwidth-bound inference) | 📄 |
| **Architecture** | **aarch64** · Ubuntu 24.04 LTS | ✅ live |

### 2.2 Internal storage (✅ live 2026-07-01)

| Device | Model | Capacity | Bus | Role |
|--------|-------|----------|-----|------|
| **nvme0n1** | **SAMSUNG MZALC4T0HBL1-00B07** | **4 TB** nominal (**3.7 TB** usable) | **NVMe** (Samsung `a810`) | OS + models + containers + hot indexes |
| **M.2 slot 2** | (empty) | — | **PCIe Gen5 ×4** | Hot-tier expansion |
| **M.2 slot 3** | (empty) | — | **PCIe Gen5 ×4** | Hot-tier expansion |

Vendor note: internal M.2 slots are **PCIe Gen5 ×4** — Gen4 NVMe here can exceed external TB enclosure throughput (~7 GB/s class).

### 2.3 Network interfaces (✅ live 2026-07-01)

| Interface | Chip | Nominal | **Negotiated now** | IP / role |
|-----------|------|---------|-------------------|-----------|
| **enP7s7** | Realtek **8127** | **10 GbE** | **10 Gb/s full duplex** ✅ | Point-to-point / NAS leg (see link matrix) |
| **enx6c6e072c96c6** | Realtek **8153** (USB NIC) | **1 GbE** | **1 Gb/s full duplex** ✅ | **Primary Trusted LAN** `.205` |
| **wlP9s9** | MediaTek **7925** | Wi-Fi 6/7 class | Down when wired | Backup wireless |
| **wg0** | WireGuard | — | Up | Mesh **10.1.0.5** |

**Reconcile vendor vs live:** Datasheet lists **ConnectX-7 @ 200 Gbps** — this unit's `lspci` shows **Realtek 8127 10 GbE** + **USB 1 GbE** dongle instead (operator path). USB-C is **USB 3.2 Gen 2×2 (20 Gb/s)** per live audit — **not Thunderbolt**.

### 2.4 Other ports & acoustics (📄 NVIDIA + operator)

| Port / metric | Vendor spec | Family install |
|---------------|-------------|----------------|
| **USB Type-C** | **4×** | USB 3.2 Gen 2×2 (20 Gb/s) — DP Alt Mode per datasheet |
| **HDMI** | **2.1a** | Headless — **Comet GL-RM10RC KVM** for physical console |
| **DisplayPort** | Up to **3×** over USB-C | — |
| **Noise (ECMA-109)** | Op **35 dB** L<sub>WA,m</sub> · Idle **19 dB** | — |

---

## 3. MacBook Pro M5 Max — **FIVEMAC** (primary operator)

| Field | Spec | Source |
|-------|------|--------|
| **Chip** | Apple **M5 Max** | 📦 |
| **CPU** | **18 cores** (6 perf + 12 efficiency) | 📄 Apple config |
| **GPU** | **40-core** GPU | 📄 |
| **Neural Engine** | **16-core** | 📄 |
| **Unified memory** | **128 GB** | 📦 |
| **Internal SSD** | **4 TB** | 📦 |
| **Display** | 16″ nano-texture | 📄 |
| **Thunderbolt** | **3× TB5** (up to **120 Gb/s** aggregate per Apple) | 📄 |
| **Other I/O** | MagSafe 3, HDMI, SDXC, 3.5 mm | 📄 |
| **Power** | 140 W USB-C adapter | 📄 |
| **Dock** | **HyperDrive Next TB5** #2 — 2.5 GbE + NVMe bay | 📦 |

**Edge role:** Pockit gateway, Cursor/Claude, M5 Holler voice, Obsidian vault host, MLX/Ollama GGUF inference.

---

## 4. MacBook Pro M1 — **ONEMAC-2**

| Field | Spec |
|-------|------|
| **Chip** | Apple **M1** |
| **Dock** | **HyperDrive Next TB5** #1 |
| **Dock Ethernet** | **2.5 GbE** |
| **Dock NVMe** | **Samsung 990 Pro** (M.2 in dock) — **⚠️ confirm** capacity (1/2/4 TB) |
| **990 Pro interface** | PCIe **4.0 ×4** — up to **~7450 / 6900 MB/s** seq read/write (vendor) |

---

## 5. Mac mini M4 Pro (when deployed)

| Field | Spec |
|-------|------|
| **CPU** | 14-core |
| **GPU** | 20-core |
| **ANE** | 16-core |
| **Memory** | **48 GB** unified |
| **SSD** | **4 TB** |
| **Ethernet** | **10 GbE** built-in + second **GbE** |
| **Thunderbolt** | **3× TB5** |

---

## 6. iMac 21.5″ Retina 4K (2017)

| Field | Spec |
|-------|------|
| **CPU** | Intel Core i5 **3.4 GHz** quad-core (Kaby Lake) |
| **GPU** | AMD Radeon Pro **560** · **4 GB** VRAM |
| **RAM** | **64 GB DDR4-2667** (unofficial upgrade) |
| **OS** | macOS **Ventura 13.7.8** |
| **Role** | x86 Docker, light Ollama CPU, warm-standby |

Detail: [`docs/hardware/imac-2017-intel-i5.md`](../hardware/imac-2017-intel-i5.md)

---

## 7. Network & security hardware

### 7.1 GL.iNet Flint 2 — **GL-MT6000** (`192.168.10.1`) — live router

| Field | Spec |
|-------|------|
| **SoC** | **MediaTek MT7986A** (quad-core **2.0 GHz**) | 📄 |
| **Wi-Fi** | **Wi-Fi 6** dual-band **AX6000** class | 📄 |
| **2.5 GbE ports** | **2×** (WAN + LAN flexible) | 📄 |
| **1 GbE ports** | **4×** | 📄 |
| **USB** | **1× USB 3.0** | 📄 |
| **OS** | **OpenWrt 24.10** | ✅ |
| **Role today** | Sole router, firewall, Wi-Fi, **WireGuard server** |

### 7.2 GL.iNet Brume 3 — **GL-MT5000** (×1 live, ×1 travel plan)

| Field | Spec |
|-------|------|
| **Ethernet** | **3× 2.5 GbE** (flexible WAN/LAN) | 📄 |
| **USB** | **1× USB 3.0** | 📄 |
| **Role today** | **Dumb 2.5G switch** on MT6000 LAN (routing off) |
| **Future** | Travel WireGuard client |

### 7.3 Verizon 5G Business Gateway

| Field | Spec |
|-------|------|
| **WAN** | 5G · **IP passthrough** to MT6000 (LAN2) | 📦 |
| **Note** | CGNAT — no inbound port-forward |

### 7.4 Protectli VP6670 — **arriving** (🔄)

| Field | Spec |
|-------|------|
| **CPU** | Intel **i7-1255U** |
| **RAM** | **32 GB+ DDR5** |
| **Storage** | **1 TB NVMe** |
| **Software target** | **OPNsense** — primary firewall / WG |

### 7.5 Comet **GL-RM10RC** (KVM only)

| Port | Spec |
|------|------|
| **Ethernet** | **1× GbE** |
| **USB-C** | **KVM** to DGX (keyboard/video/mouse/power) |
| **HDMI** | In/Out **4K @ 30 Hz** |
| **Display** | **3.69″** touchscreen |
| **Role** | **KVM only** — not a router |

### 7.6 Apple AirPort Extreme ×2

| Field | Spec |
|-------|------|
| **Ethernet** | **1 WAN + 3 LAN** — **1 GbE** each |
| **Wi-Fi** | **802.11ac** |
| **Role** | Coverage extension off Flint 2 **1G** ports |

### 7.7 GL.iNet AX1800 (Slate) — retiring interim

| Field | Spec |
|-------|------|
| **Ethernet** | **1× GbE WAN + 4× GbE LAN** |
| **Wi-Fi** | Wi-Fi 6 |
| **Role** | Was interim AI-gateway — **retiring** |

---

## 8. Desk docks & enclosures

### 8.1 HyperDrive Next TB5 Dock (×2)

| Port / feature | Speed |
|----------------|-------|
| **Thunderbolt 5** to host | Up to **120 Gb/s** (Apple/TB5 spec) |
| **Ethernet** | **2.5 GbE** |
| **USB 3.2** | **10 Gb/s** class ports |
| **M.2 NVMe slot** | PCIe NVMe (Samsung **990 Pro** in #1) |
| **Display** | Triple **4K** capable (vendor) |

### 8.2 Sonnet Echo 11 TB4 Dock (×2)

| Port | Speed |
|------|-------|
| **Thunderbolt 4** | **4×** ports · **40 Gb/s** each |
| **USB-A** | **3×** · **10 Gb/s** |
| **Ethernet** | **1 GbE** |
| **SD** | UHS-II reader |

### 8.3 Anker Prime 14-in-1

| Port | Speed |
|------|-------|
| **Ethernet** | **1 GbE** |
| **USB-C / USB** | Multi-port hub · **10 Gb/s** class |
| **Video** | Dual **4K** HDMI/DP |
| **UI** | Smart front status screen |

---

## 9. Cable & link speed matrix (every hop)

| # | From | To | Cable / medium | **Design speed** | **Live speed (2026-07-01)** | Status |
|---|------|-----|----------------|------------------|----------------------------|--------|
| 1 | Verizon modem | MT6000 WAN | Ethernet | **2.5 GbE** | ⚠️ confirm | ✅ |
| 2 | MT6000 LAN | Brume 3 (switch) | Ethernet | **2.5 GbE** | ⚠️ confirm | ✅ |
| 3 | MT6000 LAN/Wi-Fi | DGX `enx…96c6` | USB **1G** dongle | **1 GbE** | **1 Gb/s** ✅ | ✅ bottleneck for LAN NAS access |
| 4 | DGX `enP7s7` | NAS **10GbE** port | Cat6A/Cat7 **10GBase-T** | **10 GbE** | **10 Gb/s** ✅ | ✅ direct storage path |
| 5 | NAS 10GbE #2 | (spare / LACP) | — | **10 GbE** | — | 📦 |
| 6 | DGX USB-C | Comet KVM | USB4/TBT cable | **40 Gb/s** KVM | — | 📦 |
| 7 | M1/M5 | HyperDrive TB5 | TB5 cable | **120 Gb/s** | — | 📦 |
| 8 | HyperDrive | House LAN | Ethernet | **2.5 GbE** | — | 📦 |
| 9 | Flint 2 | AirPort Extreme ×2 | Ethernet | **1 GbE** | — | 📦 |
| 10 | WG mesh | VPS / Mac peers | UDP tunnel | Internet-limited | — | ✅ `10.1.0.0/24` |

**Storage traffic rule:** Heavy NFS/git bulk should prefer **link #4** (10 GbE). Treat **link #3** as management + internet only unless dongle is upgraded to 2.5G/10G USB.

---

## 10. Installed drives quick reference

| Host | Bay | Model | Size | Type | Pool / role | Provenance |
|------|-----|-------|------|------|-------------|------------|
| **DGX Spark** | NVMe0 | **SAMSUNG MZALC4T0HBL1-00B07** | 4 TB | NVMe | OS + hot data | ✅ DGX live probe |
| **DGX Spark** | M.2 #2–3 | (empty) | — | PCIe Gen5 | Expansion | — |
| **NAS** | M.2 ×2 | ⚠️ SKU TBD | ~1.8 TB each | SSD | Pool 1 RAID1 | UGOS only (not in SME) |
| **NAS** | SATA ×4 | **Seagate IronWolf Pro ST4000NT001** | 4 TB each | HDD | Pool 2 RAID5 | ✅ SME Amazon `B0F1QYWPJK` |
| **NAS** | SATA ×2 | (empty) | — | — | Ready | — |
| **HyperDrive #1** | M.2 | **Samsung 990 PRO MZ-V9P2T0B/AM** | **2 TB** | NVMe | Mac fast tier | ✅ SME Amazon ×3 orders |
| **HyperDrive TB5** | M.2 bay | (enclosure — assign 990 Pro) | 2 TB | NVMe | Dock #1 / #2 | ✅ SME `B0GR6SQYNS` dock |

---

## 11. VPS edge (`nephew-ct`)

| Field | Spec |
|-------|------|
| **Role** | Public HTTPS edge, Clinic, nginx → WG backends |
| **WG mesh** | **10.1.0.2** |
| **Note** | Not Family Office inference — edge + diagnostics only |

---

## 13. SME Family Inventory — purchase proof (Amazon / eBay)

**System:** Search My Engine (`search-my-engine`) · door **`http://search.localhost/`**  
**Surfaces:** `/orders` · `/catalog/[uuid]` · `/money` · agent tool `lookup_inventory`

| Merchant | Imported in SME | Use for hardware sheet |
|----------|-----------------|------------------------|
| **Amazon** | **863 line items** ✅ | ASIN, model, order date, price — backs §10 drive SKUs |
| **eBay** | **0 orders** (importer live; no CSV/ZIP dropped yet) | Drop eBay purchase-history export in SME upload zone |

### Key hardware purchases (SME `source=amazon`, synced 2026-07-01)

| Ordered | Item | ASIN | Model / SKU | Total USD |
|---------|------|------|-------------|-----------|
| 2026-06-02 | **UGREEN DXP6800 Pro** (diskless) | B0D22HN6PT | DXP6800 Pro 6-Bay | 1099.95 |
| 2026-05-30 | **Seagate IronWolf Pro 4TB ×4** | B0F1QYWPJK | ST4000NT001 | 954.39 |
| 2026-05-30 | **HyperDrive Next TB5 dock** | B0GR6SQYNS | — | 427.95 |
| 2026-05-30 | **Sonnet Echo 11 TB4 dock** | B08WYCY2FS | ECHO-DK11-T4 | 203.29 |
| 2026-05-24 | **NVIDIA DGX Spark** | B0FWJ16CCH | DGX Spark | 5006.53 |
| 2026-06-01 / 05-24 / 05-23 | **Samsung 990 PRO 2TB** (×3 orders) | B0BHJJ9Y77 | MZ-V9P2T0B/AM | 417–459 each |
| 2026-06-01 | **GL.iNet Comet KVM** | B0GLFF94RC | GL-RM10RC | 320.98 |
| 2026-06-01 | **GL.iNet Brume 3** | B0GGMTNG4S | GL-MT5000 | 128.38 |
| 2025-01-01 | **GL.iNet Flint 2** | B0CP7S3117 | GL-MT6000 | 167.99 |
| 2026-05-24 | **UGREEN Cat 8** 1.5 / 6 / 10 ft (×4 each) | B0D6B9LQRV / B0875VL1CJ / B0875SPZC8 | 40Gbps | 25–35 per pack |
| 2026-05-23 | **Anker Prime 14-in-1 dock** | B0CW9249DK | A83B6 | 288.88 |

Machine-readable mirror: [`data/hardware-spec-registry.json`](../../data/hardware-spec-registry.json) → `commerce_provenance` + per-device `purchases[]`.

**Refresh from SME (on DGX or Mac with SME Postgres):**

```bash
docker exec search-my-engine-db-1 psql -U claude -d claude_archive -c \
  "SELECT content::json->>'asin', content::json->>'model', left(content::json->>'name',60)
   FROM messages WHERE source='amazon' AND content::text ILIKE '%<keyword>%';"
```

---

## 12. Maintenance ritual

When hardware changes:

1. Update this chapter + [`data/hardware-spec-registry.json`](../../data/hardware-spec-registry.json).
2. **Reconcile purchases** from SME `/orders` or the query in §13 (Amazon/eBay importers).
3. Bump [`docs/CHANGELOG.md`](../CHANGELOG.md).
4. Mirror one-line truth into Nephew `data/hardware-inventory.json` (not the other way around).
5. Run live probes: DGX `ethtool`, `lsblk`, `nvme list`; NAS UGOS Storage Manager for M.2 SKUs SME lacks.

**Verify commands (DGX):**

```bash
ethtool enP7s7 enx6c6e072c96c6
lsblk -o NAME,SIZE,MODEL,ROTA,TRAN
nvme list
ip -br link
```

---

## Related

- [01-hardware.md](./01-hardware.md) — roster + workload routing
- [13-physical-topology-protectli.md](./13-physical-topology-protectli.md) — cabling ASCII
- [31-m5-max-dgx-inference-setup.md](./31-m5-max-dgx-inference-setup.md) — inference floor
- [`hardware/ugreen-dxp6800-pro-spec.md`](../../hardware/ugreen-dxp6800-pro-spec.md) — NAS-only deep dive
- [`hardware/dgx-spark-official-spec.md`](../../hardware/dgx-spark-official-spec.md) — DGX Spark NVIDIA vendor table + live reconcile
- Nephew `docs/hardware-dgx-ground-truth.md` — agent coordination index
- **SME** `http://search.localhost/orders` — Family Inventory purchase proof (§13)