# LEDGER-0024 — Dual-Push Drift Prevention (server-side sync + drift detector)

**Status**: planning
**Opened**: 2026-05-22
**Owner**: Avery
**Replaces silent failures with**: scheduled mirror + visible drift report

## Origin

Today's reorg (LEDGER-0023) surfaced two pre-existing divergences:

1. `dustpan` main — GitHub `3055c66` vs GitLab `23350e1` (different content + different SHAs for shared work)
2. `ai-skills-library` main — origin 15 ahead of gitlab, gitlab 13 ahead of origin (different SHAs for the same content via squash-merge mismatch)

Both required manual cherry-picks + force-pushes to align. Operator asked: *"is this future-proof?"* Answer: no, the prevention rules (Universal Rule 14 + `tools/git-dual-push.sh`) only work if every push goes through the dual-push tool, which agents and humans both forget. The divergence happens silently in two failure modes:

1. **Local push via bare `git push`** instead of `dual-push.sh` — only updates one remote.
2. **`gh pr merge` on GitHub** — server-side merge that never touches a local terminal, so the dual-push tool can't run. The post-merge sync step (`git fetch origin && bash tools/git-dual-push.sh main`) is manual discipline and often skipped.

## Why a server-side cron instead of GitHub Actions or GitLab pull-mirror

| Option | Cost | Catches `gh pr merge` | Decision |
|---|---|---|---|
| GitHub Actions workflow per repo | ~2,100 GH minutes/month at the marvelous-empire scale — right at the Free cap | Yes | Rejected — uncomfortably close to billing cap |
| GitLab pull mirror | Free | Yes | Rejected — pull mirror is a GitLab **Premium** feature, not in CE Free |
| **Server-side cron on VPS** (this LEDGER) | Free | Yes | **Chosen** — runs as a systemd timer where SSH + git CLI already exist. Uses `-s ours` merge-commits (plumbing) rather than force-push, so it works with GitLab's branch-protected `main`. |
| Pre-push git hook | Free | No (server-side merges bypass it) | Insufficient on its own |

## Architecture

```
                   ┌─────────────────────────────────────────────────────┐
                   │              VPS (vps-godaddy)                       │
                   │                                                       │
                   │   ┌──────────────────────────────────────────────┐   │
                   │   │  yousirjuan-dual-push-sync.timer              │   │
                   │   │  (systemd, runs every 5 minutes)              │   │
                   │   │       ↓                                       │   │
                   │   │  yousirjuan-dual-push-sync.service            │   │
                   │   │       ↓                                       │   │
                   │   │  /opt/yousirjuan-sync/sync-and-drift.sh       │   │
                   │   │       ├─ For each tracked repo:               │   │
                   │   │       │    1. git fetch origin (GitHub)       │   │
                   │   │       │    2. git fetch gitlab (local SSH)    │   │
                   │   │       │    3. If origin/main != gitlab/main:  │   │
                   │   │       │         a. Append to drift report     │   │
                   │   │       │         b. git push gitlab origin/main:main \│
                   │   │       │              --force-with-lease       │   │
                   │   │       │         c. Log success/failure        │   │
                   │   │       └─ Write JSON report                    │   │
                   │   │              /var/lib/yousirjuan/             │   │
                   │   │              dual-push-drift-report.json      │   │
                   │   └──────────────────────────────────────────────┘   │
                   │                       ↓                               │
                   │   ┌──────────────────────────────────────────────┐   │
                   │   │  /system /history /intent-drift ... agents    │   │
                   │   │       + NEW /dual-push-drift endpoint         │   │
                   │   │  (in vps-agent-server.sh — LEDGER-0012)       │   │
                   │   └──────────────────────────────────────────────┘   │
                   └─────────────────────────────────────────────────────┘
                                              ↓
                              ┌──────────────────────────┐
                              │  DustPan settings panel  │
                              │  + Nephew tower card     │
                              │  (Phase 2 — separate PR) │
                              └──────────────────────────┘
```

## Critical files

### On VPS (new)

- `/opt/yousirjuan-sync/sync-and-drift.sh` — the periodic mirror + drift detector
- `/opt/yousirjuan-sync/tracked-repos.txt` — list of repos to sync (mirrors `~/Developer/` minus archived ones)
- `/etc/systemd/system/yousirjuan-dual-push-sync.service` — systemd unit
- `/etc/systemd/system/yousirjuan-dual-push-sync.timer` — every 5 minutes
- `/var/lib/yousirjuan/dual-push-drift-report.json` — written by the script

