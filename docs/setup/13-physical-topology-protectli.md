# Chapter 13 — Physical Topology, Cabling & Protectli Migration

**Status:** living · **Last verified against:** Jun 2026 hardware audit + architecture report  
**Companion (microscopic detail):** [`../home-network-full-architecture-report.md`](../home-network-full-architecture-report.md)  
**Note:** Older docs describe **192.168.8.x** and **Brume-split** topologies — those are **historical**. Live LAN today is **`192.168.10.0/24`**.

---

## Live topology today (June 2026)

```text
Internet
    │
Verizon 5G Business Gateway (IP Passthrough — LAN2 active)
    │
    ▼
GL-MT6000 Flint 2 (192.168.10.1) — OpenWrt 24.10
    │  • Router + firewall + Wi-Fi (flat Trusted LAN today)
    │  • WireGuard server (wgserver) — off-LAN family access
    │  • Family WG mesh overlay 10.1.0.0/24 (VPS .2, DGX .5, router .1, Mac peers)
    │
    ├── LAN port → GL-MT5000 Brume 3 (dumb 2.5G switch — routing/DHCP OFF)
    │       └── extra 2.5G ports for wired clients
    │
    ├── Wi-Fi + wired Trusted LAN (192.168.10.0/24)
    │       ├── DGX Spark ............... 192.168.10.205  (nephew-spark)
    │       │       └── 10GbE ──────────► UGREEN DXP6800 ... 192.168.10.119  (nasa)
    │       ├── MacBook Pro M5 Max ...... FIVEMAC (operator primary)
    │       ├── MacBook Pro M1 .......... ONEMAC-2 (legacy laptop)
    │       ├── iMac 2017 Intel .......... wired (optional x86 services)
    │       ├── Apple AirPort Extreme ×2 . coverage / bridge APs
    │       └── phones, IoT (flat LAN today — VLAN split is next)
    │
    └── Comet GL-RM10RC (KVM appliance)
            ├── 1G Ethernet → LAN (console path varies by cabling era)
            └── USB-C KVM → DGX Spark (headless console — no network routing role)

Clinic VPS (nephew-ct) — public edge, WireGuard mesh peer 10.1.0.2
```

### What each link is for

| Link | Speed | Purpose |
|---|---|---|
| Verizon → MT6000 WAN | passthrough | Single public IP to home router |
| MT6000 → Brume 3 | 2.5G | Dumb switch expansion |
| DGX ↔ NAS | **10GbE direct** | Fast git objects, NFS/SMB, Historia vault, backups |
| Comet → DGX | USB-C KVM | Physical console when SSH/IPv6 path is awkward |
| DGX → MT6000 | wired (2.5G class) | Primary LAN + mesh |

---

## Complete hardware inventory (what we actually have)

### Compute

| Device | Hostname / alias | LAN | Role |
|---|---|---|---|
| **NVIDIA DGX Spark** | `nephew-spark`, `nephew-nivram` | `.205` | GPU brain — Ollama, Qdrant, embeddings, tower-api, voice, Docker fleet, Gitea compute |
| **MacBook Pro M5 Max** | FIVEMAC / fivemac | DHCP `.10.x` | Operator Jarvis edge — Cursor, Pockit gateway, Holler voice, Obsidian, tower-api proxy |
| **MacBook Pro M1** | ONEMAC-2 | DHCP `.10.x` | Legacy laptop + HyperDrive TB5 dock |
| **iMac 2017** | — | wired `.10.x` | x86 Docker, light Ollama, warm-standby candidate |
| **Mac mini M4 Pro** | — | (when deployed) | Planned always-on orchestration |
| **Clinic VPS** | `nephew-ct` | WG `.2` | Public HTTPS edge, Clinic, nginx → mesh backends |
| **Jetson Thor 128GB** | — | — | **Planned** — not purchased |

### Storage

| Device | Hostname | LAN | Role |
|---|---|---|---|
| **UGREEN DXP6800 Pro** | `nasa.local` | `.119` | Historia vault, git objects, media, **target** for Matrix/Synapse + heavy Docker (Plan 0197) |

**DGX NAS mounts (when linked):** `/mnt/nas-docker` (~1.9 TB), `/mnt/nas-media` (~11 TB), `/mnt/nas/historia`  
**Mac mount:** `/Volumes/historia` → sovereign Obsidian vault

### Network & security hardware

| Device | Role today | Future role |
|---|---|---|
| **Verizon 5G Business Gateway** | WAN, IP passthrough to MT6000 | Same — passthrough to **Protectli WAN** |
| **GL-MT6000 (Flint 2)** | **Everything** — router, firewall, Wi-Fi, WG server | **AP mode only** — VLAN trunk, no NAT/DHCP |
| **GL-MT5000 (Brume 3)** | Dumb 2.5G switch on MT6000 LAN | **Travel WireGuard client** (backup VPN off-site) |
| **GL-AX1800 (Slate)** | Interim / IoT AP in older plans | Retiring as MT6000/Protectli VLANs land |
| **Apple AirPort Extreme ×2** | Wi-Fi / Ethernet extension | House coverage on MT6000 LAN ports |
| **Protectli VP6670** | **Arriving** — i7-1255U, 32GB+ DDR5, 1TB NVMe | **OPNsense** — primary firewall, router, WG server |
| **Comet GL-RM10RC** | KVM to DGX only | Same |
| **Netgear WN3500RP** | **Retired** — do not use | — |

### Desk / creative (house network)

| Device | Role |
|---|---|
| **HyperDrive TB5 dock ×2** | M1/M5 — 2.5G Ethernet + NVMe |
| **Sonnet Echo 11 TB4** | Thunderbolt expansion |
| **Anker Prime 14-in-1** | USB-C hub |

