# PAIN-0014 — Gitea git store on NFS: active storage-layer incident

**First seen:** 2026-07-01  
**Status:** **unresolved** — operator / NAS / sudo territory; do not chmod-from-DGX as a cure

---

## Symptom

- Gitea `git push` fails: `Permission denied` creating `refs/heads/<branch>.lock`
- Bare repos show structural dirs at **mode 555**; count **spreads** (e.g. 17 → 96 repos in minutes)
- Repo at **mode 777** still denies writes to the git user — signature of **NFS-layer** denial, not local `chmod`
- Forge branch pushes rejected: `cannot lock ref` / `Permission denied` on Gitea refs
- May coincide with DGX **95% RAM / 100% swap** and zombie processes (compounding factor)

## Diagnose (read-only on DGX)

```bash
mount | grep nas-docker
# expect: 192.168.10.119:/volume1/docker on /mnt/nas-docker type nfs ...

find /mnt/nas-docker/gitea/git/repositories -maxdepth 2 -type d -perm 555 2>/dev/null | wc -l

# NAS space is NOT the driver when df shows TB free — check export/squash/client first
df -h /mnt/nas-docker
free -h   # memory pressure → NFSv3 stale attrs / failed ops
```

## Root cause (2026-07-01 — operator-verified)

Gitea's git object store is on **NFSv3** from Synology:

```text
/mnt/nas-docker/gitea/git  ←  192.168.10.119:/volume1/docker  (NFSv3, sec=sys, hard)
```

Failures are **NFS-permission-level**, not fixable by client-side `chmod u+w` alone:

1. **Synology export state** — squash / UID-mapping / export permission change → writes denied even at 777; 555 modes spreading across repos is classic NFS attribute/squash degradation, not a one-time root-owned object stray.
2. **DGX memory pressure** — under swap peg + zombies, the NFSv3 client can return **stale attributes** and fail ops; looks identical to permission errors.

**What does NOT fix it:** `chmod` / `chown` from the DGX client (symptom-patch — writes back over NFS and won't hold if export or client is degrading).

**Nephew perm-guard** (`deploy/gitea/gitea-perm-guard.sh`) only helps the *narrow* case of root-owned loose objects on an **otherwise healthy** NFS mount — not an active export/client incident.

## Fix (Boss Moves — operator / NAS)

1. **Stabilize DGX first** — relieve memory/swap (see PAIN-0013 / ch.31 §9) so NFS client isn't failing ops under pressure.
2. **Synology DSM** — audit NFS export for `volume1/docker`:
   - Squash / anonymous mapping (must allow `abrownsanta` / uid 1000 writes)
   - Export permission vs client IP (DGX LAN address)
   - NFS service health, connection count, kernel logs on NAS
3. **Remount test** (sudo on DGX, maintenance window): `umount` / `mount` `/mnt/nas-docker` after export fix — verify `touch` + `git push` on a test repo.
4. **Do not** treat rising 555 count as "run perm-guard harder" — that's masking storage-layer failure.

## Prevention (structural — post-incident)

- SQLite DB stays **local** on Gitea container; git objects on NAS per `deploy/gitea/docker-compose.nas.yml` — revisit Plan 0197 migration assumptions when NFS is unstable.
- Monitor: 555-repo count + NFS `dmesg` on DGX + Synology NFS connection logs.
- Memory governance (ch.31 §9) — NFS client health correlates with box headroom.

## Related

- PAIN-0013 (memory triple-stack — compounding)
- Nephew `deploy/gitea/gitea-perm-guard.sh` (symptom guard only)
- `docs/setup/18-wireguard-matrix-nas-gitea-why.md` · Plan 0197 NAS docker migration
- Clinic case **8897** (this incident — active NFS degradation)
- Nephew perm-guard (2026-06-30) — ownership strays on **healthy** NFS only; not a substitute for 8897