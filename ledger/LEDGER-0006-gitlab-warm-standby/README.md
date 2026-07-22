---
ledgerId: LEDGER-0006
title: GitLab CE warm-standby on the iMac (VPS-primary, iMac-secondary)
status: in-progress
opened: 2026-05-20
closed: null
related-pains: []
related-tickets: [LEDGER-0005]
triggers:
  - manual-cli: `bash ledger/LEDGER-0006-gitlab-warm-standby/playbooks/install-standby.sh install`
  - launchd:nightly-08-00-utc (sync backup VPS → iMac)
  - launchd:nightly-09-00-utc (restore latest backup into standby)
---

# LEDGER-0006 — GitLab CE warm-standby on the iMac

> **SUPERSEDED — DO NOT REPLAY.** This GitLab/Tailscale standby design is retained as historical evidence. DGX Gitea is the canonical Family Forge and private transport is WireGuard only under RL-WIREGUARD-ONLY-001.

## Ask

> "is it possible to host the Gitlab from this computer instead of that VPS and still reach it remotely? Can I do that via the Settings panel in the Nephew Control Panel UI?"

Resolved scope (after planning + AskUserQuestion in same session): **VPS-primary / iMac-warm-standby**, not full migration. Long-term wants both running, with the iMac standing by to take over if VPS dies. iMac to be treated as always-on dedicated infrastructure (not a workstation that sleeps).

## Outcome (Phase 1B + 1C state)

Two GitLab CE instances:

| Role | Where | URL | Data |
|---|---|---|---|
| **Primary** | VPS (`72.167.151.251`) — already shipped in LEDGER-0005 | `https://git.yousirjuan.ai` + `https://clinic.yousirjuan.ai` + `ssh://…:2424` | `/opt/gitlab/data/` on VPS, backed up nightly to `/opt/gitlab/data/backups/` |
| **Standby** | iMac (`imac-avery` on tailnet) — provisioned here | `http://imac-avery.tailaa31dd.ts.net:8929` + `ssh://…:2424` (tailnet only) | `~/Library/GitLab-Data/` on iMac, hydrated nightly from VPS backups |

The standby's job is to be a **read-mostly mirror of primary, no more than 24 h stale.** It runs continuously but isn't advertised as primary. If the VPS dies, the operator runs a promotion playbook (Phase 3, not in this ledger entry) to make the iMac authoritative.

## Runbooks

- [01-prereqs-on-imac.md](runbooks/01-prereqs-on-imac.md) — operator-driven prep: OrbStack install, Tailscale re-auth, macOS Energy Saver "never sleep." Cannot be automated.
- [02-deploy-standby-container.md](runbooks/02-deploy-standby-container.md) — `bash playbooks/install-standby.sh install` walkthrough; what to expect on first boot.
- [03-backup-replication.md](runbooks/03-backup-replication.md) — VPS nightly backup cron + iMac sync + iMac restore launchd jobs.
- [04-promotion-playbook.md](runbooks/04-promotion-playbook.md) — **DEFERRED to a future ledger entry.** If VPS dies, here's the manual procedure to make iMac primary.

## Playbooks

- [install-standby.sh](playbooks/install-standby.sh) — idempotent installer. Actions: `install / uninstall / status / start / stop / trigger-sync / trigger-restore / help`. Logs to `~/yousirjuan-ledger.log`.

## Artifacts

- [docker-compose.yml](artifacts/docker-compose.yml) — canonical compose for the iMac standby. Image pinned to `gitlab/gitlab-ce:latest@sha256:c66669ef…` (same digest as VPS primary at 2026-05-20 — GitLab 18.11.3). Volume mounts under `~/Library/GitLab-Data/`.
- [com.yousirjuan.gitlab-standby-sync.plist](artifacts/com.yousirjuan.gitlab-standby-sync.plist) — LaunchAgent: rsync latest backup from VPS to iMac nightly at 08:00 UTC (04:00 EDT).
- [com.yousirjuan.gitlab-standby-restore.plist](artifacts/com.yousirjuan.gitlab-standby-restore.plist) — LaunchAgent: restore latest backup into the standby container nightly at 09:00 UTC. **DESTRUCTIVE on the standby by design** (overwrites with VPS state).