---

## VLAN plan (near-term — on MT6000 before or during Protectli cutover)

| VLAN | Zone | Subnet | SSID target |
|---|---|---|---|
| 1 | **Trusted** | `192.168.10.0/24` | `Trusted_WiFi` |
| 10 | **IoT** | `192.168.11.0/24` | `IoT_WiFi` |
| 20 | **Guest** | `192.168.20.0/24` | `Guest_WiFi` (client isolation) |

**Firewall priority:** deny Guest→Trusted, Guest→IoT, IoT→Trusted **before** any broad allow. WG server listens on **Trusted only**.

This gives Fort Knox isolation **before** Protectli lands — do not wait for new hardware to segment.

---

## Protectli VP6670 — arriving / migration path

**Hardware:** Protectli **VP6670** — Intel i7-1255U, 32 GB+ DDR5, 1 TB NVMe  
**Software:** **OPNsense** — replaces MT6000 as router/firewall/WG authority

### Future physical layout

```text
Verizon (passthrough)
    │
    ▼
Protectli WAN (OPNsense)
    │
    ├── LAN trunk → MT6000 (AP mode — Trusted / IoT / Guest SSIDs)
    ├── LAN → Brume 3 (optional wired)
    ├── LAN → wired clients (DGX, NAS, Macs)
    └── LAN → UGREEN DXP6800 (Matrix, Docker-heavy services)
```

### Role changes after cutover

| Device | After Protectli |
|---|---|
| **Protectli** | Firewall, NAT, DHCP, VLANs, **primary WireGuard server** |
| **MT6000** | AP + switch only — NAT/DHCP/firewall **disabled** |
| **Brume 3** | Portable **travel WG client** |
| **NAS** | Matrix Synapse, Element, always-on Docker (Plan 0197) |
| **DGX** | GPU + tower-api + retrieval + voice — **not** heavy DB containers |

### Ten-step migration checklist

Execute in order when Protectli is on the bench:

1. Install **OPNsense** — WAN = Verizon passthrough; LAN = trunk toward MT6000  
2. Recreate VLANs 1 / 10 / 20 with **same subnets** as table above  
3. Migrate **DHCP** to OPNsense; disable DHCP on MT6000  
4. **Export** all WG configs from MT6000 (peers, keys inventory — store securely, not in git)  
5. Stand up **WireGuard on OPNsense** (update Verizon port-forward if UDP port changes)  
6. Cut over peers **one device at a time** (Mac → iPhone → VPS path)  
7. Convert **MT6000 to AP mode** (trunk VLANs; no NAT)  
8. Configure **Brume 3** as travel WG **client**  
9. **Retire** WG server on MT6000  
10. **Regression smoke:** VPS→DGX, Element→Synapse, Matrix `@ai-bot`, family doors  

**Rollback:** MT6000 backup `.CFG` + OPNsense XML export **before** step 6.

Full LuCI/uci detail: `home-network-full-architecture-report.md` §7.

---

## Workload placement (DGX vs NAS — Plan 0197)

| Tier | Run on | Examples |
|---|---|---|
| **GPU / latency** | **DGX only** | Ollama, embeddings, reranker, whisper/fish-speech, ComfyUI, hot Qdrant |
| **Control API** | **DGX** (light) | tower-api, graph-service (calls NAS URLs) |
| **Stateful Docker** | **NAS target** | WordPress+MariaDB, Gitea, Matrix, Grafana, Quartz, CouchDB, n8n |
| **Durable files** | **NAS NFS** | Historia, sovereign vault, git mirrors, wp-content, backups |

**Today:** many Tier C containers still on DGX — migration in flight. **Do not** use UGOS appliance-Docker on NAS; use **SSH + clean Docker** on DXP6800.

---

## WireGuard — two overlays to know

| Overlay | Subnet | Purpose |
|---|---|---|
| **Family mesh (live)** | `10.1.0.0/24` | VPS `.2`, DGX `.5`, router `.1`, Mac peers — internal service reach |
| **MT6000 wgserver** | per-peer profiles | Off-LAN travel access terminating on home router |

Plan 0180 law: internal services bind **127.0.0.1 + wg0** — not open LAN. Mac on Wi-Fi uses **tower-api on DGX** for retrieve, not direct Qdrant ports.

---

## Doc era reconciliation (don't get fooled)

| Doc / era | LAN model | Status |
|---|---|---|
| **Live (Jun 2026)** — this chapter, family-office-network | `.10.0/24`, MT6000 router | ✅ **Trust for execution** |
| **Jun 10 architecture report** | Same + VLAN target | ✅ Strategic |
| **Jun 5 whitepaper** | Brume-split, `.8.x` house | 🔄 Target / partial |
| **Seed-to-tree runbooks** | DGX `.8.249`, `.8.0/24` | ⚠️ **Stale IPs** |
| **hardware-inventory.json (Jun 5)** | Brume main gateway | ⚠️ **Stale roles** |

When a script or env var cites `192.168.8.249`, treat it as **stale** — live DGX is **`192.168.10.205`**.

---

## Related

- [01-hardware.md](./01-hardware.md) — specs and workload routing  
- [02-network-security.md](./02-network-security.md) — bind model and Family Office Sandwich  
- [14-historia-and-operator-memory.md](./14-historia-and-operator-memory.md) — NAS Historia paths  
- Nephew: `docs/infrastructure/family-office-network.md`, `Journal/reports/2026-06-15-hardware-sovereign-audit.md`, `plans/0197-nas-docker-heavy-storage-migration.md`
