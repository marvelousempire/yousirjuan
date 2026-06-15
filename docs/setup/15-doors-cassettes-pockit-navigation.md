# Chapter 15 — Doors, Cassettes & Pockit Navigation

**Public-safe:** product architecture and operator vocabulary. No credentials.

---

## Chapter intents

| Intent | Why we built it this way |
|---|---|
| **Name, not port** | Family and agents should open `http://hello.localhost/` — never memorize `:8782` or `:8009`. |
| **One front door** | A single gateway routes by hostname so every cassette feels like its own app. |
| **Pockit = family desktop** | One shell that maps every service to rails, pads, and full-page cassettes — like Finder + Launchpad + wildcard app. |
| **Cassette = plug-in contract** | New surfaces register in manifests; hosts never hardcode nav IDs. |
| **Auth at the gate** | Unauthenticated doors redirect to sign-in — network edge + auth, not port secrecy. |
| **Auto-door on create** | Adding a cassette and adding its door are the same act — no orphan `:port` URLs. |

---

## What Pockit is (operator language)

**Pockit** is the Family Office **navigational desktop** — not a generic admin dashboard.

Think of it as:

- **Finder** — browse the cassette library (`make door`, player rail, catalogue cards)
- **Launchpad** — one-click boot any player or tape (`make up <id>`, suite bar)
- **Wildcard app** — any family service can become a full-page surface behind a door name
- **Mapping layer** — shapes apps into Custom Pages, Pad Elements, Modals, Buttons, Haptics

**Retired names (never use with the board):** Hub, Pad, Launchpad → **Pockit** only.

Boot: `make pockit` from the nephew repo on the operator Mac.

---

## Section intents — taxonomy

| Term | Intent | What it is |
|---|---|---|
| **Player** | Host runtime that *plays* cassettes | `nephew-tape`, `nephew-deck`, `wordpress`, `bishop` |
| **Cassette** | Atomic plug-in surface (app, tape, iframe, backend) | Registry row in `cassette-catalogue.json` |
| **Console** | Player product with its own door and children | `pockit`, `wordpress`, `bishop` |
| **Tape** | Cassette with `framework_roles: tape` — backend + door | DustPan Python apps, WP mirrors |
| **Door** | Human hostname route to a cassette or console | `http://<id>.localhost/` |
| **Embed-app cassette** | CT/Pockit iframe tile (not full `cassette.json` yet) | Gitea, Matrix Element, ComfyUI |
| **Host** | Implementation shell | Pockit JS, Control Tower React, family-tape-gateway |

Parent chain (every cassette has lineage):

- `id` — stable SSN
- `parent_console` — which console family (`wordpress`, `dustpan`, …)
- `parent_id` — root cassette within that console
- `default_parent_player` — which player door hosts it in the family grid

Browse: `make door` · Lineage JSON: `make door <id>` · Resolver: `node scripts/resolve-surface.mjs <id> --lineage`

---

## How doors work (the mechanism)

### Intents

| Intent | Why |
|---|---|
| **Registry, not code** | New cassette = one line in `data/tape-endpoints.json` → `local_routes` — zero gateway code change. |
| **Host-header routing** | Gateway reads `Host: hello.localhost` and proxies to the correct backend. |
| **Port 80 drop** | `make doors` (sudo once) forwards `:80 → :8782` so operators type names only. |
| **Canonical copy** | Agents and docs use `canonicalDoorUrl()` from `door-url.js` — never teach `:8782` to humans. |
| **WG upstream** | Backends on DGX bind WireGuard (`10.1.0.5:<port>`) — mesh peers reach services; open LAN does not. |

### Two Make targets (do not confuse)

| Command | Intent |
|---|---|
| **`make doors`** | Install port-80 forwarder + refresh door registry + verify — **drop `:8782` from URLs** |
| **`make door`** / **`make door <id>`** | Browse cassette library tree + print lineage — **not** the forwarder |

### Layer stack

```text
Browser types:  http://pockit.localhost/
                      │
                      ▼
         port-80 forwarder (after make doors)
                      │
                      ▼
    family-tape-gateway.mjs  (127.0.0.1:8782)
         reads Host header + family auth
                      │
         ┌────────────┼────────────┐
         ▼            ▼            ▼
    Pockit shell   hello tape   gitea embed
    (family-hub)   (backend)    (10.1.0.5:3300)
```

### What you see at each door

| URL (after `make doors`) | Intent | What renders |
|---|---|---|
| `http://pockit.localhost/` | Family **player pad** — dual rail, suite bar, cassette grid | Full Pockit shell — players left, cassettes right, center canvas |
| `http://hello.localhost/` | Default **hello chat** tape | Full-page cassette backend (not a tile) |
| `http://gitea.localhost/` | Self-hosted **git forge** | Full Gitea web UI (embed or direct proxy) |
| `http://matrix-element.localhost/` | **Family Chat** | Full Element Web client |
| `http://vault.localhost/` | Sovereign **wiki publish** (Quartz) | Full vault browser surface |
| `http://wp.localhost/` | WordPress **family mirror** | Full WP Pockit theme shell |
| `http://web-jarvis-sovereign.localhost/` | **Jarvis hub** cassette | Orchestra map, child surfaces, MCP bundle |
| `http://<any-cassette-id>.localhost/` | **Any registered cassette** | Full page of that cassette's player/backend |

