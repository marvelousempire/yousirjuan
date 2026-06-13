# Full Detailed Architecture Report — Home Network, Matrix, and AI Integration

**Status:** living document · **Last verified:** 2026-06-10 (§1–§6 reconciled from dual briefings) · **Author:** operator-confirmed (Nephew indexed)
**Audience:** Nephew, Bishop agents, and any AI briefed on the family stack — paste this whole file when onboarding another model.

**Provenance legend:** ✅ *verified* = confirmed on live gear this session · 📄 *planned* = approved intent, not yet applied · 🔄 *transitional* = correct direction, interim hardware still in place · ⚠️ *reconcile* = may differ from older docs until VLAN rollout lands.

**Companion docs:**

| Doc | Role |
|---|---|
| [`whitepaper-hardware-network.md`](whitepaper-hardware-network.md) | Hardware inventory, port maps, device specs |
| [`hardware/network-architecture.md`](hardware/network-architecture.md) | Earlier VLAN/WG cheat-sheet (partially superseded — see §1 live state) |
| [`edge-architecture-triple-threat.md`](edge-architecture-triple-threat.md) | Public cassette edge (Caddy/nginx/Traefik) |
| [`family-fleet-ssh-claude.md`](family-fleet-ssh-claude.md) | SSH fleet map for operator + `claude` user |
| `marvelousempire/nephew` → [`plans/0156-dxp6800-buildout-storage-docker-mail-chat-aigen.md`](../../nephew/plans/0156-dxp6800-buildout-storage-docker-mail-chat-aigen.md) | NAS buildout program (mail, chat, Docker, 10 GbE) |
| `marvelousempire/nephew` → [`infra/README.md`](../../nephew/infra/README.md) | DGX IaC entry — stacks manifest + `make dgx-*` |
| `marvelousempire/nephew` → [`plans/0151-travel-wg-server-device-profiles.md`](../../nephew/plans/0151-travel-wg-server-device-profiles.md) | MT6000 `wgserver` travel mesh |

> **Live LAN note (2026-06-10):** The MT6000 currently runs a **flat** `192.168.10.0/24` LAN (`192.168.10.1` gateway). The VLAN address plan in §2 is the **immediate optimization target** — apply it deliberately; reconcile firewall rules and WG `AllowedIPs` when subnets change. Clinic case: [`clinic/cases/2026-06-09-mt6000-lan-renumber-wg-fw4-forwarding.md`](../../clinic/cases/2026-06-09-mt6000-lan-renumber-wg-fw4-forwarding.md).

---

## 1. Current Hardware & Roles (What We Have Today — June 2026)

### Hardware connections today

| Device / link | Role today |
|---|---|
| **Verizon Business modem** | **IP Passthrough** mode (**LAN2** port active); hands public IP directly to the main router |
| **GL-MT6000 (Flint 2)** | Main router — **OpenWrt 24.10**; currently the **single point** doing everything (see duties below) |
| **GL-MT5000 Brume 3** | **Dumb switch** on an MT6000 LAN port — routing, DHCP, and firewall **disabled**; extra **2.5G** Ethernet ports |
| **DGX Spark** | High-performance **local AI workstation** and family client (`192.168.10.205` on Trusted LAN) |
| **UGREEN DXP6800 Pro** | Available for always-on services — **not yet integrated** for Matrix/AI (`192.168.10.119` on Trusted LAN) |
| **All other devices** | Family computers, IoT appliances, phones, etc. — wired or wireless through **MT6000 + Brume 3** |

**GL-MT6000 currently handles:**

- All routing and firewall duties
- All Wi-Fi networks (single flat LAN today)
- **WireGuard VPN server** (`wgserver`) with individual peer profiles already configured
- **Multiple custom security packages** already installed

### WireGuard on MT6000

- WireGuard **server** (`wgserver`) is already running with **individual peer profiles** per trusted device.
- All tunnels **terminate on the MT6000**.
- Separate from (and in addition to) the **WG client → VPS** mesh (`wg0`, family edge path to `72.167.151.251`) documented in clinic cases and Plan 0151 travel mesh.

---

## 2. Current Network Structure & Immediate Optimization (MT6000 Only)

