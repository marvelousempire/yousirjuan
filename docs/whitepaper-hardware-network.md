# Whitepaper — Awe Engine Stack: Hardware & Network Reference

**Status:** living document · **Last verified:** 2026-06-05 · **Author:** Nephew (operator-confirmed)
**Provenance legend:** ✅ *verified* = read live from the device this session · 📄 *spec-sheet* = manufacturer datasheet value (device not directly probeable over the network) · ⚠️ *inferred* = best-estimate, confirm · 🔄 *transitional* = correct intent, interim hardware still in place.

This document describes the physical hardware, every cabled link, the address plan, and the security model of the family network. It is the canonical reference; a portable copy lives in `yousirjuan/docs/`.

**Strategic architecture** (VLAN rollout, Matrix + Element, AI AppService bot, Protectli future state): [`home-network-full-architecture-report.md`](home-network-full-architecture-report.md) — operator briefing indexed 2026-06-09. ⚠️ That report describes **MT6000 as the live router**; sections of this whitepaper still describe the **Brume-split gateway** model from 2026-06-05 — reconcile before executing either doc blindly.

---

## 1. Executive summary

The stack is a **trust-segmented home datacenter** on Verizon 5G. **Brume 3 #1** (MT5000) is the main gateway: **2.5G WAN** from Verizon, **LAN 1 (2.5G)** to **Flint 2** for the house, **LAN 2 (2.5G)** to **Brume 3 #2** for the isolated AI island (cutover today). Until Brume 3 #2 is cabled, the AI leg runs **interim via Flint 2 → AX1800 (1G) → Comet → DGX Spark**, with **WireGuard on the AI gateway**. The AI island includes **Comet GL-RM10RC** (KVM only), **DGX Spark**, and **UGREEN DXP6800 Pro** on a direct **10 GbE** link. Desk storage uses **HyperDrive TB5**, **Sonnet Echo 11 TB4**, and **Anker Prime 14-in-1** docks. **No Tailscale** — WireGuard + obfuscation on Brume 3 #2 only.

---

## 2. Current network setup (as of June 5, 2026)

Operator-confirmed canonical topology. Copy this block when briefing another AI.

### Gateway roles

| Gateway | Role | Purpose |
|---------|------|---------|
| **Brume 3 #1** (MT5000) | **Main gateway** | Internet ingress from Verizon; splits uplink to house vs AI island; house-side protection |
| **Brume 3 #2** (MT5000) | **AI gateway** (target) | Dedicated isolated AI security boundary; WireGuard + obfuscation; only path to Comet + DGX Spark |
| **Flint 2** (AX6000) | **House router** | Wi-Fi + switching for household devices only — not the AI security boundary |
| **AX1800** (interim) | **AI gateway placeholder** | 1 GbE WireGuard until Brume 3 #2 cutover today — **being replaced** |

### Internet flow

- **Verizon modem** → **Brume 3 #1** via its **2.5G WAN port**
- **Brume 3 #1** splits using two **2.5G LAN ports** (see port map below)

### Brume 3 #1 port map (MT5000 — 3× flexible 2.5G)

| Port | Assignment | Speed | Connected to |
|------|------------|-------|--------------|
| **WAN** | Verizon uplink | 2.5 GbE | Verizon 5G modem |
| **LAN 1** | House leg | 2.5 GbE | **Flint 2 (AX6000) WAN port** |
| **LAN 2** | AI leg (target) | 2.5 GbE | **Brume 3 #2 WAN port** 🔄 *live after cutover* |

### Brume 3 #2 port map (target — Router mode ⚠️ confirm at install)

| Port | Assignment | Speed | Connected to |
|------|------------|-------|--------------|
| **WAN** | From Brume 3 #1 LAN 2 | 2.5 GbE | Brume 3 #1 |
| **LAN** | AI island | 2.5 GbE | Comet 5G Ethernet → downstream DGX + NAS |

Expected mode: **Router mode** (separate AI subnet from house). ⚠️ Confirm at Brume 3 #2 install.

### House network (off Flint 2)

- **Flint 2** receives internet from **Brume 3 #1 LAN 1** (2.5G WAN port on Flint 2)
- Flint 2 ports: **2× 2.5 GbE + 4× 1 GbE** + Wi-Fi 6
- Two **AirPort Extreme 802.11ac** routers on Flint 2 **1G ports** (extend Ethernet + Wi-Fi)
- All regular household devices, laptops, and phones

### Isolated AI network

