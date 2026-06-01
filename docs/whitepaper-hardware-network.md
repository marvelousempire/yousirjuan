# Family Office — Hardware & Network Whitepaper

**Status:** Living document · **Last verified:** 2026-06-01 (Eastern)
**Scope:** Every machine, every link, every port, plus the WireGuard "customs &
border control" segmentation between the outer (edge) and inner (AI Engine) networks.
**Legend:** ✅ **VERIFIED** = read live from the device this session · 📄 **SPEC** =
manufacturer spec sheet, confirm exact SKU.

---

## 1. Executive summary

The Family Office network is built as **two trust-separated "countries"** chained by
ethernet but joined only through a controlled **WireGuard border**:

- **Outer country** — the **AX1800** edge router, the *only* device on the Verizon 5G
  modem. The "international zone."
- **Inner country** — the **AX6000** internal router and everything behind it: the
  **DGX Spark "AI Engine,"** two Airport Extremes, the UGreen NAS, the iMac, and the
  MacBook. The trusted zone.

The two never share a broadcast domain. The only sanctioned crossing is a **site-to-site
WireGuard tunnel** with a **firewall checkpoint ("customs")** on each end. This document
is the authoritative map of the hardware and how it all connects.

---

## 2. Hardware roster (full specs)

### 2.1 NVIDIA DGX Spark — "AI Engine" (inner country)
| Attribute | Value | Src |
|---|---|---|
| Role | LLM inference + Control Tower host; the protected inner asset | — |
| SoC | **NVIDIA GB10** (Grace-Blackwell) | ✅ |
| CPU | **20 cores ARM** — 10× Cortex-X925 (perf) + 10× Cortex-A725 (eff), max 3.9 GHz | ✅ |
| GPU | NVIDIA GB10 (Blackwell), driver **580.159.03** | ✅ |
| Memory | **128 GB unified** (121 GiB visible) | ✅ |
| Storage | **3.7 TB NVMe** — Samsung MZALC4T0HBL1-00B07 (`nvme0n1`), `/` 11% used | ✅ |
| OS | **Ubuntu 24.04.4 LTS**, kernel `6.17.0-1018-nvidia`, aarch64 | ✅ |
| NIC 1 | `enP7s7` — RJ45, **negotiated 1 GbE** full-duplex (MAC `4c:bb:47:2b:b1:07`) | ✅ |
| NIC 2 | `wlP9s9` — Wi-Fi (MAC `58:02:05:f5:d4:0e`) | ✅ |
| Onboard (uncabled) | GB10 platform also ships a 10 GbE RJ45 + ConnectX-7 (QSFP) — not cabled today | 📄 |
| Services | Ollama `:11434` (9 models incl. `llama3.3:70b`, `nephew:70b`, `qwen2.5-coder:32b`); DustPan agent `:8765` v0.67.0; Nephew Control Tower `:5174` | ✅ |
| Addressing | `enP7s7` 192.168.8.249 · Wi-Fi 192.168.8.114 · `wg0` 10.1.0.5 | ✅ |

### 2.2 MacBook Pro — operator workstation (inner country)
| Attribute | Value | Src |
|---|---|---|
| Model | **MacBook Pro (MacBookPro17,1)** — M1, 2020 | ✅ |
| Chip | **Apple M1**, 8 cores (4 performance + 4 efficiency) | ✅ |
| Memory | **8 GB** unified | ✅ |
| Storage | 245 GB internal — **20 GB free** (tight) | ✅ |
| OS | **macOS 26.3.1** (build 25D771280a) | ✅ |
| Thunderbolt | TB3/USB4 host @ **40 Gb/s** → HyperDrive TB5 dock | ✅ |
| Active LAN | `en4` USB **1 GbE** adapter → 192.168.8.205 (current default route) | ✅ |
| Other ports | `en15` USB **2.5 GbE** (idle), `en0` Wi-Fi, 2× TB-bridge ethernet adapters | ✅ |
| WireGuard | `utun8`/`wg0` = 10.1.0.4 (inner mesh) | ✅ |
| Services | DustPan agent `:8765` v0.69.0 | ✅ |

### 2.3 AX1800 — EDGE / front gate (outer country)
| Attribute | Value | Src |
|---|---|---|
| Role | **Edge router** — the only device on the 5G modem; outer WG border post | ✅ (position) |
| Model | ASUS **AX1800-class** (RT-AX1800S / RT-AX55) — confirm SKU | 📄 |
| WAN | 1× **1 GbE** RJ45 → Verizon 5G modem | 📄 |
| LAN | 4× **1 GbE** RJ45 | 📄 |
| Wi-Fi | Wi-Fi 6 dual-band — 574 Mbps (2.4 GHz) + 1201 Mbps (5 GHz) | 📄 |
| VPN | **WireGuard server supported** (confirmed in admin UI) | ✅ |
| LAN IP | **192.168.0.1** | ✅ |

