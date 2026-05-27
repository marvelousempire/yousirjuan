# Legacy iMac Max-Out Hardware Inventory

**Project:** Private Local AI Coding Assistant (Ollama + Continue.dev)  
**Goal:** Fully maximize both 27-inch Intel iMacs for the best possible Cursor-like experience that is 100% private and offline after setup.  
**Date:** May 27, 2026  
**Owner:** A Brown Santa / marvelousempire  
**Status:** **Living Document** — Single source of truth is now `hardware/imac-hardware-data.json`. The interactive React table and this Markdown stay in sync from that file.

> **How to update:** Edit `hardware/imac-hardware-data.json` → both the React component (`apps/yousirjuan-web/components/HardwareTable.tsx`) and future generated docs will reflect the change.

---

## Interactive Living Table (Recommended)

Visit the demo page in the web app: `/hardware-demo` (or embed `<HardwareTable />` anywhere).

The table supports:
- Real-time search across all fields
- Filter by machine (2012 / 2017 / Both)
- Filter by category (Processor, Memory, Storage, etc.)
- Clickable column headers for sorting
- Color-coded status badges

---

## Machine 1: Late 2012 27-inch iMac

**Current OS:** macOS Catalina (upgradable to Sonoma/Sequoia via OpenCore Legacy Patcher)  
**Key Limitation:** No native NVMe support. Max RAM is 32GB. Old NVIDIA GPU provides no meaningful AI acceleration.

| Category       | Specification                  | Max / Recommended                  | Upgrade Path                          | Recommended Part                              | Approx. Price (Florida) | Status      | Notes |
|----------------|--------------------------------|------------------------------------|---------------------------------------|-----------------------------------------------|-------------------------|-------------|-------|
| Processor      | 3.4 GHz Quad-Core Intel i7     | None (soldered)                    | None                                  | —                                             | —                       | Maxed       | 4 cores, no efficiency cores |
| Graphics       | NVIDIA GeForce GTX 675MX 1GB   | None                               | None                                  | —                                             | —                       | Maxed       | No CUDA / Metal AI accel |
| Memory         | 8GB DDR3 1333/1600 MHz         | 32GB (4×8GB)                       | Replace all 4 sticks with matched kit | A-Tech 4×8GB DDR3 1600MHz PC3-12800           | $99 – $130              | Needs Upgrade | Must use identical modules |
| Storage        | Original HDD (SATA)            | Fastest SATA SSD                   | Replace internal 3.5" drive           | Samsung 870 EVO 1TB or 2TB SATA SSD           | $130 – $220             | Needs Upgrade | SATA only — no NVMe |
| OS             | Catalina (official)            | Sonoma or Sequoia                  | OpenCore Legacy Patcher               | —                                             | Free                    | Needs Upgrade | Required for modern Ollama |
| AI Capability  | Very limited                   | 1.5B – 3B models only              | —                                     | qwen2.5-coder:1.5b or :3b                     | Free                    | Limited     | Use tiny models only |

**After Max-Out:** 32GB matched RAM + SATA SSD + Sonoma via OCLP → Usable for basic autocomplete and simple coding help.

---

## Machine 2: Mid 2017 27-inch iMac

**Current OS:** macOS Ventura  
**Key Advantage:** Supports NVMe via adapter. Already at official RAM max. Radeon Pro 560 is better but still no modern AI GPU accel.

| Category       | Specification                     | Max / Recommended                     | Upgrade Path                          | Recommended Part                                      | Approx. Price (Florida)      | Status          | Notes |
|----------------|-----------------------------------|---------------------------------------|---------------------------------------|-------------------------------------------------------|------------------------------|-----------------|-------|
| Processor      | Quad-Core Intel (i5/i7 gen)       | None (soldered)                       | None                                  | —                                                     | —                            | Maxed           | Better than 2012 but still 4-core |
| Graphics       | AMD Radeon Pro 560 4GB            | None                                  | None                                  | —                                                     | —                            | Maxed           | No modern AI acceleration |
| Memory         | 64GB DDR4 (currently installed)   | 64GB (official max)                   | Verify matched 2400MHz sticks         | A-Tech / OWC 4×16GB DDR4 2400MHz (if replacing)       | $200 – $260 (if needed)      | Verify Seating  | Mismatched or loose sticks cause sluggishness |
| Storage        | Original SATA                     | NVMe SSD via adapter                  | Add Sintech NVMe adapter + NVMe drive | Sintech NVMe Adapter + Samsung 970 EVO Plus 1TB/2TB   | Adapter $15–25<br>SSD $110–$250 | Needs Upgrade   | Big performance win over SATA |
| OS             | Ventura                           | Ventura or higher (optional)          | Optional OpenCore Legacy Patcher      | —                                                     | Free                         | Good            | Native support is solid |
| AI Capability  | Good for local use                | 7B models comfortable                 | —                                     | qwen2.5-coder:7b                                      | Free                         | Recommended     | Best daily driver of the two |

**After Max-Out:** 64GB matched RAM + NVMe SSD → Comfortably runs 7B coding models with good responsiveness.

---

## Shared / External Recommendations

| Item                    | Purpose                              | Recommendation                              | Approx. Price | Notes |
|-------------------------|--------------------------------------|---------------------------------------------|---------------|-------|
| External Fast Storage   | Model storage, projects, backups     | Samsung T7, Crucial X9 Pro, or SanDisk Pro-G40 (Thunderbolt/USB-C) | $100 – $250   | Great for keeping large models off internal drive |
| External RAM            | —                                    | Not possible / not recommended              | N/A           | USB/Thunderbolt latency makes it useless for AI |
| Power / Thermals        | Stability during long generations    | Ensure good ventilation, clean dust         | —             | Old iMacs can thermal throttle |

---

## Summary of Maximum Potential

| Machine       | RAM     | Storage     | Best Model     | Realistic Experience                          | Recommended Daily Use          |
|---------------|---------|-------------|----------------|-----------------------------------------------|--------------------------------|
| 2012 iMac     | 32GB    | SATA SSD    | 1.5B – 3B      | Basic autocomplete + simple help              | Secondary / light tasks        |
| 2017 iMac     | 64GB    | NVMe SSD    | 7B             | Useful coding partner (closest to Cursor)     | Primary daily driver           |

**Total Estimated Upgrade Cost (both machines):** $350 – $650 depending on SSD sizes chosen and whether new RAM kit is purchased for the 2017 iMac.

**Next Steps (see full PRD and agent team in this repo):**
1. Purchase matched RAM + SSDs
2. Install hardware
3. Run OpenCore Legacy Patcher on 2012 iMac
4. Apply Ollama performance plist + Continue.dev configs
5. Use the interactive React table (`/hardware-demo`) to track status

---

**Living Document Note**  
`hardware/imac-hardware-data.json` is now the single source of truth. The React component and this Markdown are derived views. Future agents should update the JSON when hardware status or recommendations change.

Last updated: 2026-05-27