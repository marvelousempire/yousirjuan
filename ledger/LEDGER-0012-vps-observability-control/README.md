---
ledgerId: LEDGER-0012
title: VPS observability + control surface in DustPan — live processes, kill, docker, notifications
status: in-progress
opened: 2026-05-20
closed: null
related-pains: []
related-tickets: [LEDGER-0007, LEDGER-0008, LEDGER-0009, LEDGER-0011]
triggers:
  - systemd:yousirjuan-vps-agent.service (auto-on, RestartOnFailure)
phase-1:
  status: shipped-in-this-pr
  scope: VPS-side agent daemon (systemd) exposing /system /processes /docker /sites /kill /docker/{stop,start}
phase-2:
  status: deferred
  scope: DustPan "VPS" tab with live cards, kill buttons, docker controls (marvelousempire/dustpan PR)
phase-3:
  status: deferred
  scope: macOS notifications when load > N, mem > N%, swap > N%, any subdomain DOWN
---

# LEDGER-0012 — VPS observability + control in DustPan

## Ask

> "you were able to see exactly which one of those things are running high […]. You have to let me see all of that inside of the server VPS section of dust pan. […] I have to be able to control what's happening and be able to kill what's happening from dust pan dust pan should have the watcher on it. Send me notifications. Let me know [if the] servers getting too hot."

## Outcome (Phase 1, in this PR)

A systemd-managed agent on the VPS exposes process + docker + system state over an authenticated HTTP API. DustPan (Phase 2, separate PR) reads from this and renders a live VPS section with kill controls.

### Endpoints (live on the VPS once installed)

| Method | Path | Auth | Returns |
|---|---|---|---|
| GET | `/health` | none | `ok\n` |
| GET | `/system` | none | uptime, load, mem, swap, disk, hostname |
| GET | `/processes` | none | top 20 by CPU + top 20 by MEM |
| GET | `/docker` | none | all containers (name, status, ports, image) |
| GET | `/sites` | none | HTTP code + latency for each yousirjuan.ai subdomain |
| GET | `/all` | none | bundle of the four above (single-fetch for DustPan) |
| POST | `/kill` | Bearer | `{pid, signal?}` → kill a process (refuses PID < 100) |
| POST | `/docker/stop` | Bearer | `{name}` → stop a container |
| POST | `/docker/start` | Bearer | `{name}` → start a container |

GET endpoints are unauthenticated (read-only, host stats — gated by Tailscale ACL). POST endpoints require `Authorization: Bearer <token>` from `/etc/yousirjuan/vps-agent.env`, generated on first install.

### Why a separate agent vs piggybacking on LEDGER-0008's state server

LEDGER-0008's state server lives on the **iMac** and exposes the watchdog's view. LEDGER-0012's agent lives on the **VPS** and exposes the VPS's actual process/memory/docker state. Different host, different concern, different authority model (this one can kill processes; the iMac one cannot).

## Runbooks (TBD in follow-up PR)

- `01-install.md` — operator one-line install on VPS
- `02-tailscale-acl.md` — restrict :9878 to tag:dustpan + tag:nephew-tower nodes
- `03-thresholds.md` — recommended notification thresholds (mem > 85%, swap > 50%, load > 4×cpus, any subdomain HTTP code != 2xx/3xx)

## Playbooks (ship in this PR)

- [vps-agent-server.sh](playbooks/vps-agent-server.sh) — the Python http.server daemon (~210 LOC, no deps beyond stdlib)
- [install-vps-agent.sh](playbooks/install-vps-agent.sh) — install/uninstall/status. Generates bearer token, writes systemd unit, enables + starts service. Idempotent.

## Replay (zero-AI)

```bash
ssh vps-godaddy 'cd ~/Developer/yousirjuan 2>/dev/null || \
  git clone https://github.com/marvelousempire/yousirjuan ~/Developer/yousirjuan; \
  cd ~/Developer/yousirjuan && git pull && \
  sudo bash ledger/LEDGER-0012-vps-observability-control/playbooks/install-vps-agent.sh install'
```

Token gets printed once — paste into DustPan's settings when Phase 2 ships. Token also persisted at `/etc/yousirjuan/vps-agent.env`.

## Verification

```bash
# From the iMac:
curl -s http://vps-godaddy.tailnet:9878/health      # ok
curl -s http://vps-godaddy.tailnet:9878/system | python3 -m json.tool | head -20
curl -s http://vps-godaddy.tailnet:9878/processes | python3 -m json.tool | head -40
curl -s http://vps-godaddy.tailnet:9878/docker | python3 -m json.tool | head -30
curl -s http://vps-godaddy.tailnet:9878/sites | python3 -m json.tool
```

The `/processes` response is what made today's diagnosis instant — it's the same data as `ps -eo pid,user,pcpu,pmem,rss,etime,command --sort=-pmem` but structured.

## Undo

```bash
ssh vps-godaddy 'sudo bash ledger/LEDGER-0012-vps-observability-control/playbooks/install-vps-agent.sh uninstall'
```

Service stopped + disabled. Token preserved (delete manually to rotate).

## Phase 2 + 3 (separate PRs in marvelousempire/dustpan)

### Phase 2 — DustPan "VPS" tab

New tab next to "settings" in DustPan's tab bar. Cards:

1. **System** — load 1m/5m/15m gauges, memory used/free bars, swap usage, disk
2. **Top processes** — table of top 10 by CPU + top 10 by MEM with a [Kill] button next to each (signal selector: TERM / KILL)
3. **Docker containers** — list with `[Stop]` / `[Start]` buttons per container
4. **Sites** — per-subdomain HTTP code + latency badge (mirrors the watchdog targets)

Polls `/all` every 5 seconds when tab is foregrounded; pauses when backgrounded.

### Phase 3 — Notifications

- Tail `/system` from a tiny launchd job on the operator's Mac
- When `mem_pct_used > 85` or `swap_pct_used > 50` or `load_1m > 4*cpus` or any `/sites` entry has code `000` or `5xx` → `osascript -e 'display notification ...'`
- Debounced (5 min between same-threshold alerts) to avoid spam

## Cross-references

- **Builds on** LEDGER-0007 (watchdog) — the watchdog still does the DNS-failover decisions; this agent is the read-side for DustPan
- **Sibling of** LEDGER-0008 (iMac state server) — same architecture, different host
- **Replaces the gap** in LEDGER-0009 (Tamer was advisory; this is operational visibility + kill control)
- **Tested against** LEDGER-0011 (the hardening playbooks operate on processes this agent will show)

## Open follow-ups

- ACL: only operator's tagged DustPan + Nephew should reach :9878 (runbook 02)
- Process kill confirmation: DustPan UI should show a "confirm kill PID X (cmd: …)?" modal before POSTing
- Add `/disk` endpoint with per-mount usage (currently `/` only)
- Log retention: rotate `/var/log/yousirjuan-vps-agent.log` via logrotate