### 2.4 AX6000 — INTERNAL router (inner country)
| Attribute | Value | Src |
|---|---|---|
| Role | **Internal router** behind the AX1800; inner WG border post + existing mesh | ✅ (position) |
| Model | ASUS **AX6000-class** (likely GT-AX6000 / ROG Rapture) — confirm SKU | 📄 |
| WAN | 1× **2.5 GbE** RJ45 ← uplink to AX1800 | 📄 |
| LAN | 1× **2.5 GbE** + 4× **1 GbE** RJ45 | 📄 |
| USB | 2× USB 3.2 Gen 1 | 📄 |
| Wi-Fi | Wi-Fi 6 dual-band AX6000 — 1148 + 4804 Mbps | 📄 |
| VPN | **WireGuard server** live: `10.1.0.0/24` on `:51821` (hub 10.1.0.1) | ✅ |
| LAN IP | **192.168.8.1** (ASUS MAC `94:83:c4:a5:89:9f`) | ✅ |
| Firmware ❓ | Admin console answers as **`console.gl-inet.com`** (despite the ASUS MAC OUI) → likely **GL.iNet / OpenWrt** — *good for the border plan*: real per-flow `iptables`/`nftables` customs. Confirm SKU. | ✅ probed |

### 2.5 Airport Extreme ×2 (inner country)
| Attribute | Value | Src |
|---|---|---|
| Role | Wi-Fi/wired extension of the inner LAN; **two units wired together, one feeds the UGreen NAS** | ✅ (per operator) |
| Model | Apple AirPort Extreme (A1521, 802.11ac) | 📄 |
| Ports each | 3× **1 GbE** LAN + 1× **1 GbE** WAN + 1× USB 2.0 | 📄 |
| Clients | iMac 21.5″ attaches here | ✅ (per operator) |

### 2.6 UGreen DXP4800 Pro — NAS (inner country)
| Attribute | Value | Src |
|---|---|---|
| Role | Shared storage; high-speed feed to the MacBook via the TB5 dock | ✅ (per operator) |
| CPU | Intel **Pentium Gold 8505** (5 cores, up to 4.4 GHz) | 📄 |
| Bays | 4× 3.5″ SATA + 2× M.2 NVMe | 📄 |
| LAN | 2× **2.5 GbE** RJ45 (one → AX6000) | 📄 |
| High-speed | **10 GbE** link → HyperDrive TB5 dock (operator-stated; confirm source port) | ✅ link / 📄 port |
| Other | USB-C 10 Gbps, USB-A, HDMI | 📄 |

### 2.7 HyperDrive Thunderbolt 5 Dock HD2801 (inner country)
| Attribute | Value | Src |
|---|---|---|
| Role | Bridges NAS 10 GbE ⇄ MacBook over Thunderbolt | ✅ (per operator) |
| Bus | **Thunderbolt 5** dock; negotiated **40 Gb/s** with the M1 host (M1 = TB3/USB4 cap) | ✅ |
| Downstream | Multiple TB5 ports reporting "up to 40 Gb/s" to this host | ✅ |
| Spec ports | 3× TB5, 10 GbE RJ45, USB-A/C, HDMI/DP, SD/microSD (per HD2801 sheet) | 📄 |

### 2.8 Verizon 5G Modem (edge of the outer country)
| Attribute | Value | Src |
|---|---|---|
| Role | Internet uplink (WAN) to the AX1800 | ✅ |
| Antennas | 6 | ✅ (per operator) |
| Public IP | `97.164.202.176` (Verizon) — **almost certainly CGNAT** (no port-forwardable inbound) | ✅ |

### 2.9 clinic-vps (remote — currently OFFLINE)
GoDaddy VPS (`abrownsanta@…secureserver:2222`), Ubuntu, ran a DustPan agent. **Unreachable
on every path** (SSH `:2222` timeout, WG dead, `clinic.yousirjuan.ai` NXDOMAIN). Out of
scope until revived; relevant later as a potential **public relay** for CGNAT inbound.

---

## 3. Physical topology & cabling

```
  Verizon 5G Modem (6 antennas)   -- public 97.164.202.176 (CGNAT)
        | 1 GbE eth (WAN)
        v
  +------------------------------------------------------------------- OUTER --+
  |  AX1800  (192.168.0.1)   EDGE / front gate                                  |
  +-------+----------------------------------------------------------------------+
          | eth  (AX6000 WAN takes a 192.168.0.x lease)
          v
  +------------------------------------------------------------------- INNER --+
  |  AX6000  (192.168.8.1)   internal router · WG mesh 10.1.0.0/24               |
  |     |-- 2x Airport Extreme  (wired together; one -> UGreen NAS)              |
  |     |        \-- iMac 21.5" (64 GB, Radeon Pro 560 4 GB)                     |
  |     |-- eth -- DGX Spark / AI Engine (192.168.8.249) -- Ollama + Ctrl Tower  |
  |     |-- 2.5 GbE -- UGreen DXP4800 Pro (NAS)                                  |
  |     |                   \-- 10 GbE -- HyperDrive TB5 --40Gb/s TB-- MacBook   |
  |     \-- 1 GbE (en4) -- MacBook Pro M1 (192.168.8.205)  [LAN/mgmt path]       |
  +------------------------------------------------------------------------------+
```

