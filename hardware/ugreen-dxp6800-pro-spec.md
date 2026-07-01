# UGREEN NASync DXP6800 Pro — family NAS spec (installed + vendor)

**Hostname:** `nasa.local` · **LAN:** `192.168.10.119` · **OS:** UGOS Pro  
**Vendor page:** https://nas.ugreen.com/products/ugreen-nasync-dxp6800-pro-nas-storage  
**Handbook chapter:** [`docs/setup/32-hardware-full-spec-sheet.md`](../docs/setup/32-hardware-full-spec-sheet.md) §1

> **Not Synology.** This is UGREEN NASync hardware running **UGOS Pro**.

---

## Chassis (vendor datasheet)

| Item | Value |
|------|-------|
| Model | **DXP6800 Pro** (SKU 25898) |
| CPU | Intel **Core i5-1235U** — 10C/12T, 12th Gen |
| RAM | **8 GB DDR5-4800** stock · **64 GB** max |
| OS flash | **128 GB** SSD |
| SATA | **6 bays** |
| M.2 NVMe | **2 slots** |
| PCIe | **1× ×4** expansion |
| LAN | **2× 10GbE** (LACP → 20 Gb/s aggregate) |
| Thunderbolt 4 | **2×** @ 40 Gb/s |
| USB | 2× USB-A 3.2 + 2× USB 2.0 |
| SD | SD 4.0 reader |
| HDMI | 8K @ 60 Hz |
| Max vendor capacity | 208 TB (6×32T + 2×8T M.2) |
| Idle / active power | 24.91 W / 43.07 W |

---

## Our install (2026-07-01)

| Pool | Layout | Usable | Purpose |
|------|--------|--------|---------|
| **Pool 1** | 2× ~1.8 TB M.2 · **RAID 1** | ~1.8 TB | Fast tier — **family model cache** target |
| **Pool 2** | 4× ~3.6 TB HDD · **RAID 5** | ~10.8 TB | Bulk — media, Historia, git objects |
| **Free** | 2× empty SATA bays | — | Expansion |

**DGX mounts:** `/mnt/nas-docker` (~1.9 TB) · `/mnt/nas-media` (~11 TB) · `/mnt/nas/historia` · `/mnt/nas-models`

**Mac mount:** `/Volumes/historia`

---

## Link to DGX Spark

| Path | Speed | Interface |
|------|-------|-----------|
| **Direct 10GbE** (preferred) | **10 Gb/s** ✅ live on `enP7s7` | DGX Realtek 8127 ↔ NAS 10GbE #1 |
| **Via LAN dongle** | **1 Gb/s** | DGX USB Realtek 8153 → MT6000 → NAS |

---

## Open items

- [ ] Record exact HDD + M.2 **model numbers** from UGOS Storage Manager → `data/hardware-spec-registry.json`
- [ ] Document 10GbE **port #1 vs #2** assignment + LACP if enabled
- [ ] Cable type/length for DGX↔NAS 10GBase-T run