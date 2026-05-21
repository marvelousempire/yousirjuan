---
ledgerId: LEDGER-0015
title: Server Stability Suite — proactive killer + /history endpoint + macOS notification alerts
status: in-progress
opened: 2026-05-21
closed: null
related-tickets: [LEDGER-0007, LEDGER-0011, LEDGER-0012, LEDGER-0014]
triggers:
  - systemd:yousirjuan-server-tamer.service (VPS — every 30s)
  - launchd:com.yousirjuan.alert-watch (iMac — every 60s)
  - http:GET /history on LEDGER-0012 agent
---

# LEDGER-0015 — Server Stability Suite

## Ask

Operator 2026-05-21: *"how do I address this server issue with the monitoring tools […] let's get the monitoring tools going so we can really see in real time was happening […]. How do you tame the server from getting wild? We have to build software for them immediately because we can't have that happen again."*

Previous session built **observability** (watchdog, agent, UIs, kill buttons). What was missing: **proactive defense** — software that ACTS before the kernel OOM-killer fires + pings the operator regardless of which screen they're on.

## Outcome (all three components ship in this PR)

### 1. `server-tamer` — proactive killer (VPS systemd service)

Polls the LEDGER-0012 agent every 30 s. Tiered response:

| Memory % | Action |
|---|---|
| ≥ 85% | WARN (log + state counter set) |
| ≥ 90% | WARN_LOUD (escalate counter) |
| ≥ 92% **sustained 2 consecutive ticks (60 s)** | KILL highest-RSS non-protected non-root process + write loud operator-intent file documenting the kill |

**Protected from kill (never targeted, even if largest):**
- PID 1, sshd, systemd, dbus, tailscaled
- LEDGER-0007 watchdog, LEDGER-0012 agent, this script itself
- Data services: postgres, redis, gitaly
- Anything matching patterns in `/etc/yousirjuan/server-tamer-protected.conf` (operator-extensible)

**Kill = TERM first, KILL if TERM fails.** Every kill auto-writes `/etc/yousirjuan/operator-intent.d/server-tamer-killed-pid-N-<ts>.md` so the next agent SSH-ing in sees the loud red banner explaining what got killed + why.

Counter resets after every kill so a single memory spike doesn't trigger multiple kills.

### 2. `/history` endpoint + 24h system-history retention

The server-tamer also writes a snapshot of `/system` to `/var/lib/yousirjuan/system-history.jsonl` every 30s. File auto-rotates at 3000 lines (keeps last 2880 = 24h).

LEDGER-0012 agent gains a new endpoint:

```
GET /history?lines=N        (default 200, max 2880)
```

Returns the JSONL tail. DustPan + Nephew can chart memory/load trends.

### 3. `alert-watch` — macOS notifications (iMac launchd)

Polls `http://vps-godaddy:9878/all` every 60 s. Fires `osascript -e 'display notification ...'` when:

- `mem_pct_used > 85`
- `swap_pct_used > 50`
- `load_1m > (CPUS × 4)` — default 16 on the 4-vCPU VPS
- Any subdomain returns HTTP `5xx` or `000`
- Agent itself unreachable

Debounced **5 minutes per threshold** in `~/.local/share/yousirjuan/alert-debounce.json` — no spam. Re-fires once cool-down elapses if condition still holds.

## Runbooks (covered by READMEs in each component for now; sub-docs deferred)

The ticket README + each script's inline header is the runbook. Sub-docs ship in a follow-up PR if patterns evolve.

## Playbooks

- [server-tamer.sh](playbooks/server-tamer.sh) — the proactive killer loop
- [install-server-tamer.sh](playbooks/install-server-tamer.sh) — install/uninstall/status (run as root on VPS)
- [alert-watch.sh](playbooks/alert-watch.sh) — macOS notification poller
- [install-alert-watch.sh](playbooks/install-alert-watch.sh) — install/uninstall/status/test (run as user on iMac)

## Artifacts

- [com.yousirjuan.alert-watch.plist](artifacts/com.yousirjuan.alert-watch.plist) — launchd template for the alert daemon

## Replay (zero-AI, on a fresh setup)

```bash
# VPS side (run as root)
ssh vps-godaddy 'cd ~/Developer/yousirjuan && git pull && \
  sudo bash ledger/LEDGER-0015-server-stability-suite/playbooks/install-server-tamer.sh install'

# iMac side (run as user)
cd ~/Developer/yousirjuan && git pull && \
  bash ledger/LEDGER-0015-server-stability-suite/playbooks/install-alert-watch.sh install
```

The server-tamer requires the LEDGER-0012 agent to already be running on the VPS.

## Verification

```bash
# VPS
ssh vps-godaddy 'sudo bash ~/Developer/yousirjuan/ledger/LEDGER-0015-server-stability-suite/playbooks/install-server-tamer.sh status'
ssh vps-godaddy 'curl -sf http://127.0.0.1:9878/history?lines=5'

# iMac
bash ~/Developer/yousirjuan/ledger/LEDGER-0015-server-stability-suite/playbooks/install-alert-watch.sh status
bash ~/Developer/yousirjuan/ledger/LEDGER-0015-server-stability-suite/playbooks/install-alert-watch.sh test
```

## Killer policy (chosen by operator)

- **WARN at 85%**
- **WARN_LOUD at 90%**
- **KILL at 92% sustained 2 ticks (60 s)**
- **Tick interval: 30 s**

To change: edit env vars in `/etc/systemd/system/yousirjuan-server-tamer.service` or in the script's top.

## Undo

```bash
ssh vps-godaddy 'sudo bash ~/Developer/yousirjuan/ledger/LEDGER-0015-server-stability-suite/playbooks/install-server-tamer.sh uninstall'
bash ~/Developer/yousirjuan/ledger/LEDGER-0015-server-stability-suite/playbooks/install-alert-watch.sh uninstall
```

History file + log files preserved.

## Cross-references

- LEDGER-0007 — watchdog (decision-maker for DNS failover; this is the parallel decision-maker for process kills)
- LEDGER-0011 — VPS hardening (sshd OOM protect + 8 GB swap; this layer activates BEFORE swap thrash)
- LEDGER-0012 — VPS agent that this suite reads from
- LEDGER-0014 — operator-intent protocol (every server-tamer kill writes an intent file via this mechanism)
- Universal Rule 14 — dual-push (used to push this PR to GitHub + GitLab)

## Open follow-ups

- **Phase 2:** Time-series chart in DustPan VPS panel + Nephew /vps page (consume /history endpoint)
- **Phase 3:** push notifications via Pushover / APNs (when iPhone isn't near the Mac)
- **Phase 4:** programmatic action by Tamer (LEDGER-0009) — automated suggestion + opt-in apply