**Verified hop chain (traceroute from the MacBook):** `192.168.8.1` (AX6000) ->
`192.168.0.1` (AX1800) -> `10.184.120.18` (Verizon carrier) -> internet. **Two NAT layers.**

---

## 4. Logical addressing

| Segment | Subnet | Gateway | Notes |
|---|---|---|---|
| Outer LAN | `192.168.0.0/24` | AX1800 `.1` | faces the 5G modem |
| Inner LAN | `192.168.8.0/24` | AX6000 `.1` | DGX, Mac, NAS, iMac, APs |
| Inner WG mesh (live) | `10.1.0.0/24` :51821 | AX6000 `10.1.0.1` | Mac `.4`, DGX `.5` |
| Outer WG (planned) | `10.10.0.0/24` :51820 | AX1800 `10.10.0.1` | front-gate clients |
| Border transit (planned) | `10.255.255.0/30` | — | AX1800 `.1` <-> AX6000 `.2` |
| Carrier (Verizon) | `10.184.120.0/?` | — | CGNAT hop |
| Dead/retired | `10.0.0.0/24` | — | old mesh, decommissioned |

---

## 5. The WireGuard "customs & border control" design

**Principle:** the inner country is *not* on the modem's network and never shares L2/L3
with it. The only path between countries is a WireGuard tunnel; the firewall at each end is
**customs**.

- **Border = site-to-site WG** peering **AX1800 <-> AX6000** over the eth link, on the
  `10.255.255.0/30` transit. Each router's peer `AllowedIPs` lists the *other* country's
  subnets — making the tunnel the only L3 route between them. Because it rides the **local
  eth link, CGNAT does not affect it.**
- **Customs (firewall):**
  - **Outer -> Inner:** deny-by-default + a narrow allowlist (e.g. a vetted client reaching
    the AI Engine API). The checkpoint.
  - **Inner -> Outer:** controlled egress (model pulls/updates + established replies) or full
    air-gap, operator's choice.
- **AI Engine sealing:** Ollama `:11434` and DustPan `:8765` are bound to the inner side
  and reachable only from inside or across customs — closing today's open-on-LAN exposure.
- **Strict policy note:** ASUS *stock* firewall is coarse; **Merlin firmware** (or a small
  Linux gateway) is recommended where true per-flow customs rules are required.

---

## 6. Current status & known issues

| Item | State |
|---|---|
| AX6000 inner WG mesh (`10.1.0.1`) | live (Mac, DGX peers) |
| **DGX IPv4 on the LAN** | 🔴 down (2026-06-01) — `192.168.8.249`/`.114` unreachable over IPv4 from Mac **and** VPS (even `:22`); **IPv6 works** (`fd4b:36c7:d004::352`, how SSH connects). App/Caddy/DGX healthy — a LAN-layer IPv4 fault (wired port / switch / router IPv4). Workaround: Mac `/etc/hosts` points search/bank at the DGX IPv6. Fix: restore wired/LAN IPv4 (cable/switch/router or reboot). |
| DGX AI Engine — Ollama + Control Tower `:5174` | healthy |
| MacBook + DGX DustPan agents | healthy |
| WG border tunnel (two countries) | NOT built yet — this plan |
| Ollama `:11434` | exposed `0.0.0.0` (one internal Docker consumer `172.18.0.2`) — to seal |
| clinic-vps | offline on all paths |
| Internet-inbound WG | blocked by Verizon 5G CGNAT — needs a relay |

---

## 7. Verification matrix (border build)

1. **Border up:** AX6000 `ping 10.255.255.1`; `wg show` both routers = recent handshake + bytes both ways.
2. **Customs:** outer-WG client reaches the AI Engine **only** on allowlisted ports; everything else denied.
3. **Inner sealed:** from the outer `192.168.0.x` LAN *without* the WG -> DGX `:8765`/`:11434` **must fail**.
4. **Cockpit:** Mac on inner WG -> `http://192.168.8.x:5174` loads; DGX disks live.
5. **No regression:** existing inner mesh `10.1.0.0/24` peers unaffected.

---

## 8. Appendix — provenance

All ✅ values were read live on 2026-06-01 via: DGX `ssh nephew-nivram` (`lscpu`,
`nvidia-smi`, `lsblk`, `ethtool`, `ip`, `ss`, `ollama list`); MacBook `system_profiler`
(`SPHardwareDataType`, `SPThunderboltDataType`), `networksetup`, `ifconfig`, `traceroute`.
📄 values are manufacturer spec sheets pending SKU confirmation (routers, NAS, dock, APs).