**Today:** All devices run behind the **single MT6000** on a flat **`192.168.10.0/24`** LAN (`192.168.10.1` gateway).

**Optimization goal (before Protectli arrives):** Create **three separate networks** using VLANs on the MT6000 — real segmentation with only current hardware.

### VLAN strategy on MT6000 (OpenWrt)

| VLAN | Zone | Subnet | SSID (target) |
|---|---|---|---|
| **1** (default LAN) | **Trusted** | `192.168.10.0/24` | `Trusted_WiFi` |
| **10** | **IoT** | `192.168.11.0/24` | `IoT_WiFi` |
| **20** | **Guest** | `192.168.20.0/24` | `Guest_WiFi` |

See **§7** for LuCI paths, uci commands, and verification. IoT uses `.11` deliberately so Trusted can stay on live `.10` without overlap.

### Wi-Fi configuration

Create **separate SSIDs**, each bound to its VLAN:

- **Trusted_WiFi** → Trusted VLAN
- **IoT_WiFi** → IoT VLAN
- **Guest_WiFi** → Guest VLAN with **Client/AP Isolation** enabled

### Firewall rules (priority order on MT6000)

Apply in this order (deny before broad allow):

1. **Block** all traffic from **Guest (VLAN 20)** → **Trusted (VLAN 1)**
2. **Block** all traffic from **Guest (VLAN 20)** → **IoT (VLAN 10)**
3. **Block** all traffic from **IoT (VLAN 10)** → **Trusted (VLAN 1)** — allow only very specific ports later if needed
4. **Allow** Guest and IoT **only to WAN** (internet)
5. **Allow Trusted full access** — WireGuard server listens **only on Trusted**

**WireGuard strategy (current):**

- Keep the existing WireGuard server on the MT6000, bound **only to the Trusted network**.
- **No Guest or IoT devices** may connect to WireGuard.
- After VLAN cutover, preserve VPS ↔ LAN forwarding via persisted **fw4/nft** rules (see §7.2).

OpenWrt 24 **fw4/nft:** manual forward rules that must survive `firewall restart` belong in the persisted nft path (see clinic MT6000 case — `iptables-only` in `firewall.user` is insufficient).

This gives **Fort Knox–style isolation** even before the Protectli arrives.

---

## 3. Private Family Communication System (Matrix + Element) — Planned

### Where it runs

| Component | Host |
|---|---|
| **Matrix homeserver (Synapse)** | **UGREEN DXP6800 Pro** (Docker on NAS) — hostname **`matrix.jailynmarvin.com`** |
| **Clients** | **Element** on phones, laptops, DGX Spark, and every family member device |

### What family gets (Element)

- End-to-end encrypted messaging and group chats
- Voice and video notes
- File sharing, reactions, threads, and room history
- **Proprietary-feeling UX** — fully on your own hardware; **no third-party chat servers**

All communication stays completely inside your own hardware and **WireGuard tunnels**.

### Full security stack

| Layer | Control |
|---|---|
| Network | Matrix traffic **only** through **WireGuard tunnels** (not public internet) |
| Transport | TLS to Synapse inside the mesh |
| Messages | **End-to-end encryption** on client devices |
| Server | Event signing and **server signature verification** for message integrity (Synapse) |
| Federation | **Disabled** or heavily restricted — **family-only** single-homeserver use |
| Discovery | **`matrix.jailynmarvin.com`** — mesh-only; **no public DNS A record** |

Human team chat is part of Plan 0156 Phase D+ on the NAS; GPU-adjacent AI chat UI (Odysseus) stays on the DGX.

---

## 4. AI Integration — Matrix Application Service Bot

### Architecture

```
Family Element clients
        │
        ▼
  Synapse (UGREEN NAS) ◄──── Application Service registration
        │
        ▼
  @ai-bot:jailynmarvin.com  (privileged AppService user)
        │
        ▼
  Local models on DGX Spark (Ollama or custom FastAPI)
```

