# Whitepaper — Awe Engine Stack: Hardware & Network Reference

**Status:** living document · **Last verified:** 2026-06-01 · **Author:** Nephew (Claude Code)
**Provenance legend:** ✅ *verified* = read live from the device this session · 📄 *spec-sheet* = manufacturer datasheet value (device not directly probeable over the network) · ⚠️ *inferred* = best-estimate, confirm.

This document describes the physical hardware, every cabled and wireless link, the address plan, the data pipeline, and the security model of the two-country WireGuard border that sits on top. It is the canonical reference; a portable copy lives in `yousirjuan/docs/`.

---

## 1. Executive summary

The stack is a **double-NAT, trust-segmented home datacenter**. A Verizon 5G uplink feeds an **edge router (ASUS AX1800)** which is the only device on the carrier modem. Behind it, an **internal router (ASUS AX6000)** hosts the trusted "inner country" where the **DGX Spark "Awe Engine"** (NVIDIA GB10, 128 GB unified) runs the LLM, the DustPan disk cockpit, and the Nephew Control Tower. Storage is a **UGreen DXP4800 Pro NAS** reached over 10 GbE through a **Thunderbolt 5 dock** to the MacBook. The design goal is two L3 "countries" — outer (international/edge) and inner (trusted/Awe Engine) — joined only by a **site-to-site WireGuard "border" tunnel** with firewall "customs" on each side.

---

## 2. Hardware roster (one line each)

| # | Device | Role | Key spec | Mgmt address |
|---|--------|------|----------|--------------|
| 1 | Verizon 5G Internet Gateway (6 antennas) | WAN uplink | 5G mmWave/C-band, CGNAT 📄 | carrier → public `97.164.202.176` ✅ |
| 2 | ASUS AX1800 (RT-AX1800S-class) | **Edge / front gate** | WiFi6 AX1800, 1×GbE WAN + 4×GbE LAN 📄 | LAN `192.168.0.1` ✅ |
| 3 | ASUS AX6000 (RT-AX88U-class, MAC `94:83:c4…`) | **Internal router** | WiFi6 AX6000, 1×GbE WAN + 8×GbE LAN 📄; WG hub `10.1.0.1:51821` ✅ | LAN `192.168.8.1` ✅ |
| 4 | Apple AirPort Extreme A1521 ×2 | Wired switches / AP extension | 802.11ac 3×3, 3×GbE LAN + 1×GbE WAN each 📄 | bridged (inner) ✅(topology) |
| 5 | **DGX Spark "Awe Engine"** | AI + control plane | GB10, 20×Cortex-X925, 121 GiB unified, 3.7 TB NVMe ✅ | `enP7s7 192.168.8.249`, `wlP9s9 192.168.8.114`, `wg0 10.1.0.5` ✅ |
| 6 | UGreen DXP4800 Pro | NAS (4-bay) | Intel Pentium Gold 8505, DDR5, 1×10GbE + 1×2.5GbE 📄 | 10 GbE→Hyperdrive; 2.5 GbE→AX6000 ✅(topology) |
| 7 | HyperDrive Thunderbolt 5 Dock (HD2801) | TB5 bridge | Thunderbolt 5 (80 Gb/s) 📄; negotiates 40 Gb/s to M1 ✅ | NAS 10 GbE in → TB to MacBook |
| 8 | MacBook Pro17,1 "ONEMAC-2" | Operator workstation | Apple M1 (4P+4E), 8 GB, macOS 26.3.1 ✅ | `en0 192.168.8.205` ✅ (roster said .200), `utun8 10.1.0.4` 📄 |
| 9 | iMac 21.5″ (2017 Retina 4K) | Secondary workstation | i5/i7 Kaby Lake, Radeon Pro 560 4 GB, 64 GB RAM 📄/⚠️ | via AirPort Extreme (inner) ⚠️ |
| 10 | clinic-vps (GoDaddy) | Off-site VPS | `abrownsanta@…:2222` | `72.167.151.251` — reachable for edge; DustPan service down ⚠️ |

---

## 3. Per-device deep specs