**Target (Brume 3 #2 live — cutover today):**

- Brume 3 #1 **LAN 2** (2.5G) → **Brume 3 #2 WAN** (2.5G)
- Brume 3 #2 **LAN** → **Comet 5G (GL-RM10RC) Ethernet** (1G on Comet; 2.5G link speed on Brume side)
- Comet **USB-C KVM port** → **DGX Spark Thunderbolt / USB4**
- DGX Spark **10GbE** → **UGREEN DXP6800 Pro NAS 10GbE port #1** (direct)
- **WireGuard + obfuscation** on Brume 3 #2 — sole remote-access path to Comet + DGX Spark

**Current interim (until Brume 3 #2 is cabled):**

- 🔄 **Flint 2 LAN (1G)** → **AX1800 WAN** (1G) — temporary AI leg feed
- AX1800 **LAN (1G)** → **Comet Ethernet** (1G)
- Same Comet → DGX → NAS downstream chain
- **WireGuard** on AX1800 controls Comet + DGX access today

> **Note:** Interim path routes AI traffic through Flint 2 temporarily. Target path is **direct Brume 3 #1 LAN 2 → Brume 3 #2** so the AI island never touches the house router.

### Desk / workstation storage (house network)

| Dock | Connected to | Notes |
|------|--------------|-------|
| **HyperDrive Next TB5** #1 | M1 MacBook | 2.5G Ethernet + Samsung 990 Pro NVMe in dock |
| **HyperDrive Next TB5** #2 | M5 Max MacBook Pro (Thursday) | Ready to connect |
| **Sonnet Echo 11 TB4** ×2 | Workstations | 1G Ethernet · 4× TB4 · SD reader |
| **Anker Prime 14-in-1** | Workstation hub | 1G Ethernet · dual 4K HDMI/DP · smart front screen |

### Key notes

- **DGX Spark** is fully isolated behind the AI gateway (AX1800 interim → **Brume 3 #2** permanent)
- **Comet** = KVM only (keyboard, mouse, screen, power) — accessed remotely via **WireGuard on the AI gateway**
- **NAS** = direct **10 GbE** to DGX Spark (models, datasets, backups)
- **No Tailscale** anywhere — private WireGuard on AI gateway only
- **Mullvad on Brume 3 #1:** ⚠️ not yet decided — see open items

---

## 3. Hardware — full port overview

| Device | Ethernet Ports | Thunderbolt / USB-C Ports | USB Ports | Other Ports & Features |
|--------|----------------|---------------------------|-----------|------------------------|
| **NVIDIA DGX Spark** | 1× 10 GbE | 4× USB4 / Thunderbolt (40 Gbps) | Included in USB4 | 1× HDMI 2.1a, 2× QSFP (200 Gbps) |
| **UGREEN DXP6800 Pro NAS** | 2× 10 GbE | 2× Thunderbolt 4 (40 Gbps) | 3× USB-A 3.2 (10 Gbps), 2× USB 2.0 | 8K HDMI, 2× M.2 NVMe, SD card reader |
| **Brume 3 (MT5000)** ×2 | 3× 2.5 GbE (flexible WAN/LAN) | None | 1× USB 3.0 | — |
| **Flint 2 (AX6000)** | 2× 2.5 GbE + 4× 1 GbE | None | 1× USB 3.0 | Wi-Fi 6 |
| **Comet 5G (GL-RM10RC)** | 1× 1 GbE | 1× USB-C (KVM) | 1× USB 2.0 | HDMI In/Out (4K@30), 3.69″ touchscreen |
| **HyperDrive Next TB5 Dock** (×2) | 1× 2.5 GbE | Multiple Thunderbolt 5 (up to 120 Gbps) | Multiple USB 3.2 (10 Gbps) | M.2 NVMe slot (Samsung 990 Pro), triple 4K |
| **Sonnet Echo 11 TB4 Dock** (×2) | 1× 1 GbE | 4× Thunderbolt 4 | 3× USB-A (10 Gbps) | SD card reader |
| **Anker Prime 14-in-1** | 1× 1 GbE | Multiple USB-C | Multiple 10 Gbps USB | Dual 4K HDMI/DP, smart front screen |
| **AirPort Extreme 802.11ac** (×2) | 4× 1 GbE (1 WAN + 3 LAN) | None | None | Wi-Fi AC |
| **GL.iNet AX1800** (interim) 🔄 | 1× GbE WAN + 4× GbE LAN | None | 1× USB 2.0 | Wi-Fi 6 · WireGuard · **retiring today** |

### WireGuard throughput (expected)

| Gateway | Link speed to Comet/DGX path | WireGuard notes |
|---------|------------------------------|-----------------|
| AX1800 (interim) | 1 GbE max | WireGuard active today |
| **Brume 3 #2** (target) | 2.5 GbE to Comet; 10 GbE DGX↔NAS bypasses WG | Obfuscation enabled; Comet access via WG only |

---

## 4. Hardware roster (one line each)

| # | Device | Role | Key spec | Notes |
|---|--------|------|----------|-------|
| 1 | Verizon 5G Internet Gateway | WAN uplink | 5G mmWave/C-band, CGNAT 📄 | Carrier → public IP; no inbound port-forward |
| 2 | **Brume 3 #1** | **Main gateway** | 2.5G WAN + 2× 2.5G LAN 📄 | Splits house vs AI island |
| 3 | **Brume 3 #2** | **AI gateway** (target) | 2.5G WAN + LAN, WireGuard + obfuscation 📄 | Replaces AX1800 on AI leg 🔄 |
| 4 | GL.iNet Flint 2 (AX6000) | **House router** | 2× 2.5G + 4× 1G + Wi-Fi 6 📄 | Off Brume 3 #1 LAN 1 |
| 5 | GL.iNet AX1800 (Slate AX) | **AI gateway (interim)** | 1 GbE WAN/LAN, WireGuard 📄 | Retiring today 🔄 |
| 6 | Apple AirPort Extreme A1521 ×2 | House AP / switch extension | 4× 1 GbE each (1 WAN + 3 LAN) 📄 | Off Flint 2 1G ports |
| 7 | **Comet 5G (GL-RM10RC)** | **KVM appliance** | 1G Eth + USB-C KVM + touchscreen 📄 | Remote console to DGX only |
| 8 | **DGX Spark "Awe Engine"** | AI + control plane | GB10, 128 GB unified, 10GbE + TB 📄 | Isolated AI subnet |
| 9 | **UGREEN DXP6800 Pro** | NAS | 10GbE + additional ports 📄 | Port #1 ↔ DGX Spark 10GbE direct |
| 10 | HyperDrive Next TB5 Dock ×2 | TB5 bridge + 2.5G Eth + NVMe | TB5 up to 120 Gbps 📄 | M1 live; M5 Max Thursday |
| 11 | Sonnet Echo 11 TB4 Dock ×2 | TB4 hub + 1G Eth | 4× TB4 📄 | SD reader · workstations |
| 12 | Anker Prime 14-in-1 | USB-C hub + 1G Eth | Multi USB-C 📄 | Dual 4K · smart front screen |
| 13 | MacBook Pro M1 "ONEMAC-2" | Operator workstation | M1, macOS ✅ | House network + HyperDrive dock |
| 14 | MacBook Pro M5 Max | Creative workstation | 128 GB / 4 TB 📄 | Arriving Thursday |
| 15 | clinic-vps (GoDaddy) | Off-site edge | `72.167.151.251` | Public Control Tower + GitLab |

---

## 5. Physical pipeline (cabling, top → bottom)

```
Verizon 5G Internet Gateway                         (CGNAT — no inbound)
      │ 2.5G
      ▼
Brume 3 #1  ── MAIN GATEWAY ──  splits two 2.5G LAN legs
      │
      ├── 2.5G LAN ──► Flint 2 (AX6000) WAN          HOUSE NETWORK
      │                      ├── 1G ── AirPort Extreme #1 ──┐
      │                      ├── 1G ── AirPort Extreme #2   │ laptops · phones · IoT
      │                      └── 1G ── household devices ◄──┘
      │
      └── 2.5G LAN 2 ──► Brume 3 #2 WAN (target)     ISOLATED AI NETWORK
                 🔄 interim today: Flint 2 1G ──► AX1800 WAN ──► Comet
                              │
                              ├── Comet GL-RM10RC Eth (1G)
                              │       └── USB-C KVM ──► DGX Spark (console)
                              │
                              └── DGX Spark 10GbE ◄────► UGREEN DXP6800 Pro (port #1)

House desk: HyperDrive TB5 (×2) · Sonnet Echo 11 TB4 (×2) · Anker Prime 14-in-1
```

**Segmentation:** house LAN and AI island are **separate L3 networks**. Target join point is **Brume 3 #1 only** (not Flint 2). DGX Spark is **not** on the household LAN.

---

## 6. Logical network & address plan

| Plane | Subnet / value | Notes |
|-------|----------------|-------|
| Carrier WAN | Verizon CGNAT | No inbound port-forward from the internet |
| House LAN | `192.168.8.0/24` (gw `.1` = Flint 2) ✅(historical) ⚠️ confirm | Family devices, Macs, AirPorts, desk docks |
| AI island LAN | ⚠️ **TBD** — document after Brume 3 #2 install | DGX Spark, Comet, NAS — isolated from house |
| WireGuard (AI gateway) | AX1800 interim → Brume 3 #2 🔄 | Obfuscation on Brume 3 #2; Comet access via WG only |
| DGX ↔ NAS | Layer-2 10 GbE direct | 10 Gbps — bypasses WireGuard (local link) |
| Mullvad (Brume 3 #1) | ⚠️ **TBD** — operator decision pending | See open items |
| Tailscale | **Not used** | Retired from this topology |

---

## 7. Per-device deep specs (still-valid probes)

### 7.1 DGX Spark "Awe Engine" — partial ✅ (pre-isolation probes)

- **SoC:** NVIDIA **GB10** Grace-Blackwell. **Memory:** **121 GiB** unified (128 GB nominal).
- **Storage:** Samsung NVMe **~3.7 TB** usable.
- **OS:** Ubuntu **24.04 LTS**, aarch64.
- **NICs / ports (topology today):**
  - **10GbE** → UGREEN DXP6800 Pro port #1 (direct)
  - **Thunderbolt** ← Comet KVM (console only)
  - **Ethernet** ← AI gateway LAN via Comet chain (interim 1 GbE)
- **Runs:** Ollama, Nephew Control Tower, DustPan agent, Docker stacks (search-my-engine, family-edge).

### 7.2 MacBook Pro M1 "ONEMAC-2" — ✅ probed (house network)

- **Chip:** Apple **M1**. Connected via **HyperDrive TB5 dock** (Samsung 990 Pro NVMe in dock).
- **Network:** House Wi-Fi / Flint 2 LAN. DustPan agent locally.

### 7.3 UGREEN DXP6800 Pro NAS — 📄 spec-sheet

- **Ports:** **10GbE port #1** ↔ DGX Spark direct; additional ports per SKU 📄
- **Role:** Shared storage for models, datasets, backups on the AI island

### 7.4 Comet 5G (GL-RM10RC) — 📄 spec-sheet

- **Role:** KVM-only appliance — keyboard, mouse, display, power for DGX Spark over USB-C/Thunderbolt
- **Network:** 1 GbE to AI gateway (2.5 GbE when Brume 3 #2 live)

---

## 8. Software / services map & security

- **Nephew Control Tower** — DGX `:5174` (single pane on the Spark).
- **DustPan agents** — MacBook + DGX disk cockpit agents.
- **Ollama** — DGX local inference. 🔴 Bind to AI-island addresses only; never expose on house LAN.
- **WireGuard** — AI gateway only (AX1800 interim → Brume 3 #2 with obfuscation). Controls Comet + DGX access.
- **Tailscale** — **not deployed** in this topology.

---

## 9. Current status (2026-06-05)

| Up ✅ | In progress 🔄 / ⚠️ |
|------|---------------------|
| Brume 3 #1 main gateway live (2.5G split) | Brume 3 #2 arriving — replaces AX1800 on AI leg |
| House network on Flint 2 + AirPort Extremes | WireGuard obfuscation flips to Brume 3 #2 at cutover |
| DGX ↔ NAS direct 10GbE | Confirm AI-island subnet + DHCP after Brume 3 #2 install |
| Comet KVM path to DGX Spark | Interim: Flint 2 → AX1800 → Comet at 1G |
| HyperDrive dock on M1 MacBook | Sonnet Echo ×2 + Anker Prime on desk |
| — | Brume 3 #2 Router mode + AI subnet CIDR — confirm at install |
| — | Mullvad on Brume 3 #1 — operator decision pending |

---

## 10. Open items / confirmations

1. **Brume 3 #2 cutover** — cable Brume 3 #1 LAN 2 → Brume 3 #2 WAN; retire AX1800 + interim Flint 2 feed; migrate WireGuard + obfuscation.
2. **Brume 3 #2 mode** — confirm Router mode and document AI-island subnet (CIDR + gateway IP).
3. **House vs AI IP ranges** — pin final CIDRs for both networks in this doc once configured.
4. **Mullvad on Brume 3 #1** — decide yes/no for house-leg VPN egress.
5. **MacBook Pro M5 Max** — second HyperDrive TB5 dock + house-network onboarding (Thursday).
6. **Retire stale docs** — seed-to-tree runbooks describing DGX on Flint 2 LAN are superseded by this file.

*Topology source: operator-confirmed summary 2026-06-05. Prior probe data (DGX/Mac specs) retained where still accurate.*