| Piece | Location | Notes |
|---|---|---|
| **AI bot** | UGREEN DXP6800 Pro | Runs as a privileged **Matrix Application Service** |
| **Bot user** | `@ai-bot:jailynmarvin.com` | Summoned via mention or command in family rooms |
| **Use cases** | Family rooms | Research, summaries, idea logging, quick answers — **local models only** |
| **Inference** | DGX Spark (`192.168.10.205`) | Ollama (`:11434`) or custom FastAPI/Hermes — **no cloud inference** |
| **Docker Compose** | UGREEN (`/volume1/docker/matrix/`) | See services below — 📄 ships with Plan 0156 / future ledger ticket |

**Docker Compose services (on UGREEN):**

- `postgres` — Synapse database
- `synapse` — Matrix homeserver
- `matrix-ai-bot` — Node.js container with `matrix-appservice-bridge`
- `caddy` — TLS termination on Trusted LAN only
- Optional `ollama` sidecar or direct `OLLAMA_BASE_URL` pointing at DGX Spark

Network isolated internally; bot and Synapse reachable **only via WireGuard + Trusted LAN**. Firewall: allow **NAS → DGX TCP 11434** (or Hermes port) on Trusted zone only; deny from IoT/Guest.

The bot listens for **mentions or commands** in family rooms and responds using **local models only** — no data leaves the home.

---

## 5. Future State — When Protectli VP6670 Arrives

### New roles

| Device | Future role |
|---|---|
| **Protectli VP6670** (i7-1255U, 32GB+ DDR5, 1TB NVMe) | **OPNsense** — main firewall + router; **primary WireGuard server** (migrate peers off MT6000) |
| **GL-MT6000** | Pure **access point mode** — DHCP and routing **disabled** |
| **Brume 3 (MT5000)** | Portable / **travel WireGuard client** (backup VPN device off-site) |
| **UGREEN DXP6800 Pro** | Matrix homeserver + AI AppService + other always-on services |
| **DGX Spark** | Primary AI compute + family workstation |

### Physical connections (future)

```
Verizon modem (passthrough)
        │
        ▼
Protectli WAN
        │
        ├── Protectli LAN → MT6000 (AP mode — Trusted / IoT / Guest SSIDs)
        ├── Protectli LAN → Brume 3 (if needed)
        ├── Protectli LAN → wired devices
        └── Protectli LAN → UGREEN DXP6800 Pro (NAS / services)
```

**VLANs and firewall rules** move to **OPNsense** (much cleaner policy model than OpenWrt).

### Migration steps summary

1. Build and install **OPNsense** on Protectli; WAN = Verizon passthrough.
2. Recreate VLANs 1 / 10 / 20 and firewall rules (same subnets as §2 / §7).
3. Export WG configs from MT6000; migrate WireGuard server/peers to Protectli — **one device at a time**.
4. Convert **MT6000 to AP mode** (disable NAT/DHCP/firewall; trunk VLANs).
5. Repurpose **Brume 3** as travel WG **client**.
6. Point Matrix and AI services at the new trusted network behind Protectli.
7. Retire WG server on MT6000; regression: VPS→DGX, Element→Synapse, `@ai-bot` mention.

**Rollback:** keep MT6000 backup `.CFG` + OPNsense config XML export before cutover. Full 10-step checklist in **§7.7**.

This setup balances **what works today** with a **clean migration path** to the full Protectli architecture.

---

## 6. Overall Privacy & Security Goals

| Goal | How |
|---|---|
| Maximum privacy from ISP (Verizon) | Sensitive access **tunneled via WireGuard** — Verizon sees almost nothing |
| Strong network isolation (Fort Knox) | Guests and IoT have **zero path** to Trusted devices |
| Family chat | Fully **self-hosted**, **open-source** stack (Matrix, Element, WireGuard) — **E2EE**, proprietary-feeling |
| AI processing | **Stays local** on DGX Spark — no external data leakage |
| Separation of concerns | **Networking/security** (Protectli) vs **services** (UGREEN) |
| Clean migration | VLAN + firewall on MT6000 **now**; full cutover to Protectli **when hardware arrives** |

---

## 7. Microscopic operator detail

Reference address plan for the steps below (reconciles §2 with live `192.168.10.0/24`):

