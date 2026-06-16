# Chapter 22 — Doc Era Reconciliation (Stale Branches & Whitepapers)

**Public-safe:** which topology docs are **live truth** vs **superseded planning**.

---

## Chapter intents

| Intent | Why |
|---|---|
| **One live topology** | Operators and agents must not follow conflicting network maps |
| **Branch hygiene** | Merged or stale branches get deleted — Gitea `main` is master |
| **Enterprise agent safety** | GitHub-only agents may reference old whitepapers — this chapter redirects |

---

## Live ground truth (use these)

| Topic | Canonical doc | Verified |
|---|---|---|
| **Physical cabling + `.10` LAN** | [13-physical-topology-protectli.md](./13-physical-topology-protectli.md) | 2026-06-15 hardware audit |
| **Mesh + bind model** | [02-network-security.md](./02-network-security.md), [18-wireguard-matrix-nas-gitea-why.md](./18-wireguard-matrix-nas-gitea-why.md) | Plan 0180 |
| **Doors + Pockit** | [15-doors-cassettes-pockit-navigation.md](./15-doors-cassettes-pockit-navigation.md) | `make doors` |
| **Full microscopic network** | [`home-network-full-architecture-report.md`](../home-network-full-architecture-report.md) | Same era as ch. 13 |

**Live model (Jun 2026):** Verizon passthrough → **GL-MT6000** (`192.168.10.1`) → flat `192.168.10.0/24`. DGX `.205`, NAS `.119`, 10GbE direct link. **Protectli VP6670** is the migration target for OPNsense + VLANs.

---

## Superseded / do not merge blindly

| Source | Why stale | Action |
|---|---|---|
| Branch `plan/border-control-wg` → `docs/whitepaper-hardware-network.md` | Describes **AX1800 outer / AX6000 inner** “two countries” model — **not** the live flat `.10` MT6000 layout | **Deleted** — content preserved in git history only |
| Older `.8.x` LAN references | Pre-migration addressing | Ignore unless reconciling with ch. 13 |
| Brume-split “AI island” whitepaper | Target architecture — conflicts with live MT6000-flat | Track in Historia; do not treat as live |

---

## Deleted branches (2026-06-16 sync)

| Branch | Reason |
|---|---|
| `docs/operator-setup-master-guide` | Merged into `main`; was wrongly set as Gitea default for `avery/yousirjuan` |
| `voice-security-audit-2026-06` | Merged into `main` at `8e470bc` (enterprise audit ch. 00/19–21/24) |
| `plan/border-control-wg` | Superseded by ch. 13 — whitepaper conflict |

Enterprise agents: **branch from `main` only** on GitHub; operator merges to **Gitea `main`** before treating work as live.

---

## Related

- [README.md](./README.md) — Gitea master / GitHub mirror discipline
- [13-physical-topology-protectli.md](./13-physical-topology-protectli.md)
