# LEDGER-0037 — Spark LAN + Gitea wiring (WireGuard path down)

**Status:** ACTIVE — until further notice (opened 2026-07-02)  
**Operator note:** fivemac reached Gitea on Spark over **home LAN**; WireGuard `10.1.0.5` git/HTTP paths are **down** from this Mac.

## Current truth

| Path | Status | Use when |
|------|--------|----------|
| **Spark SSH (LAN)** | `abrownsanta@192.168.10.205` | Always on home LAN |
| **Gitea HTTP API (LAN)** | `http://192.168.10.205:3300/api/v1/version` | Operator confirmed on LAN |
| **Gitea git (LAN)** | `git@gitea-spark-lan:marvelousempire/<repo>.git` | SSH `ProxyCommand` → Spark `127.0.0.1:2424` |
| **WireGuard `10.1.0.5:2424`** | **DOWN** from fivemac | Do not rely until WG restored |
| **WireGuard `10.1.0.5:3300`** | **DOWN** from fivemac | Do not rely until WG restored |
| **SSH `nephew-spark` / `dgx`** | WG-only (`10.1.0.5`) | Remote / mesh when WG up |

On Spark, Gitea binds `127.0.0.1:2424` + `10.1.0.5:2424` (and HTTP `3300` similarly). From fivemac on LAN, **git push uses the proxy alias**, not direct `192.168.10.205:2424`.

## SSH aliases (`~/.ssh/config`)

```
Host nephew-spark-lan spark-lan dgx-spark-lan 192.168.10.205
Host gitea-spark-lan gitea-lan   # ProxyCommand → nephew-spark-lan → 127.0.0.1:2424
```

Legacy WG aliases (`gitea-dgx`, `nephew-spark`) stay for when mesh returns.

## Verify

```bash
# Spark shell
ssh nephew-spark-lan 'hostname && curl -sS -m 5 http://127.0.0.1:3300/api/v1/version'

# Gitea git auth (no shell — expect "Hi there, avery!")
ssh -p 2424 git@gitea-spark-lan

# LAN HTTP (when published on 192.168.10.205)
curl -sS -m 8 http://192.168.10.205:3300/api/v1/version
```

## Git push (marvelousempire repos)

```bash
# One-time remote (or use URL directly):
git remote add gitea-lan gitea-spark-lan:marvelousempire/search-my-engine.git
git push gitea-lan main

# Or without adding a remote:
git push gitea-spark-lan:marvelousempire/nephew.git fix/office-door-stays-local
```

## Related

- `hardware/dgx-spark-frontier-node.md` — Spark role in the mesh
- `search-my-engine/docs/ci-contract.md` — Gitea Verify ship gate
- Clinic / SME door docs — operator browser sign-off still required after script green

## Revoke

When WireGuard `10.1.0.5` is stable from fivemac again: update this ledger status to **SUPERSEDED**, restore `gitea-dgx` as default `origin` for SME/nephew, and note the date in `journal.md`.