| Zone | VLAN ID | Bridge / iface | Subnet | Gateway |
|---|---|---|---|---|
| Trusted | 1 | `br-trusted` | `192.168.10.0/24` | `192.168.10.1` |
| IoT | 10 | `br-iot` | `192.168.11.0/24` | `192.168.11.1` |
| Guest | 20 | `br-guest` | `192.168.20.0/24` | `192.168.20.1` |

Matrix server (NAS): `192.168.10.119` (UGREEN DXP6800 Pro on Trusted). Synapse hostname target: **`matrix.jailynmarvin.com`** (mesh-only — no public DNS A record).

---

### 7.1 OpenWrt 24.10 VLAN setup (GL-MT6000)

**Before you start:** export a GL.iNet backup (**System → Backup / Restore → Download backup**). Wrong bridge edits can lock you out — keep a wired Mac on a LAN port.

#### LUCI menu path (click order)

1. **Network → Interfaces → Devices** tab
2. Select **`br-lan`** → **Configure…**
3. Enable **Bridge VLAN filtering**
4. Under **VLAN filtering**, add rows:

   | VLAN ID | CPU (eth0 / eth1 / …) | Tagged ports | Untagged ports |
   |---|---|---|---|
   | 1 | `t` on CPU | — | LAN ports that feed Trusted wired clients |
   | 10 | `t` on CPU | — | Port to IoT-only wired gear (if any) |
   | 20 | `t` on CPU | — | — (Guest is usually Wi-Fi only) |

5. **Save** → **Apply** (expect a brief disconnect)

6. **Network → Interfaces → Add new interface** (repeat per zone):

   | Name | Protocol | Device | IPv4 |
   |---|---|---|---|
   | `trusted` | Static | `br-trusted.1` (or rename from `br-lan`) | `192.168.10.1/24` |
   | `iot` | Static | `br-iot.10` | `192.168.11.1/24` |
   | `guest` | Static | `br-guest.20` | `192.168.20.1/24` |

7. **Network → DHCP and DNS** — create one DHCP server per interface (`trusted`, `iot`, `guest`) with non-overlapping pools, e.g. `.100–.250` on each subnet.

8. **Network → Wireless** — see §7.3.

Exact port-to-VLAN mapping depends on which MT6000 LAN port feeds the Brume 3 dumb switch; **all Brume downstream ports inherit the VLAN of the uplink port** (untagged).

#### uci CLI equivalent (SSH `root@192.168.10.1`)

Run in order; adjust `lan2`/`lan3` port names to match **Network → Devices** on your unit (`ip link` / LuCI port labels).

```sh
# Enable VLAN filtering on the existing bridge
uci set network.@device[0].name='br-lan'
uci set network.@device[0].type='bridge'
uci add network bridge-vlan
uci set network.@bridge-vlan[-1].device='br-lan'
uci set network.@device[0].ports='lan1 lan2 lan3 eth1'
uci set network.@bridge-vlan[-1].vlan='1'
uci set network.@bridge-vlan[-1].ports='lan1:u* lan2:u* lan3:u* eth1:u*'

uci add network bridge-vlan
uci set network.@bridge-vlan[-1].device='br-lan'
uci set network.@bridge-vlan[-1].vlan='10'
uci set network.@bridge-vlan[-1].ports='lan4:u'

uci add network bridge-vlan
uci set network.@bridge-vlan[-1].device='br-lan'
uci set network.@bridge-vlan[-1].vlan='20'
uci set network.@bridge-vlan[-1].ports=''

uci set network.trusted=interface
uci set network.trusted.device='br-lan.1'
uci set network.trusted.proto='static'
uci set network.trusted.ipaddr='192.168.10.1'
uci set network.trusted.netmask='255.255.255.0'

uci set network.iot=interface
uci set network.iot.device='br-lan.10'
uci set network.iot.proto='static'
uci set network.iot.ipaddr='192.168.11.1'
uci set network.iot.netmask='255.255.255.0'

uci set network.guest=interface
uci set network.guest.device='br-lan.20'
uci set network.guest.proto='static'
uci set network.guest.ipaddr='192.168.20.1'
uci set network.guest.netmask='255.255.255.0'

uci commit network
/etc/init.d/network restart
```

⚠️ Port names (`lan1`, `lan4`, …) **vary by firmware** — verify in LuCI before commit.