**Rule:** door name **===** cassette folder/id name. Adding a cassette without a door violates cassette-auto-door law.

### Adding a door (one line)

Edit `data/tape-endpoints.json`:

```json
"local_routes": {
  "<folder-name>": { "upstream": "http://10.1.0.5:<port>" }
}
```

Restart pad/gateway. Run `make doors` to refresh. Cassette discovery (`discover-cassettes.mjs`) should auto-write this on create.

---

## Pockit shell architecture

### Intents

| Intent | Why |
|---|---|
| **Dual rail** | Separate *players* (how you play) from *cassettes* (what you play) — mirrors physical tape deck mental model. |
| **Manifest-driven nav** | Hosts read JSON catalogues — new cassettes appear without shell code edits. |
| **Suite bar** | Adobe CC–style strip — jump Pockit, Control Tower, Automata, Historia, Voice without losing rails. |
| **CassetteFrame center** | Every tape gets a full canvas — iframe, native pad, or backend proxy. |
| **Sign-in gate** | Suite bar and privileged tiles hidden until family auth passes. |

```text
PlayerShell
├── Player pills (nephew-tape, nephew-deck, …)
├── Cassette sidebar / PlayerTapeRail
├── CassetteFrame (center — full page of active cassette)
├── Suite bar (pockit-suite.js — Family Office app strip)
└── Footer version badge (pockit-surface.json changelog)
```

Hosted pads: `voice-pad.js`, embed iframes, native Control Tower routes.

Motion: **cotton-ball Comet settle** — sneeze-out entry, soft overshoot, rest (family chrome standard).

---

## Embed-app vs manifest cassette

### Intents

| Intent | Why two types exist |
|---|---|
| **Fast iframe tiles** | Mature services (Gitea, Matrix, ComfyUI) ship as CT manifest rows first — no Python tape scaffold required. |
| **Full tape promotion** | When a surface needs backend logic, vanilla fields, assembly-line checks → promote to `cassette.json`. |
| **Same doors either way** | Both types get `local_routes` entries — operator experience is identical at the URL bar. |

| Type | Source of truth | Examples |
|---|---|---|
| **Manifest cassette** | `cassettes/<cat>/<id>/cassette.json` | `wordpress-plans`, `grafana`, `hello` |
| **Embed-app cassette** | `data/control-tower-apps.manifest.json` | `gitea`, `matrix-element`, `comfyui` |
| **Native card** | `data/native-cards.manifest.json` | `nephew-hello`, `overview` |

Update ritual: operator says **"Update the Cassette"** → SOP + `make cassette-line CHECK=<id>`.

Key manifests (nephew repo):

| File | Role |
|---|---|
| `data/cassette-catalogue.json` | Master cassette registry |
| `data/tape-endpoints.json` | Door routing (`local_routes`) |
| `data/local-route-catalog.json` | Door slug aliases |
| `data/control-tower-apps.manifest.json` | Embed iframe tiles |
| `containers/nephew-ct/family-hub/family-hub-cards.json` | Pockit card pins |

---

## Control Tower vs Pockit

### Intents

| Intent | Why two hosts |
|---|---|
| **Audience split** | Pockit = family grid; Control Tower = operator React dashboard with dustpan tri-rail. |
| **Same catalogue** | Both consume `cassette-catalogue.json` — no duplicate registry. |
| **Different chrome** | Family gets vanilla JS + voice pad; operators get iframe grid + native pages + Bishop factory. |

| Surface | Audience | Path |
|---|---|---|
| **Pockit** | Family | `containers/nephew-ct/family-hub/` |
| **Control Tower** | Operator | `apps/control-tower/` |

---

## Three ways to reach a cassette

### Intents

| Path | Intent | When to use |
|---|---|---|
| **Door name** | Human-friendly, auth-gated, no port | Default on operator Mac after `make doors` |
| **WireGuard direct** | Mesh peer → DGX WG IP + port | Automation, probes, DGX-local curls |
| **Public gated edge** | HTTPS apex for family off-LAN | `https://<name>.jailynmarvin.com` via VPS edge |

Off-LAN: device must be a **WireGuard peer**. `.localhost` resolves to loopback on the machine running the gateway — for phones/other Macs, local DNS or VPN to the gateway host is the next layer.

---

## Agent rules (doors + Pockit)

1. Tell operators **`http://<id>.localhost/`** — not gateway ports (RL-DOOR-URL-001).
2. Boot with `make pockit` / `make up <id>` — not raw docker on family paths.
3. Map new apps to Pockit primitives (PlayerShell, Pad Element, door) before shipping UI.
4. **Visual** = Obsidian wiki; **Jarvis** = voice only — do not conflate.
5. Every new cassette gets a door line in `tape-endpoints.json` at creation time.

---

## Related

- [05-nephew-orchestration.md](./05-nephew-orchestration.md) — CLOAK + five layers
- [12-pockit-non-vanilla-surfaces.md](./12-pockit-non-vanilla-surfaces.md) — suite bar, Comet motion, Jarvis hub
- [02-network-security.md](./02-network-security.md) — bind model + mesh
- [18-wireguard-matrix-nas-gitea-why.md](./18-wireguard-matrix-nas-gitea-why.md) — WG + Matrix + forge reasons
- Nephew: `docs/pockit/Cassette-Surface-Taxonomy.md`, `docs/sop/update-the-cassette.md`
