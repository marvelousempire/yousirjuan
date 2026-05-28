---
ledgerId: LEDGER-0011
title: VPS memory hardening — GitLab caps + sshd OOM protect + double swap
status: in-progress
opened: 2026-05-20
closed: null
related-pains: []
related-tickets: [LEDGER-0007]
triggers:
  - manual-ssh: operator runs apply-all.sh on the VPS once host is responsive
---

# LEDGER-0011 — VPS memory hardening

## Ask

> "Software caps first, RAM later" — operator decision 2026-05-20 after the second OOM-cascade of the day.

The recurring OOM cascade on the 8 GB / 4 vCPU VPS (TBS-SEPT25 plan) is documented in LEDGER-0007 runbook 05. Two events in 4 hours; GoDaddy panel history shows 5 restart/sync events in 2 hours. Operator wants software-side caps applied first, before changing hardware tier.

## Outcome

Three idempotent shell playbooks that the operator runs over SSH once the VPS is responsive. Each is reversible. Together they:

1. **Cap GitLab Puma + Sidekiq** — `per_worker_max_memory_mb = 400` (default ~1024), `sidekiq concurrency = 10` (default 20). Trades throughput for ~1.2 GB of headroom.
2. **Protect sshd from OOM** — systemd drop-in with `OOMScoreAdjust = -1000`. Makes sshd effectively unkillable so the operator can always get in to triage.
3. **Double swap to 8 GB** — resize `/swapfile` from 4 GB → 8 GB. More room for the kernel to dehydrate idle pages before the OOM killer fires.

Combined effect: under the same workload that OOM-cascaded twice today, the host should now (a) keep sshd up no matter what, (b) absorb temporary memory spikes without triggering kills, (c) cap GitLab's runaway potential.

## Runbooks

- [01-gitlab-memory-caps.md](runbooks/01-gitlab-memory-caps.md) — apply `per_worker_max_memory_mb = 400` + `sidekiq concurrency = 10` via `/etc/gitlab/gitlab.rb`.
- [02-sshd-oom-protect.md](runbooks/02-sshd-oom-protect.md) — systemd drop-in for sshd with OOMScoreAdjust=-1000.
- [03-double-swap.md](runbooks/03-double-swap.md) — resize /swapfile from 4 GB to 8 GB.
- [04-apply-and-verify.md](runbooks/04-apply-and-verify.md) — order, sequencing, and post-conditions.

## Playbooks

- [01-gitlab-memory-caps.sh](playbooks/01-gitlab-memory-caps.sh) — idempotent. Backs up gitlab.rb; sets the two values; runs `gitlab-ctl reconfigure`.
- [02-sshd-oom-protect.sh](playbooks/02-sshd-oom-protect.sh) — idempotent. Writes `/etc/systemd/system/ssh.service.d/50-oom-protect.conf`; reloads systemd.
- [03-double-swap.sh](playbooks/03-double-swap.sh) — idempotent. Skips if `/swapfile` is already ≥ 8 GB.
- [apply-all.sh](playbooks/apply-all.sh) — runs 01 → 02 → 03 in safe order; logs each step.

## Replay (zero-AI, on the VPS via SSH)

```bash
# (After SSH is responsive)
cd ~/Developer/yousirjuan 2>/dev/null || \
  git clone https://github.com/marvelousempire/yousirjuan ~/Developer/yousirjuan && \
  cd ~/Developer/yousirjuan
git pull && \
sudo bash ledger/LEDGER-0011-vps-memory-hardening/playbooks/apply-all.sh
```

## Verification

After applying:

```bash
# 1. GitLab caps in effect
grep -E "per_worker_max_memory_mb|sidekiq\['concurrency'\]" /etc/gitlab/gitlab.rb

# 2. sshd OOM protection
systemctl cat ssh | grep -i oom    # should show OOMScoreAdjust=-1000
cat /proc/$(pidof sshd | tr ' ' '\n' | head -1)/oom_score_adj   # should print -1000

# 3. Swap is 8 GB
free -h | grep Swap                # should show 8.0Gi (or close)
```

## Undo

Each playbook has its own `--undo` action. To revert all:

```bash
sudo bash ledger/LEDGER-0011-vps-memory-hardening/playbooks/03-double-swap.sh --undo && \
sudo bash ledger/LEDGER-0011-vps-memory-hardening/playbooks/02-sshd-oom-protect.sh --undo && \
sudo bash ledger/LEDGER-0011-vps-memory-hardening/playbooks/01-gitlab-memory-caps.sh --undo
```

(Reverse order of apply to avoid leaving sshd unprotected while gitlab restarts.)

## Cross-references

- [LEDGER-0007 runbook 05](../LEDGER-0007-imac-emergency-failsafe/runbooks/05-incident-2026-05-20-oom-cascade.md) — the postmortem that motivated this hardening.
- ADR-0001 — the architectural philosophy this fits: "selective, careful, full" — not "throw more hardware."
- Future: a LEDGER-0012 may track the RAM upgrade (8 → 16 GB) if these caps prove insufficient.

## Open follow-ups (not in this PR)

- **Monitor for 24h after apply.** If a third OOM cascade happens within 24h with these caps in place, RAM upgrade becomes mandatory.
- **n8n sandbox (LEDGER-0010)** — moving n8n into a memory-capped Docker sandbox removes today's specific OOM trigger (`npm install n8n` on host) permanently.
- **Tamer notification** — once LEDGER-0009 lands on Apple Silicon, it should flag "OOM event detected in dmesg" as a critical suggestion.