**Verification:**

```sh
ip -d link show br-lan
ubus call network.interface trusted status
ping -c1 192.168.10.1
```

---

### 7.2 Firewall zones and nft rules (§2 policy)

#### LUCI: zones and forwardings

1. **Network → Firewall → Zones**
   - Create **`iot`** zone → covered networks: `iot` interface
   - Create **`guest`** zone → covered networks: `guest` interface
   - **`trusted`** zone → `trusted` interface + add **`wg0`** and **`wgserver`** (if present) to this zone only

2. **Network → Firewall → General Settings** — defaults: `input` reject on wan, accept on lan/trusted; `forward` reject; `output` accept.

3. **Network → Firewall → Traffic Rules** — add **Reject** rules (order matters — top first):

   | Name | Source zone | Destination zone | Action |
   |---|---|---|---|
   | `deny-guest-to-trusted` | guest | trusted | Reject |
   | `deny-guest-to-iot` | guest | iot | Reject |
   | `deny-iot-to-trusted` | iot | trusted | Reject |

4. **Network → Firewall → Forwardings** — allow only:

   | Source | Destination | Enabled |
   |---|---|---|
   | trusted | wan | yes |
   | iot | wan | yes |
   | guest | wan | yes |
   | trusted | iot | yes (optional — you control bulbs from Mac) |
   | guest | trusted | **no** |
   | iot | trusted | **no** |

5. **Do not** attach `wg0` to guest or iot zones.

#### uci CLI (inter-zone rejects + forwardings)

```sh
# Reject guest → trusted
uci add firewall rule
uci set firewall.@rule[-1].name='deny-guest-to-trusted'
uci set firewall.@rule[-1].src='guest'
uci set firewall.@rule[-1].dest='trusted'
uci set firewall.@rule[-1].target='REJECT'

uci add firewall rule
uci set firewall.@rule[-1].name='deny-guest-to-iot'
uci set firewall.@rule[-1].src='guest'
uci set firewall.@rule[-1].dest='iot'
uci set firewall.@rule[-1].target='REJECT'

uci add firewall rule
uci set firewall.@rule[-1].name='deny-iot-to-trusted'
uci set firewall.@rule[-1].src='iot'
uci set firewall.@rule[-1].dest='trusted'
uci set firewall.@rule[-1].target='REJECT'

uci commit firewall
/etc/init.d/firewall restart
```

#### Preserve VPS ↔ LAN forwarding (OpenWrt 24 fw4)

After VLAN cutover, re-run the persisted script (update `LAN=` if needed):

[`ledger/LEDGER-0027-seed-to-tree-bootstrap/playbooks/glmt6000-firewall-persist.sh`](../ledger/LEDGER-0027-seed-to-tree-bootstrap/playbooks/glmt6000-firewall-persist.sh)

That script writes **both** legacy iptables lines **and** fw4 nft rules on `inet fw4 forward_lan`:

```sh
nft add rule inet fw4 forward_lan iifname wg0 oifname br-lan counter accept comment "vps-to-dgx"
nft add rule inet fw4 forward_lan iifname br-lan oifname wg0 counter accept comment "dgx-to-vps"
```

**Screenshot description (LuCI Traffic Rules):** three red **Reject** rows at the top with Source `guest`/`iot` and Destination `trusted`/`iot`; below them, green **Forward** rows showing `guest → wan`, `iot → wan`, `trusted → wan` only.

**Verification from a Guest client:**

```sh
ping -c1 192.168.10.1    # should fail or be blocked by zone policy
ping -c1 1.1.1.1         # should succeed
```

From Trusted, after WG is up:

```sh
ping -c1 192.168.10.205  # DGX — should succeed
curl -sk https://192.168.10.119:9443/  # UGREEN UGOS — should succeed
```

---

### 7.3 Wi-Fi SSID binding (GL.iNet / OpenWrt)

Per radio (**Network → Wireless → Edit** on `radio0` / `radio1`):

| SSID | Network (interface) | Security | Extra |
|---|---|---|---|
| `Trusted_WiFi` | `trusted` | WPA3-SAE (or WPA2/WPA3 mixed) | — |
| `IoT_WiFi` | `iot` | WPA2-PSK (IoT compatibility) | — |
| `Guest_WiFi` | `guest` | WPA2-PSK (unique password) | Enable **Isolate Clients** / AP isolation |

