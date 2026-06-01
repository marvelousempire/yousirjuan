# Plan 0136 (nephew) / 0059 (dustpan) — Customs & Border Control: WG-separated inner/outer networks

**Status:** APPROVED — execution in progress (2026-06-01). Companion: `docs/whitepaper-hardware-network.md`.

## Context
The operator rebuilt the edge and stated the security model plainly: two separate network
"countries," chained by ethernet but trust-separated, where the only sanctioned crossing is a
WireGuard tunnel with a customs/border checkpoint on each side. The inner country (the Awe Engine /
DGX) must not share a broadcast domain with the modem.

**Confirmed topology** (live probes + operator): Verizon 5G → **AX1800** edge `192.168.0.1` (only box
on the modem) → **AX6000** internal `192.168.8.1` (double-NAT) → **DGX `192.168.8.249`** (deepest).
Inner WG mesh `10.1.0.0/24` (hub `.1`, Mac `.4`, DGX `.5`) is **live**. **Two AirPort Extremes**, both
inside, wired together, one feeding the **UGreen NAS**. Public `97.164.202.176` is **CGNAT** → no
internet-inbound (internal border is immune since it rides the eth link).

**Security finding (verified):** Ollama on the DGX listens `*:11434` unauthenticated, LAN-wide.
Inner-country sealing closes this.

## Tasks (precise)

### Phase 0 — Documentation FIRST (done)
- 0a. Probe real specs (DGX SSH; Mac `system_profiler`) — ✅ done.
- 0b. `docs/whitepaper-hardware-network.md` in **nephew** + **yousirjuan** — ✅ done.
- 0c. This plan in **nephew/plans/0136** (+ dustpan/yousirjuan copies) — in progress.
- 0d. Commit + push each repo.

### Phase A — Border posts (operator GUI; I supply exact values + verify)
1. **Back up both routers** (Administration → Save Setting → export `.CFG`) — the revert path. *(operator)*
2. **AX1800 (outer):** confirm Router mode, WAN = 5G modem, LAN `192.168.0.1/24`; enable **WG server
   `10.10.0.1/24:51820`**, generate keys. *(operator GUI; I give the exact config)*
3. **AX6000 (inner):** confirm the existing **WG server `10.1.0.0/24:51821`** — reuse, no change to
   existing peers (Mac `10.1.0.4`, DGX `10.1.0.5`). *(verify only)*
4. **Border tunnel:** add a WG peer so **AX6000 ⇄ AX1800** peer over the eth link on **transit
   `10.255.255.0/30`**; each peer's `AllowedIPs` = the other's LAN + WG subnets; AX6000 dials
   `192.168.0.1:51820` (local → CGNAT-immune). *(operator GUI; I give configs)*

### Phase B — Customs (firewall = border control)
5. Per-side policy: **Outer→Inner deny-by-default + narrow allowlist** for the Awe Engine API;
   **Inner→Outer controlled egress**. ASUS stock firewall is coarse — **recommend Merlin firmware**
   on the enforcing router for real per-flow iptables customs. *(operator decision; I supply rules)*

### Phase C — Seal the Awe Engine APIs to the inner country (I do, over SSH)
6. **DustPan agent** — already token-gated on `0.0.0.0:8765`; confirm reachable only inside + across
   customs (no code change).
7. **Ollama** — stop exposing on `0.0.0.0`. Enumerate current `:11434` consumers first, then bind to
   the inner address (`OLLAMA_HOST=192.168.8.249` or the inner-WG IP) + rely on the AX6000/customs
   firewall so `:11434` is inner-only.

### Phase D — Client + cockpit (I do)
8. Mac stays an inner-WG peer (`utun8/10.1.0.4`) to reach the Awe Engine + cockpit.
9. **Cockpit fixes:** add the DGX inner address to Control Tower `vite.config.ts allowedHosts`; fix
   the stale `dustpan-clinic 10.0.0.5` in `data/agent-endpoints.json`; restart CT.

### Phase E — Ship
10. Land repeatable parts in dustpan (`scripts/stack/border-wg-client.sh`; teach `dustpan expose` to
    label inner vs outer WG) + doc `docs/border-control-wg.md`. Bump/changelog/PR per repo;
    cross-repo sync audit.

## Critical files
- **Routers (no repo):** AX1800 WG server + LAN; AX6000 WG (reuse) + border peer; firewall customs on both.
- **nephew:** `apps/control-tower/vite.config.ts` (allowedHosts), `data/agent-endpoints.json`, `docs/whitepaper-hardware-network.md`, `plans/0136-…md`.
- **dustpan:** `scripts/stack/border-wg-client.sh` (new), `docs/border-control-wg.md` (new), `web/cli.py` (inner/outer WG label), `plans/0059-…md`.
- **DGX host:** Ollama service env (`OLLAMA_HOST`).

## Verification (layered; each gates the next)
1. **Border up:** from the AX6000, `ping 10.255.255.1` (AX1800 transit) succeeds; `wg show` on each router shows a recent handshake + bytes both ways.
2. **Customs enforced (the proof):** from an outer-WG client → the Awe Engine API reachable only on allowlisted port(s), all else denied; from inner, API works + egress follows the controlled-egress rule.
3. **Inner sealed:** from the outer `192.168.0.x` LAN **without** crossing the WG → DGX `:8765/:11434` must FAIL (separate countries, no flat route).
4. **CGNAT acknowledged:** internal border works regardless; internet-inbound to the outer post stays blocked until a relay is added (out of scope v1).
5. **Cockpit:** Mac on inner WG opens `http://192.168.8.249:5174` → CT loads, DGX disks live; existing inner-mesh peers unchanged.

## Out of scope (v1)
- Internet-inbound remote access (needs a cloud relay — later).
- Restoring clinic-vps DustPan.
- Touching the search/bank/nephew public edge (Plan 0134) or the DGX IdP keys.

## Reversibility
- Routers: `.CFG` backups before any change; revert = restore the export.
- Ollama: env change only — revert `OLLAMA_HOST` and restart.
- Cockpit: config/data edits, git-tracked.
- Each phase is independently revertable; the inner mesh (existing peers) is never modified.
