# Runbook 05 — Incident postmortem: 2026-05-20 OOM cascade

The first real incident the watchdog (LEDGER-0007) was built to cover, captured live from the iMac via the watchdog log + SSH triage after recovery. Worth codifying because the trigger (`npm install` of a heavy package) is going to keep happening on this VPS until the underlying root cause is fixed.

## TL;DR

A user-initiated `npm install n8n` allocated 2.2 GB of RAM on a 7.8 GB VPS already running GitLab + Puma + Sidekiq + Gitaly + Cursor remote-server + n8n + Docker + a GitHub Actions runner + multiple Next.js dev servers. The OOM killer fired twice:

| Time (UTC, dmesg) | What | Killed by | What it killed |
|---|---|---|---|
| `12:39:14` | First OOM strike | `sshd` invoked oom-killer | `dbus-daemon` (PID 68058) |
| `13:22:55` | Second OOM strike (43 min later) | `tailscaled` invoked oom-killer | `npm install n8n` (PID 129290, 2.2 GB RSS) |

Between strikes, the kernel swap daemon (`kswapd0`) thrashed at 40%+ CPU. Userspace (sshd, nginx) was starved of CPU, so external probes saw TCP-accept + banner-timeout — the [runbook 04](04-vps-overload-triage.md) signature.

## Timeline (US Eastern)

| Time | Event | Source |
|---|---|---|
| ~07:30 | Earlier overload (Cursor remote-server `rg /` issue, separate). Killed manually. | session memory |
| ~08:39 | First OOM kill: sshd killed dbus-daemon | dmesg |
| ~09:00 | `apps/yousirjuan-web` build pipelines + GitHub Actions runner active | top |
| ~09:22 | `npm install n8n` started by some user/automation. RSS grows to 2.2 GB. | top, dmesg |
| ~09:22 | OOM kill #2: tailscaled killed `npm install n8n` | dmesg |
| ~09:23+ | kswapd thrash; sshd banner-timeout from external clients. iMac watchdog probes start failing. | local log |
| ~09:25 | Operator clicked **Boot into Rescue Mode** in GoDaddy panel | operator |
| ~09:25 | Soft reboot fired. **Rescue OS never actually booted** — GoDaddy panel UI stuck on "Booting into rescue mode…" but customer Ubuntu came up first on the recycled kernel | observation |
| ~09:28 | SSH on port 2222 accepts again | iMac watcher |
| ~09:29 | Operator + Claude session SSH'd in. Load: 1.87 / 68.63 / 150.28 — recovering. | this session |
| ~09:34 | Load: 0.54 / 23.18 / 105.53; swap dropped from 3.7 → 2.9 GB | session |

The "rescue mode click" was effectively a soft-reboot kludge — the GoDaddy panel attempted to swap the VM to a rescue image, but the customer-OS reboot resolved the wedge faster than the rescue image could come up. GoDaddy's UI is still showing the stale "Booting into rescue mode" banner an hour later (blocking access to Firewall / Settings panels).

## What we saw from the iMac watchdog

The LEDGER-0007 watchdog was installed in DRY_RUN ~5 min before the incident escalated. Its log captured the degradation:

```
[09:23] ✗ hello   (https://hello.yousirjuan.ai/)  fail=1  status=vps
[09:26] ✗ hello   fail=2
[09:26] ✗ workflow fail=3   ← already at strike threshold (legitimately down: n8n was the culprit)
[09:29] post-reboot — probes start passing again on subsequent ticks
```

This is exactly the behavior the watchdog is built for. The (dry-run) decision log would have been: `WOULD SWAP A record hello.yousirjuan.ai`. Real swap was correctly not executed because:

1. DRY_RUN=1 (correct default until Phase 2 standby containers exist)
2. No standby container exists for `hello` yet

## Root cause

Memory budget of the 7.8 GB VPS is fundamentally undersized for the current workload. Steady-state residents on the box right now:

| Process | Approx RSS |
|---|---|
| GitLab Sidekiq | ~770 MB |
| GitLab Puma worker 0 | ~600 MB |
| GitLab Puma worker 1 | ~550 MB |
| n8n | ~150 MB |
| GitLab Gitaly | ~90 MB |
| Postgres (GitLab embedded) | ~80 MB |
| Multiple `next-server` (Next.js dev) instances | ~100 MB each × N |
| Cursor remote-server (node + fileWatcher) | ~50 MB |
| GitHub Actions runner | up to 1 GB per active job |
| Docker daemon | ~50 MB |
| Tailscaled | ~30 MB |

This already lives close to the 7.8 GB ceiling. Any `npm install` of a tree the size of `n8n` (transitive deps include sharp, sqlite native bindings, etc.) is enough to trigger OOM.