On GL.iNet firmware: **Wireless → [SSID] → Advanced → Network** must point at the correct interface name (`trusted`, not `lan`).

Disable the old single `GL-MT6000-xxx` SSID on `lan` once the three SSIDs are tested.

---

### 7.4 Synapse `homeserver.yaml` snippets (UGREEN Docker)

Bind Synapse to the **Trusted LAN only** — not `0.0.0.0` on the NAS if UGOS exposes other interfaces.

```yaml
server_name: "jailynmarvin.com"
public_baseurl: "https://matrix.jailynmarvin.com/"
report_stats: false

listeners:
  - port: 8008
    type: http
    bind_addresses: ["127.0.0.1", "192.168.10.119"]
    x_forwarded: true
    resources:
      - names: [client, federation]
        compress: false

  - port: 8448
    type: http
    bind_addresses: ["127.0.0.1", "192.168.10.119"]
    resources:
      - names: [federation]

# Federation off — family-only server
federation_domain_whitelist: []
allow_public_rooms_without_auth: false
enable_registration: false
registration_shared_secret: "<generate-long-random-string>"

# Signing key — persist volume, never regenerate casually
signing_key_path: "/data/matrix.jailynmarvin.com.signing.key"

database:
  name: psycopg2
  args:
    user: synapse
    password: "<from-docker-secret>"
    database: synapse
    host: postgres
    cp_min: 5
    cp_max: 10
```

**Reverse proxy (Caddy on NAS or DGX edge)** — TLS terminate on Trusted only; example:

```caddyfile
matrix.jailynmarvin.com {
  bind 192.168.10.119
  reverse_proxy 127.0.0.1:8008
}
```

**Access path:** clients reach `matrix.jailynmarvin.com` only when **WireGuard is up** (split DNS or `/etc/hosts` / profile DNS pointing the name to `192.168.10.119` inside the mesh). No public A record.

---

### 7.5 Element client config (custom homeserver over WG)

#### Desktop / mobile — manual server

1. Open Element → **Sign in** → **Edit** homeserver URL
2. Set **`https://matrix.jailynmarvin.com`** (must match Synapse `public_baseurl`)
3. First login creates the device cross-signing keys (keep secure backup)

#### `.well-known` (required for auto-discovery)

Serve on the same host (Caddy):

```caddyfile
https://jailynmarvin.com {
  respond /.well-known/matrix/server "{\"m.server\": \"matrix.jailynmarvin.com:443\"}"
  respond /.well-known/matrix/client "{\"m.homeserver\": {\"base_url\": \"https://matrix.jailynmarvin.com\"}}"
}
```

If you skip public DNS entirely, push equivalent entries via **split DNS on the MT6000** (Trusted DHCP option or `dnsmasq` host overrides) so `.well-known` resolves only for WG + Trusted clients.

#### `config.json` (Element Web self-hosted — optional)

```json
{
  "default_server_config": {
    "m.homeserver": {
      "base_url": "https://matrix.jailynmarvin.com",
      "server_name": "jailynmarvin.com"
    }
  },
  "brand": "Family Chat",
  "disable_guests": true,
  "features": {
    "feature_registration": false
  }
}
```

---

### 7.6 Matrix Application Service + Docker Compose (UGREEN)

#### Registration file (`/data/matrix/ai-bot-registration.yaml`)

Generate once:

```sh
python3 - <<'PY'
import hashlib, hmac, secrets
token = secrets.token_hex(32)
print("id:", "ai-bot")
print("url:", "http://matrix-ai-bot:8080")
print("as_token:", token)
print("hs_token:", secrets.token_hex(32))
print("sender_localpart:", "ai-bot")
print("namespaces:", "users: exclusive regex @ai-bot:.*")
PY
```

Example YAML (tokens from generator — **store in Docker secret, not git**):

