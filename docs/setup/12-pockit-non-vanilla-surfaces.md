# Chapter 12 — Pockit & Sovereign Surfaces (Non-Vanilla UI)

**Public-safe:** how the family shell was **synthesized** beyond stock dashboards — motion, suite chrome, cassettes, and Jarvis hub.

---

## Philosophy — Pockit is a mapping layer

Pockit is **not** a generic admin template. It is a **mapping and shaping app**:

- Apps → **Custom Pages**, **Pad Elements**, **Modals**, **Buttons**, **Haptics**  
- Every family surface is a **Cassette with Speakers** (door + chrome + optional voice)  
- Hosts read **manifests** — they do not hardcode nav IDs  
- **No stock UIs** for sovereign paths — iframe/embed or native pad scripts only  

Retired names (never use with the board): Hub, Pad, Launchpad → **Pockit** only.

---

## Shell architecture

```text
PlayerShell (dual rail)
├── Player pills (nephew-tape, nephew-deck, …)
├── Cassette sidebar / tape rail
├── CassetteFrame (center canvas)
└── Footer version badge (pockit-surface.json)

Hosted pads: voice-pad.js, embed iframes, native CT routes
Suite bar: pockit-suite.js (Family Office app strip)
```

Boot: `make pockit` from nephew repo on operator Mac.  
Aliases: `make pad`, `make pocket` (same target).

---

## Living re-skin (catalogue → chrome)

Pockit is a **living interface** — not a static page per app:

```text
cassettes/product/*.json + data/cassette-catalogue.json
        ↓ discover / build
data/tape-door-registry.json  →  http://<id>.localhost/
        ↓ gateway Host routing
PlayerShell + PlayerTapeRail + CassetteFrame
        ↓ reads hosted_cassette_ids, nav, glyphs
Operator says: make bishop · make clinic · http://hello.localhost/
```

| Layer | What weaves in |
|---|---|
| **Catalogue** | `hosted_cassette_ids`, settings tabs, parent_console |
| **Door registry** | One hostname per cassette — operators never type ports |
| **Player shell** | Tape rail, overview grid, factory chrome (e.g. Bishop intention) |
| **Manifests** | `pockit-surface.json`, family-hub-cards — version badge + suite bar |

New cassettes **magnet onto the rail** when registered — no hand-wired button per tape.  
Operator command: **`make up <id>`** or console shorthand **`make bishop`**, not raw Vite URLs.

Plan 0196 (universal HUD / `pockit_hud=1` embed) extends this — see nephew `plans/0196-pockit-universal-hud-shell.md`.

---

## Non-vanilla chrome we shipped

| Feature | What it does |
|---|---|
| **Family Office suite bar** | Adobe CC–style top strip — jump Pockit, Control Tower, Automata, Historia, Voice without breaking rails |
| **CleanMyMac-style welcome** | First-run onboarding cards; `#/welcome`; dismiss persists; replay via Setup guide |
| **Cotton-ball Comet motion** | Entry animation — sneeze-out, soft overshoot, rest (RL-COTTON-001) |
| **Canonical door URLs** | Operators say `http://pockit.localhost/` — not gateway port numbers |
| **Changelog version badge** | Footer shows live pockit-surface version |
| **Sign-in gated suite** | Suite bar hidden until family auth |
| **Parakeet voice pad** | Full Goal 65 UX — viz, haptics, prefetch queue, route picker |
| **Jarvis Sovereign hub cassette** | Single door listing child surfaces, orchestra probes, Apple TCC layer, MCP bundle |
| **MindSpace 3D embed** | Child cassette under sovereign hub |
| **Native Pockit.app** | Swift macOS app — Po notification icon, not Script Editor applet |
| **Settings / substrate navigation** | Per-cassette settings from overview cards; gear opens Pockit Config |

---

## Cassette discipline (global)

| Term | Meaning |
|---|---|
| **Cassette** | Registry row — app, tape, or embed |
| **Player** | Host runtime that plays cassettes |
| **Console** | Player product with its own door (`pockit`, `wordpress`, `bishop`) |
| **Door** | `http://<id>.localhost/` |
| **Tape** | Cassette in `framework_roles: tape` |

Update ritual: operator says **“Update the Cassette”** → SOP + `make cassette-line CHECK=<id>`.

Key manifests live in nephew `data/` — catalogue, tape-endpoints, family-hub-cards.

---

## Jarvis Sovereign hub (browser stack map)

Door: **web-jarvis-sovereign.localhost** (after `make doors`)

Hub shows:

- Family door links (pretty URLs)  
- Orchestra doctor status artifact  
- Apple hands-on layers A–E  
- MCP bundle pointer  
- Child cassettes: MindSpace, vault/Quartz, hello  

Native richest path remains **Visual Obsidian** on mounted vault — not the browser alone.

---

## Control Tower vs Pockit

| Surface | Audience | Pattern |
|---|---|---|
| **Pockit** | Family grid, vanilla JS shell, voice pad | `containers/nephew-ct/family-hub/` |
| **Control Tower** | Operator React app, dustpan tri-rail | `apps/control-tower/` |

Both consume the **same cassette catalogue** — different host chrome.

---

## Visual / theme synthesis

- **Obsidian golden profile** — AnuPpuccin + `jarvis-sovereign.css` exported to git  
- **Ant Design / KVM comet themes** — WordPress Pockit theme mirrors family motion language  
- **Pockit surface schema** — cassettes publish `surface` blocks (nav, actions, theme_hints)  

---

## Agent rules for surfaces

1. Tell operators **door names** — canonical URL copy rule  
2. Boot with `make up <id>` / `make pockit` — not raw docker  
3. Map new apps to Pockit primitives before shipping UI  
4. Voice surfaces use **Jarvis** naming; wiki uses **Visual**  

---

## Related

- [05-nephew-orchestration.md](./05-nephew-orchestration.md) — CLOAK + taxonomy  
- [11-voice-parakeet-premium-stack.md](./11-voice-parakeet-premium-stack.md) — Parakeet pad  
- Nephew: `docs/product-stack-glossary.md`, `docs/pockit/Cassette-Surface-Taxonomy.md`, `docs/pockit/Pockit-App-Prototype.md`