### In yousirjuan repo (new)

- `ledger/LEDGER-0024-dual-push-drift-prevention/playbooks/sync-and-drift.sh` — script source (deployed to VPS)
- `ledger/LEDGER-0024-dual-push-drift-prevention/playbooks/install.sh` — idempotent installer
- `ledger/LEDGER-0024-dual-push-drift-prevention/artifacts/*.service|*.timer` — systemd units
- `ledger/LEDGER-0024-dual-push-drift-prevention/artifacts/tracked-repos.txt` — initial repo list
- `ledger/LEDGER-0024-dual-push-drift-prevention/runbooks/01-install.md` — operator one-liner
- `ledger/LEDGER-0024-dual-push-drift-prevention/runbooks/02-add-a-repo.md` — extending the tracked list
- `ledger/LEDGER-0024-dual-push-drift-prevention/runbooks/03-investigate-a-drift.md` — what to do when the report flags one

### In yousirjuan vps-agent-server (modify — Phase 2)

- `ledger/LEDGER-0012-vps-observability-control/playbooks/vps-agent-server.sh` — add `/dual-push-drift` GET endpoint that returns the JSON report
- DustPan panel (separate PR) consumes the endpoint

## Auth model on VPS

The sync script needs:
1. **Read access to GitHub repos** — gh CLI auth or a deploy SSH key with read access to marvelousempire org. The cleanest is: configure the VPS user with an SSH key that's in the marvelousempire account's "Authorized keys" list (read-only or read+write).
2. **Write access to GitLab** — already exists; the VPS IS the GitLab server, so local SSH key (or a service account) has full push access.

Operator decision needed before install:
- Use existing `marvelousempire` SSH key on VPS, OR generate a dedicated `yousirjuan-sync@vps-godaddy` deploy key for this script alone (more auditable). Defaults to the dedicated deploy key.

## Repo list (initial)

All 83 marvelous-empire leaves + 8 wrapper monorepos + ai-skills-library + contribution-network-private = ~93 repos. Sync runs in parallel batches of 5 to avoid hammering GitHub.

Script reads from `tracked-repos.txt` — one per line, can be edited by operator without touching the script.

Excluded by default:
- `scene-scout` (archived)
- `dotclaude` (archived)
- Any fork (their canonical home is the upstream)

## Reversibility

- Disable timer: `sudo systemctl disable --now yousirjuan-dual-push-sync.timer`
- Remove: `sudo bash playbooks/install.sh uninstall` (removes timer, service, /opt/yousirjuan-sync, leaves drift report intact for forensics)
- Worst-case force-push damage: bounded — `--force-with-lease` aborts if the gitlab head moved since fetch, so a concurrent legitimate push can't be silently overwritten

## What this does NOT do

- Does NOT install on local Mac. The sync runs ONLY on the VPS. Local pushes to GitHub still need `dual-push.sh` for immediate mirror; this is the safety net for the cases that bypass it.
- Does NOT replace `dual-push.sh`. The tool stays the primary path; this catches the misses.
- Does NOT enforce Universal Rule 14. The rule still requires agent/human discipline.

## Verification

```bash
# 1. After install, timer is active
sudo systemctl list-timers yousirjuan-dual-push-sync.timer | grep yousirjuan

# 2. First manual run produces a clean report
sudo /opt/yousirjuan-sync/sync-and-drift.sh
cat /var/lib/yousirjuan/dual-push-drift-report.json | python3 -m json.tool | head -30

# 3. Induced drift gets detected and auto-fixed within 5 min
#    On laptop: cd ~/Developer/<test-repo> && git commit --allow-empty -m "test" && git push origin main
#    Wait 5 min
#    On VPS: tail -20 /var/log/yousirjuan-sync.log

# 4. /dual-push-drift endpoint returns JSON (Phase 2)
curl -s http://vps-godaddy:9878/dual-push-drift | python3 -m json.tool | head -30
```

## Open follow-ups

- Phase 2: DustPan + Nephew tower cards reading the drift report — separate PRs
- Operator choice on auth model (shared SSH key vs dedicated deploy key) — see "Auth model" section
- Notification escalation if drift persists for >2 cycles — likely reuses LEDGER-0015 alert-watch