## Replay (zero-AI, after operator prereqs)

```bash
git clone https://github.com/marvelousempire/yousirjuan.git ~/Developer/yousirjuan && \
cd ~/Developer/yousirjuan && \
bash ledger/LEDGER-0006-gitlab-warm-standby/playbooks/install-standby.sh install && \
bash ledger/LEDGER-0006-gitlab-warm-standby/playbooks/install-standby.sh status
```

## Verification

After the install playbook runs:

```bash
bash ledger/LEDGER-0006-gitlab-warm-standby/playbooks/install-standby.sh status
```

…should show every section with ✓ (Docker present, Tailscale online, container running, HTTP responding, launchd agents loaded). Within 24h, the latest-backup line under standby should show a recent tarball.

End-to-end test once standby's data is restored:

```bash
git clone http://imac-avery.tailaa31dd.ts.net:8929/marvelousempire/yousirjuan.git /tmp/test-clone
diff <(git -C /tmp/test-clone log --oneline -10) \
     <(git -C ~/Developer/yousirjuan log --oneline origin/main -10)
# Should be empty diff (modulo 24h backup staleness window).
```

## Undo

```bash
bash ledger/LEDGER-0006-gitlab-warm-standby/playbooks/install-standby.sh uninstall
```

Container stops, launchd agents removed, plists deleted. **Data preserved** at `~/Library/GitLab-Data/` so re-install resumes. Delete manually if you want a clean wipe.

## What's already done (this session)

- ✅ VPS nightly backup cron installed at `/etc/cron.d/gitlab-nightly-backup` (runs 07:00 UTC daily).
- ✅ Initial VPS backup triggered + completed: `/opt/gitlab/data/backups/1779269804_2026_05_20_18.11.3_gitlab_backup.tar` (927 MB, took 2m 38s).
- ✅ All canonical artifacts in `artifacts/`.
- ✅ install-standby.sh playbook written + tested for `help`/`status` paths.

## What needs operator action before standby boots

- ❌ Install OrbStack: `brew install --cask orbstack` (or download from orbstack.dev). Requires admin password.
- ❌ Tailscale re-auth: open Tailscale.app, sign in. One-time OAuth click.
- ❌ macOS Energy Saver: System Settings → Battery → Options → never sleep + wake-for-network. Operator approves each toggle.

After those three, run the install playbook and the standby is up. After one nightly cycle (08:00 UTC sync + 09:00 UTC restore), data mirrors VPS.

## Notes

- **Image digest pin** is important. GitLab backup format is version-locked — a standby on a different version can fail to restore. Refresh the pin when VPS upgrades; do both at once.
- **Backup transfer (~1 GB/day) over home internet uplink** — incremental rsync helps but the first transfer is the full 927 MB. Acceptable.
- **Tailnet hostname** `imac-avery.tailaa31dd.ts.net` (per HANDOFF.md) — assumes Tailscale logged in. The compose's `external_url` uses it; if hostname differs after re-auth, edit `STANDBY_DIR/docker-compose.yml` accordingly.
- **Standby runs but is NOT advertised as primary.** Don't push to it directly. Don't bookmark it for daily work. It's a backup target, not a working repo.
- **Phase 3 (promotion playbook + UI button)** is deferred to a future ledger entry. For now, "the VPS died, what do I do?" is: stop the standby's nightly restore, point your DNS at the standby's tailnet IP (or set up a relay), update remote URLs in clones. Manual procedure documented in next session.

## Cross-references

- Builds on: [LEDGER-0005 — GitLab CE full source-of-truth (Phase 1 shipped)](../LEDGER-0005-gitlab-as-source-of-truth/)
- Referenced from: `apps/control-tower/src/pages/StatusPage.tsx` in `marvelousempire/nephew` (Phase 2 — add GitLabHostingCard, NOT in this ticket; separate PR after standby is live)