### 3.1 DGX Spark "Awe Engine" — ✅ all probed
- **SoC:** NVIDIA **GB10** Grace-Blackwell. **CPU:** 20× ARM **Cortex-X925**, aarch64, 1 socket / 10 cores·socket / 1 thread·core, max **3.90 GHz**. **GPU:** NVIDIA GB10 (unified-memory; driver **580.159.03**).
- **Memory:** **121 GiB** unified (128 GB nominal).
- **Storage:** **Samsung MZALC4T0HBL1-00B07 NVMe**, **3.7 TB** (4.10 TB raw), 414 GB used, FW `NXHB202Q`.
- **OS:** Ubuntu **24.04.4 LTS**, kernel **6.17.0-1018-nvidia**, aarch64.
- **NICs / ports:**
  - `enP7s7` — wired **1 GbE** (1000 Mb/s, full-duplex ✅), MAC `4c:bb:47:2b:b1:07`, `192.168.8.249/24`. **Primary LAN uplink to the AX6000.**
  - `wlP9s9` — Wi-Fi, MAC `58:02:05:f5:d4:0e`, `192.168.8.114/24` (secondary).
  - `wg0` — WireGuard, `10.1.0.5/24`, **full-tunnel** (AllowedIPs `0.0.0.0/0, ::/0`) to peer `192.168.8.1:51821` (the AX6000 hub); local listen `:40278`.
  - `docker0` + multiple `br-*`/`veth*` — Docker bridge networks (the search-my-engine + bank-reader + nephew-family-edge stacks).
- **Runs:** Ollama (`qwen2.5:32b`) `*:11434` ⚠️ (see §6), Nephew Control Tower `0.0.0.0:5174`, DustPan agent `0.0.0.0:8765`, plus the Dockerized search/bank/edge stacks.

### 3.2 MacBook Pro17,1 "ONEMAC-2" — ✅ probed
- **Chip:** Apple **M1** (8 cores: 4 performance + 4 efficiency). **RAM:** 8 GB unified. **macOS:** 26.3.1 (build 25D771280a). Serial `FVFFFZ8EQ05D`.
- **Ports:** 2× Thunderbolt 3 / USB4 (**40 Gb/s** host bus ✅), 1× 3.5 mm, MagSafe-era 13″ chassis. Wi-Fi 6 (802.11ax) 📄.
- **Network:** `en0` (Wi-Fi) `192.168.8.205` ✅; WireGuard `utun8` `10.1.0.4` 📄 (tunnel was not active at probe time — confirm). Connected to the **HyperDrive TB5 dock** (NAS 10 GbE behind it).
- **Runs:** DustPan v0.69.0 `:8765`.

### 3.3 ASUS AX1800 — edge / front gate — 📄 spec-sheet (RT-AX1800S-class)
- **Wi-Fi:** AX1800 (574 Mb/s 2.4 GHz + 1201 Mb/s 5 GHz, WiFi 6). **CPU:** ~1.5 GHz tri/quad-core 📄.
- **Ports:** **1× Gigabit WAN** (to the 5G modem), **4× Gigabit LAN** (one feeds the AX6000 WAN). No multi-gig.
- **Role:** the *only* device on the Verizon modem; LAN `192.168.0.1/24`; will host **WG-OUTER `10.10.0.0/24:51820`** (proposed).

### 3.4 ASUS AX6000 — internal router — 📄 spec-sheet (RT-AX88U-class; ASUS MAC `94:83:c4…`)
- **Wi-Fi:** AX6000 (1148 Mb/s 2.4 GHz + 4804 Mb/s 5 GHz, WiFi 6). **CPU:** Broadcom quad-core 1.8 GHz, 1 GB RAM, 256 MB flash 📄.
- **Ports:** **1× Gigabit WAN** (leased `192.168.0.x` from the AX1800), **8× Gigabit LAN** (DGX, NAS 2.5 GbE→1 GbE neg., AirPort Extremes), 2× USB 3.
- **Role:** internal router `192.168.8.1/24`; **WG-INNER hub `10.1.0.0/24:51821` — LIVE** (peers: Mac `10.1.0.4`, DGX `10.1.0.5`). This is the trusted country's gateway.

### 3.5 Apple AirPort Extreme A1521 (×2) — 📄 spec-sheet
- 6th-gen (2013). **Wi-Fi:** 802.11ac 3×3 (1300 Mb/s 5 GHz + 450 Mb/s 2.4 GHz). **Ports each:** 3× Gigabit LAN, 1× Gigabit WAN, 1× USB 2.0.
- **Topology (operator-confirmed):** both inside the inner country, **wired together**, and **one of them feeds the UGreen NAS**. Used as gigabit switches / Wi-Fi extension off the AX6000.