```yaml
id: ai-bot
url: "http://matrix-ai-bot:8080"
as_token: "<AS_TOKEN>"
hs_token: "<HS_TOKEN>"
sender_localpart: ai-bot
namespaces:
  users:
    - exclusive: true
      regex: "@ai-bot:.*"
  rooms: []
  aliases: []
rate_limited: false
de.sorunome.msc2409.push_ephemeral: true
```

Register with Synapse:

```yaml
# homeserver.yaml (append)
app_service_config_files:
  - /data/ai-bot-registration.yaml
```

Restart Synapse after adding the file.

#### Bot → DGX inference env

```yaml
# matrix-ai-bot container
OLLAMA_BASE_URL: "http://192.168.10.205:11434"
# or
HERMES_URL: "http://192.168.10.205:8642/v1/chat/completions"
BOT_TRIGGER: "@ai-bot"
```

Firewall: allow **NAS → DGX TCP 11434** (or Hermes port) on **Trusted zone only**; deny from IoT/Guest.

#### Docker Compose skeleton (NAS `/volume1/docker/matrix/`)

```yaml
services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: synapse
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: synapse
    volumes:
      - ./postgres:/var/lib/postgresql/data
    restart: unless-stopped

  synapse:
    image: matrixdotorg/synapse:latest
    depends_on: [postgres]
    volumes:
      - ./synapse/homeserver.yaml:/data/homeserver.yaml:ro
      - ./synapse/data:/data
      - ./ai-bot-registration.yaml:/data/ai-bot-registration.yaml:ro
    ports:
      - "127.0.0.1:8008:8008"
    restart: unless-stopped

  matrix-ai-bot:
    image: ghcr.io/your-org/matrix-ai-bot:latest  # build or pin local image
    environment:
      HOMESERVER_URL: http://synapse:8008
      AS_TOKEN: ${AS_TOKEN}
      HS_TOKEN: ${HS_TOKEN}
      OLLAMA_BASE_URL: http://192.168.10.205:11434
    depends_on: [synapse]
    restart: unless-stopped

  caddy:
    image: caddy:2-alpine
    ports:
      - "192.168.10.119:443:443"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - caddy_data:/data
    restart: unless-stopped

volumes:
  caddy_data:
```

Ship the real compose + secrets under Plan 0156 / a future `LEDGER-0034-matrix-ai-bot` ticket — this skeleton is the contract shape.

---

### 7.7 Protectli VP6670 migration checklist

Execute in order when the hardware arrives:

| Step | Action | Verification |
|---|---|---|
| 1 | Install **OPNsense** on Protectli; WAN = Verizon passthrough; LAN = trunk to MT6000 | Web UI on LAN |
| 2 | Recreate VLANs 1 / 10 / 20 with same subnets as §7 reference table | `ping` gateways from each VLAN |
| 3 | Migrate **DHCP** scopes to OPNsense; disable DHCP on MT6000 | Clients renew correct subnet |
| 4 | Export WG configs from MT6000 (`wg show`, `/etc/wireguard/`, GL.iNet peer QR codes) | Inventory doc updated |
| 5 | Stand up **WireGuard on OPNsense** (same UDP port or new — update Verizon PF once) | Off-LAN peer handshake |
| 6 | Cut over peers **one device at a time** (Mac → iPhone → VPS path) | Each peer reaches Trusted LAN |
| 7 | Convert **MT6000 to AP mode** (disable NAT/DHCP/firewall; trunk VLANs) | Wired client gets correct VLAN |
| 8 | Repurpose **Brume 3** as travel WG **client** profile | Connect from off-site |
| 9 | Retire WG server on MT6000 | `wgserver` stopped; OPNsense only |
| 10 | Regression: VPS→DGX, Element→Synapse, `@ai-bot` mention | End-to-end smoke |

**Rollback:** keep MT6000 backup `.CFG` + OPNsense config XML export before cutover.

---

*§7 expanded 2026-06-09; §1–§6 reconciled 2026-06-10. Operator execution gates: VLAN lab on one port first; Matrix stack after Plan 0156 Phase C Docker-host lock.*

---

*Indexed from operator architecture briefings (2026-06-09 §7, 2026-06-10 §1–§6). Supersedes fragmented VLAN notes in `hardware/network-architecture.md` for strategic planning; keep that file for historical WG peer tables until merged.*