## Lessons + prevention

### 1. Never `npm install` heavy packages directly on the VPS

Build artifacts on a build host (the iMac, a GitHub Actions runner with adequate memory, or DGX Spark). Deploy artifacts only. The VPS should not be a build environment.

If a one-off install is unavoidable, do it under a memory limit:

```bash
systemd-run --user --scope -p MemoryMax=500M npm install <pkg>
# Fails fast at 500 MB instead of OOM-cascading the whole box.
```

### 2. Cap GitLab Puma + Sidekiq with systemd MemoryHigh

`MemoryHigh` (soft) tells the kernel to throttle the unit before hitting OOM. Edit `/etc/gitlab/gitlab.rb`:

```ruby
puma['per_worker_max_memory_mb'] = 400         # currently default ~600
sidekiq['concurrency'] = 10                    # currently 20
```

Then `sudo gitlab-ctl reconfigure`. Trades throughput for headroom — fine for a full single-tenant install.

### 3. Earmark `oom_score_adj` for survival-critical processes

Currently sshd has `oom_score_adj=0` — same as every other process. That's why sshd was the FIRST process to invoke the killer (the kernel evaluates oom_score = RSS + oom_score_adj × 10; sshd is small but isn't immune).

```bash
# Set sshd to be effectively unkillable
echo -1000 | sudo tee /proc/$(pidof sshd | tr ' ' '\n' | head -1)/oom_score_adj
# Persist via systemd drop-in:
sudo systemctl edit ssh
# add:
#   [Service]
#   OOMScoreAdjust=-1000
```

### 4. Increase swap to 8 GB (currently 4 GB)

Swap thrash is bad, but **no swap at OOM time is worse**. Doubling swap gives the kernel more room to dehydrate idle pages from GitLab workers before killing.

```bash
sudo swapoff /swapfile
sudo dd if=/dev/zero of=/swapfile bs=1M count=8192
sudo chmod 600 /swapfile
sudo mkswap /swapfile && sudo swapon /swapfile
```

### 5. Add RAM upgrade to the roadmap

The proper fix is more RAM. The VPS appears to be ~8 GB; doubling to 16 GB would give GitLab room without cap-shrinking. Track as a Phase-3 prerequisite on this ledger; cost is one tier of GoDaddy VPS upgrade.

## Why the LEDGER-0007 watchdog being live in DRY_RUN was already valuable

- **Eyewitness log.** We have the exact moments hello/clinic/git went from UP → DOWN → UP, attestable.
- **Validation of the alert path.** The watchdog correctly distinguished workflow.yousirjuan.ai (n8n upstream genuinely 502) from a host-wide outage, exactly as designed.
- **Forced the diagnostic.** Without the watchdog ticking on the iMac, the operator might still be guessing whether the VPS was offline-offline or just slow.

## What we would have done differently if Phase 2 standby containers existed

When `hello` hit 3 consecutive fails, the watchdog (if `DRY_RUN=0`) would have:

1. Called GoDaddy DNS API: `hello.yousirjuan.ai A → FAILOVER_IP` (iMac Tailscale Funnel)
2. Traffic for `hello.yousirjuan.ai` would route to a standby nginx on the iMac serving the marketing pages from a recent build
3. ~3 ticks later (~9 min) after VPS recovered, watchdog would revert: `hello.yousirjuan.ai A → 72.167.151.251`

Users would have seen ~10 min of "site is on emergency backup" instead of "site is down." That's the Phase 2 target.

## Action items captured

| Item | Where | Owner | Status |
|---|---|---|---|
| Document this incident as runbook 05 | this file | done | shipped |
| Add `oom_score_adj=-1000` to sshd via systemd drop-in | VPS | operator | open |
| Add `per_worker_max_memory_mb=400` to gitlab.rb | VPS | operator | open |
| Double swap to 8 GB | VPS | operator | open |
| Build n8n + Next.js on iMac, deploy artifacts to VPS | apps/ | operator | open (LEDGER-TBD) |
| RAM upgrade tracking | GoDaddy VPS plan | operator | open |
| Phase 2 standby containers | LEDGER-0007 phase 2 | deferred | open |
| Investigate GoDaddy panel "Booting into rescue mode…" stuck UI | GoDaddy support | operator | open |

## Related

- [02-watchdog-design.md](02-watchdog-design.md) — the state machine that observed this.
- [03-enabling-real-swap.md](03-enabling-real-swap.md) — what would have happened in live mode.
- [04-vps-overload-triage.md](04-vps-overload-triage.md) — the diagnostic flow used during this incident.
