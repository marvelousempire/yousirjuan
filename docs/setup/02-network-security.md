# Chapter 2 — Network & Security Model

**Public-safe:** architecture and rules only. No subnet octets, port lists, peer tables, keys, or domain names.

---

## The Family Office Sandwich

One **public, gated edge**; everything else **private on the WireGuard mesh**.

| Layer | Behavior |
|---|---|
| **Public edge** | Single VPS-facing HTTPS entry (Caddy/nginx). Auth + TLS at the door. |
| **WireGuard mesh** | Encrypted overlay connecting VPS, DGX, router, and every trusted Mac/phone |
| **Internal services** | Bind **loopback + WireGuard interface only** — never the open LAN |
| **LAN** | Closed for internal cassette ports by design (Plan 0180 hardening) |
| **Doors** | Human-friendly hostnames route through a local gateway on the operator Mac |

**Why:** port secrecy is not security. Locks are **auth + network edge + WireGuard membership**, not hiding port numbers.

---

## WireGuard mesh (conceptual)

```text
[Laptop / iPad / Phone]
        │
   Slate AX (travel) or home Wi-Fi
        │
   WireGuard tunnel
        │
   Flint 2 (home gateway) ── VPS peer ── Public internet
        │
   Trusted LAN (segmented)
        ├── DGX Spark (compute)
        ├── NAS (storage)
        ├── Mac fleet (orchestration)
        └── IoT / Guest (isolated VLANs)
```

Every trusted device is a **mesh peer**. Off-LAN access requires an active tunnel — there is no direct LAN exposure of internal AI services.

---

## VLAN segmentation (target)

| Zone | Purpose | Access |
|---|---|---|
| **Trusted** | DGX, Macs, NAS, AI workloads | Full internal mesh access when peered |
| **IoT** | Smart home, cameras, speakers | Internet only; **blocked from Trusted** |
| **Guest** | Visitors | Internet only; **blocked from Trusted and IoT** |

Firewall order: **deny cross-zone first**, then allow controlled Trusted → IoT for operator control.

---

## Service bind model (Plan 0180)

| Bind target | Meaning |
|---|---|
| **Loopback** | Service reachable only on the host itself |
| **WireGuard interface** | Service reachable by mesh peers, not Wi-Fi clients |
| **Docker internal network** | Container-to-container (Qdrant, Synapse, etc.) — independent of published binds |
| **Public edge container** | The **one** intentionally wide-facing service on the VPS/DGX edge stack |

**Agent rule:** never re-add `0.0.0.0` publishes when editing composes. Edit **git-tracked** compose files (`deploy/dgx/`, `deploy/gitea/`, `containers/`, `docker-compose.dgx.yml`) — not live box-only edits.

---

## Reaching a service (operator vocabulary)

| Method | When |
|---|---|
| **Door name** | Preferred on operator Mac after doors bootstrap — `http://<cassette-id>.localhost/` |
| **Mesh direct** | From a WireGuard peer to the compute node's WG address |
| **Public apex** | Family-facing HTTPS through the gated edge |
| **SSH tunnel** | Fallback when mesh or IPv6 path unavailable |

Doors are implemented by the **family tape gateway** (`family-tape-gateway.mjs` in the nephew repo), which routes by hostname to the correct cassette backend.

---

## Git & SSH on the mesh

- All repos use **SSH remotes** to GitHub (no token expiry on push).
- A **self-hosted Gitea forge** on the DGX holds working copies; NAS stores git objects; GitHub is the **offsite mirror**.
- Direct push to the forge bypasses PR gates; GitHub `main` stays protected.

---

## DNS & TLS (conceptual)

- Public family domains terminate TLS at the edge.
- Internal doors use `.localhost` hostnames resolved by the gateway (operator Mac).
- DDNS on the home router gives stable hostname for off-LAN WireGuard endpoints (details in private ledger runbooks).

---

## Security layers (defense in depth)

| Layer | Control |
|---|---|
| Network | WireGuard mesh, VLAN isolation, closed LAN binds |
| Edge | TLS, auth gates, rate limits |
| Host | fail2ban, iptables/nftables, non-root services where possible |
| App | Bearer auth on APIs, OIDC where integrated |
| Git | Secret hygiene — `.gitignore`, pre-commit/push gitleaks hooks |
| Agent | CLOAK preflight (PII/secrets patrol before write/deploy) |

---

## IPv6 / dual-interface note (DGX)

The DGX may present both wired and wireless interfaces on the same subnet, causing asymmetric IPv4 routing. Production access paths:

- **IPv6 hostname alias** for LAN browser/SSH to the Spark
- **WireGuard** for remote access
- Do not fight broken IPv4 paths — use the documented production path

Details in operator runbooks (private).

---

## Onboarding a new Mac (checklist)

1. Join the **WireGuard mesh** (required for any internal service).
2. Load SSH keys into the macOS keychain; configure GitHub + forge host blocks in `~/.ssh/config`.
3. Clone `nephew` and sibling repos to the standard developer path.
4. Drop `.env` files beside composes (gitignored; use `.env.example` templates).
5. Run doors bootstrap for clean `.localhost` URLs.
6. Verify forge and a sample cassette door in the browser.

---

## Related

- [01-hardware.md](./01-hardware.md) — machine roles
- [03-software-services.md](./03-software-services.md) — what binds where
- [07-git-and-deploy.md](./07-git-and-deploy.md) — forge + dual-push
- Private: `ledger/LEDGER-0026-vps-into-wg-mesh/`, `ledger/LEDGER-0018-tailscale-to-wireguard-migration/`