### 3.6 UGreen DXP4800 Pro NAS — 📄 spec-sheet
- **CPU:** Intel **Pentium Gold 8505** (5-core, up to 4.4 GHz). **RAM:** 8 GB DDR5 (→ 64 GB). **Bays:** 4× 3.5″/2.5″ SATA + 2× M.2 NVMe.
- **Ports:** **1× 10 GbE RJ45**, **1× 2.5 GbE RJ45**, USB-C 10 Gb/s, USB-A, HDMI.
- **Cabling (confirmed):** 10 GbE → HyperDrive TB5 dock (→ MacBook); 2.5 GbE → AX6000.

### 3.7 HyperDrive Thunderbolt 5 Dock (HD2801) — 📄 spec-sheet
- **Thunderbolt 5** (80 Gb/s bi-dir, 120 Gb/s boost). Downstream TB5 ports + 10 GbE + USB. **To the M1 MacBook it negotiates 40 Gb/s** (M1 is TB3/USB4) ✅. Bridges the NAS 10 GbE into the Mac.

### 3.8 iMac 21.5″ (2017 Retina 4K) — 📄 spec-sheet / ⚠️
- **CPU:** Intel Core i5/i7 (Kaby Lake). **GPU:** Radeon Pro 560 4 GB. **RAM:** 64 GB (⚠️ above Apple's official 32 GB max — third-party; confirm). **Ports:** 2× Thunderbolt 3, 4× USB-A 3, 1× GbE, SDXC, 3.5 mm. Reaches the LAN via an AirPort Extreme (inner) ⚠️.

### 3.9 Verizon 5G Internet Gateway (6 antennas) — 📄 spec-sheet
- 5G (C-band/mmWave) + 4G fallback; 6 internal antennas. Typically 2× 2.5 GbE/GbE LAN out. **Carrier-grade NAT (CGNAT)** — no port-forwardable inbound from the internet. Public-facing IP observed: `97.164.202.176`.

---

## 4. Physical pipeline (cabling, top → bottom; verified by traceroute)

```
Verizon 5G Internet Gateway (6 antennas)            public 97.164.202.176 (CGNAT)
      │ eth
      ▼
ASUS AX1800  ── EDGE / FRONT GATE ──  192.168.0.1   (traceroute hop 2; only box on the modem)
      │ eth   (AX6000 WAN takes a 192.168.0.x lease)
      ▼
ASUS AX6000  ── INTERNAL ──  192.168.8.1            (traceroute hop 1; default gateway of inner hosts)
      ├── eth ───────── DGX Spark / Awe Engine (enP7s7 192.168.8.249)   ← Control Tower + LLM
      ├── eth ───────── AirPort Extreme #1 ─┬─ eth ─ AirPort Extreme #2
      │                                     └─ eth ─ UGreen DXP4800 NAS (also 2.5 GbE → AX6000)
      └── 2.5 GbE ───── UGreen NAS ──10 GbE── HyperDrive TB5 ──TB(40Gb/s)── MacBook M1 (192.168.8.205)
```

**Double-NAT (verified):** inner `192.168.8.0/24` sits behind outer `192.168.0.0/24` behind the 5G carrier → public `97.164.202.176`. 5G is CGNAT → **no inbound port-forward from the internet** (the reason an off-site host can no longer dial home directly).

---

## 5. Logical network & address plan

| Plane | Subnet / value | Notes |
|-------|----------------|-------|
| Outer LAN | `192.168.0.0/24` (gw `.1` = AX1800) | edge; only the AX6000 WAN + AX1800 Wi-Fi clients |
| Inner LAN | `192.168.8.0/24` (gw `.1` = AX6000) | trusted; DGX `.249`/`.114`, Mac `.205`, NAS, iMac, AirPorts |
| WG-INNER (live) | `10.1.0.0/24` `:51821` hub `.1`=AX6000 | peers Mac `.4`, DGX `.5` (full-tunnel) ✅ |
| WG-OUTER (proposed) | `10.10.0.0/24` `:51820` on AX1800 | not built |
| Border transit (proposed) | `10.255.255.0/30` (`.1`⇄`.2`) | site-to-site AX1800⇄AX6000 |
| Public | `97.164.202.176` (Verizon, CGNAT) | no inbound |
| Legacy | `10.0.0.0/24` | **dead** (old mesh) |

---

## 6. Software / services map & security findings

- **Nephew Control Tower** — DGX `:5174` (single pane). Agent registry: `dustpan` (DGX-local), `dustpan-spark` (DGX). ⚠️ `dustpan-clinic 10.0.0.5` stale → fix to current.
- **DustPan agents** — MacBook v0.69.0 `:8765`, DGX v0.67.0 `:8765` (token-gated). clinic offline.
- **Ollama** — DGX `*:11434`, `qwen2.5:32b`. 🔴 **Security finding (verified):** listening on all interfaces (`*:11434`), unauthenticated, LAN-wide. Sealing it into the inner country (bind to the inner address + customs firewall) closes this.
- **WireGuard** — AX6000 inner mesh `10.1.0.0/24` live; Mac full-tunnel via `utun8`. Old `10.0.0.0/24` dead.

---

## 7. The two-country WireGuard border (design)

```
┌─ OUTER COUNTRY (edge / international) ─┐      ┌─ INNER COUNTRY (trusted / Awe Engine) ─┐
│ AX1800  LAN 192.168.0.0/24            │      │ AX6000  LAN 192.168.8.0/24             │
│ WG-OUTER 10.10.0.0/24 :51820          │      │ WG-INNER 10.1.0.0/24 :51821 (LIVE)     │
│ faces the 5G modem                    │      │ DGX/Awe Engine, iMac, Mac, NAS, AirPorts│
└───────────────┬───────────────────────┘      └───────────────┬────────────────────────┘
                └────────  ░ BORDER TUNNEL ░  ───────────────────┘
                  site-to-site WG over the eth link · transit 10.255.255.0/30
                  CUSTOMS = firewall allowlist each side:
                    Outer→Inner: DENY by default + vetted allowlist (the checkpoint)
                    Inner→Outer: controlled egress only
```

- **Border** = a site-to-site WG tunnel peering **AX1800 ⇄ AX6000 over the local eth link** (CGNAT-immune). Each peer lists the other country's subnets in `AllowedIPs`. This — not flat NAT routing — becomes the only L3 path between countries.
- **Customs** = per-side firewall. Outer→Inner deny-by-default with a narrow allowlist (e.g. an authenticated client reaching the Awe Engine API). Inner→Outer controlled egress (model pulls, updates) only.
- **Why it survives CGNAT:** the border rides the internal ethernet link, so it works today; only *internet-inbound* to the outer post is blocked (a cloud relay handles remote access later — out of scope for v1).
- **Firewall note:** ASUS stock firewall is coarse; **Merlin firmware** (or a small Linux gateway) gives real per-flow iptables "customs." Recommended on whichever router enforces the strict checkpoint.

---

## 8. Current status

| Up ✅ | Down 🔴 / ⚠️ |
|------|--------------|
| AX6000 inner WG mesh (`10.1.0.1` reachable) | clinic-vps DustPan service offline |
| DGX agent + Control Tower (`:5174`) | Internet-inbound WG — blocked by 5G CGNAT |
| MacBook agent; Mac WG tunnel | Ollama `:11434` open LAN-wide (to seal) |
| Internal border path (eth link) ready | Border tunnel — not built yet (the plan) |
| — | **DGX off IPv4 on the LAN (2026-06-01)** — `192.168.8.249`/`.114` unreachable over IPv4 from Mac+VPS (even `:22`); **IPv6 works** (`fd4b:36c7:d004::352`). App/Caddy/DGX healthy — a LAN-layer IPv4 fault. Workaround: Mac `/etc/hosts`→DGX IPv6. Fix: wired/switch/router IPv4. |

---

## 9. Open items / confirmations
1. iMac RAM 64 GB exceeds Apple's official 21.5″ 2017 max (32 GB) — confirm the module config. ⚠️
2. Mac `en0` is `192.168.8.205` (roster said `.200`) — DHCP drift; pin a reservation if a stable address is wanted.
3. Exact ASUS model numbers (AX1800/AX6000) inferred from class + MAC — confirm for the port matrices.
4. Inner router `192.168.8.1` answers as **`console.gl-inet.com`** (despite the ASUS MAC `94:83:c4…`) — likely **GL.iNet / OpenWrt**, good for the border (real customs). Confirm firmware/SKU. ✅(probed)
4. Mac `utun8`/WG was not active at probe — confirm the inner-WG peer is meant to be always-up.

*Probe provenance: DGX via SSH (`lscpu`, `free`, `lsblk`, `nvme list`, `nvidia-smi`, `ip`, `ethtool`, `wg`, `ss`); Mac via `system_profiler`, `ifconfig`, `networksetup`. Router/NAS/dock/iMac/modem from manufacturer datasheets pending direct admin access.*
