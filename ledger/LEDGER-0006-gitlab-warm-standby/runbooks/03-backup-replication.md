# Runbook 03 — Backup replication (VPS → iMac, nightly)

**Time:** ~2 min for VPS backup + ~1 min for sync (small repo set) + ~5 min for restore
**Reversible:** yes (uninstall launchd agents + remove `/etc/cron.d/gitlab-nightly-backup` on VPS)
**Prereqs:** runbook 02 complete (standby container running)

## The three-stage nightly cycle

```
03:00 ET / 07:00 UTC   VPS cron creates backup
                       → /opt/gitlab/data/backups/<timestamp>_gitlab_backup.tar
                       (script: /usr/local/bin/gitlab-nightly-backup.sh)

04:00 ET / 08:00 UTC   iMac launchd: rsync VPS backup dir → iMac
                       → ~/Library/GitLab-Data/data/backups/
                       (LaunchAgent: com.yousirjuan.gitlab-standby-sync)

05:00 ET / 09:00 UTC   iMac launchd: restore latest backup into standby container
                       (gitlab-backup restore force=yes; reconfigure; restart)
                       (LaunchAgent: com.yousirjuan.gitlab-standby-restore)
```

After this cycle, the standby has data no more than ~24 h old (since the last VPS backup).

## What's already configured

This work was done in the install playbook + during LEDGER-0006 shipping:

**On the VPS:**
- `/usr/local/bin/gitlab-nightly-backup.sh` — wrapper script that calls `docker exec gitlab gitlab-backup create CRON=1 STRATEGY=copy SKIP=registry` + prunes backups older than 7 days.
- `/etc/cron.d/gitlab-nightly-backup` — `0 7 * * * root /usr/local/bin/gitlab-nightly-backup.sh`.
- `/var/log/gitlab-nightly-backup.log` — appended on each run.

**On the iMac:**
- `~/Library/LaunchAgents/com.yousirjuan.gitlab-standby-sync.plist` — pulls VPS backups via rsync at 08:00 UTC.
- `~/Library/LaunchAgents/com.yousirjuan.gitlab-standby-restore.plist` — restores latest backup at 09:00 UTC.
- `~/Library/Logs/gitlab-standby-{sync,restore}.log` — appended on each run.

## Manual triggers (out of schedule)

To force a sync or restore right now (useful for first-time hydration):

```bash
# Pull latest backup from VPS immediately:
bash ~/Developer/yousirjuan/ledger/LEDGER-0006-gitlab-warm-standby/playbooks/install-standby.sh trigger-sync

# Restore latest backup into standby immediately (DESTRUCTIVE on standby):
bash ~/Developer/yousirjuan/ledger/LEDGER-0006-gitlab-warm-standby/playbooks/install-standby.sh trigger-restore
```

Each writes its log file under `~/Library/Logs/gitlab-standby-{sync,restore}.log`.

## Success criteria

After at least one successful full cycle:

1. `ls -lh ~/Library/GitLab-Data/data/backups/` shows a recent `*_gitlab_backup.tar`.
2. `git clone http://imac-avery.tailaa31dd.ts.net:8929/marvelousempire/yousirjuan.git /tmp/standby-test` succeeds.
3. The cloned repo's HEAD matches the VPS primary's HEAD (modulo a 24 h staleness window).
4. `tail -20 ~/Library/Logs/gitlab-standby-restore.log` ends with `restore complete`.

## Common failures and fixes

| Symptom | Likely cause | Fix |
|---|---|---|
| sync log: `Connection refused` on port 2222 | iMac can't reach VPS (rare) or VPS SSH is down | Check `ssh vps-godaddy 'echo ok'` works manually; if not, see LEDGER-0003 runbook 04 |
| sync log: `permission denied (publickey)` | iMac SSH key not on VPS | Add `~/.ssh/id_ed25519.pub` to `abrownsanta@vps:~/.ssh/authorized_keys` |
| restore log: `error: backup version mismatch` | Standby's GitLab version differs from backup's GitLab version | Update standby's image digest to match VPS (edit `~/Developer/gitlab-standby/docker-compose.yml`) |
| restore log: `Database 'gitlabhq_production' already exists` | Restore reusing a half-restored state | `docker exec gitlab-standby gitlab-rake db:drop:all` then re-trigger restore |
| latest-backup line in status is days old | Either the VPS cron isn't running or the sync isn't running | Check `/var/log/gitlab-nightly-backup.log` on VPS + `~/Library/Logs/gitlab-standby-sync.log` on iMac |

## Notes

- **The restore is DESTRUCTIVE** on the standby. That's the intent. The standby is supposed to mirror primary exactly; don't expect ad-hoc commits on standby to survive.
- **Backup size grows with repo count**, but the per-repo overhead is small. The 927 MB initial backup (May 2026) covers the yousirjuan repo's full git history + DB rows for users, projects, MRs, etc. As more repos land on primary, the backup grows; rsync's incremental nature helps but tarballs aren't deltas, so each daily transfer is the full new tarball.
- **`SKIP=registry`** in the backup command means container-registry artifacts aren't included. The yousirjuan VPS doesn't use the registry currently; if it ever does, drop the SKIP and accept the larger backup.
- **`STRATEGY=copy`** means GitLab copies repos before tarring, which means the live repos aren't locked during backup. Slower than the default but doesn't impact users.

## Undo

```bash
# On iMac (stop the launchd jobs but keep them on disk):
launchctl unload ~/Library/LaunchAgents/com.yousirjuan.gitlab-standby-sync.plist
launchctl unload ~/Library/LaunchAgents/com.yousirjuan.gitlab-standby-restore.plist

# On VPS (remove the cron entry):
ssh vps-godaddy 'sudo rm /etc/cron.d/gitlab-nightly-backup'
```

## Related

- [01-prereqs-on-imac.md](01-prereqs-on-imac.md), [02-deploy-standby-container.md](02-deploy-standby-container.md)
- Future: `04-promotion-playbook.md` — separate ledger entry; for when VPS dies and standby has to take over.
