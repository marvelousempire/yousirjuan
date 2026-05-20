# ADR-0001 — No Kubernetes. Selective Docker. No wholesale containerization.

- **Status:** Accepted
- **Date:** 2026-05-20
- **Decided by:** Avery Goodman (operator) + agent recommendation
- **Revisit:** 2026-11-20 (6 months — after Phase 2 standby containers land and the stack's resource ceiling has been re-measured)

## Context

During the LEDGER-0008 PR review, the operator asked: *"Is it best for us to TAME everything by running in Docker container and in different networks for Docker and share containers sometimes and use APIs and Kubernetes too?"*

It's a legitimate architectural question. Containerization and orchestration are real tools. The cost of getting the answer wrong is months of operational overhead with little measurable benefit.

This ADR captures the call we made and the data behind it so future agents (and future-Avery) don't re-litigate.

## Current footprint (the relevant numbers)

| Node | Hardware | Role | Always-on? |
|---|---|---|---|
| GoDaddy VPS | 4 vCPU / 7.8 GB RAM / 193 GB disk | nginx, GitLab CE, n8n, Postgres, Redis, Cursor remote-server | Yes |
| iMac (operator's main) | Likely 32+ GB RAM | Dev box, LEDGER-0006 always-on, Ollama (LEDGER-0001), watchdog (LEDGER-0007) | Yes (per Energy Saver) |
| Mac mini | M4 Pro 48 GB target | Future inference + DGX Spark routing default | TBD |
| DGX Spark | 128 GB unified | Future ceiling-tier inference | TBD |

Total active services across the whole platform: **~10**. Total active operators: **1**. Total active SREs to maintain a control plane: **0**.

## The OOM postmortem (LEDGER-0007 runbook 05) anchors the decision

A `npm install n8n` triggered a host-wide OOM cascade on the VPS this morning. Memory was already at the redline before that. Adding container-runtime overhead (dockerd + containerd + per-container network namespaces + overlay2) would have made that incident more likely, not less. Containers don't add memory; they add overhead.

## Decision

### 1. No Kubernetes

The Kubernetes control plane (etcd + kube-apiserver + kube-scheduler + kube-controller-manager + kubelet on every node) consumes 1–2 GB of RAM **before any workload runs**. On a 7.8 GB host that just OOM-cascaded, dedicating 25% of total RAM to the orchestrator is the opposite of prudence.

K8s is designed for and best-in-class at:

- 100+ nodes
- 50+ services
- Multi-tenant or multi-team workloads
- Dedicated SRE / platform-engineering staff

We have 1 VPS + 2 Macs, ~10 services, 1 operator. **K8s is wildly over-scoped.** The right tool at this scale is `systemd`, `launchd`, and `docker-compose` for the few workloads that genuinely need containment.

### 2. No wholesale Dockerization

Migrating already-working native services (Postgres-on-systemd, nginx-on-systemd, the macOS launchd jobs) into Docker buys us nothing and costs:

- ~5–10% memory overhead per containerized process
- New failure modes (mounts, networking, image rebuilds)
- New ops surface (image registries, scanning, rebuilds)

**If it's not broken, native stays native.**

### 3. Selective Docker for the unruly

Containerize ONLY processes that fit one or more of:

- **Untrusted by default** — third-party CLIs that shouldn't see the host filesystem (Grok CLI Beta, future LLM clients, anything you wouldn't `curl | bash`)
- **Native-deps hell** — Python/Node trees with binary wheels that break the host package state on every update (sharp, sqlite native, transformers, etc.)
- **Memory-bounded targets** — services we explicitly want to kill at a limit before they OOM-kill the host (n8n was today's offender; capping it in a container with `MemoryMax=1g` prevents recurrence)

Tools we will containerize:

| Tool | Why | Container target |
|---|---|---|
| Grok CLI Beta | Untrusted, network-egress LLM CLI | LEDGER-0010 sandbox |
| n8n (going forward) | Today's OOM offender; needs hard memory cap | LEDGER-0010 sandbox |
| ComfyUI / Flux / Whisper / Kokoro | GPU + Python binary deps | Already containerized in `docker-compose.yml` |
| Future LLM CLIs (Claude Code remote, etc.) | Untrusted by default | LEDGER-0010 sandbox |

Tools we will NOT containerize:

| Tool | Why it stays native |
|---|---|
| LEDGER-0007 watchdog | launchd IS its container — adding Docker between launchd and the script adds nothing |
| LEDGER-0008 state server | Same |
| GitLab CE (Omnibus) | Already containerized in LEDGER-0005 — done |
| VPS Postgres / Redis | Working under systemd; Docker would only add overhead |
| Mac mini Ollama | Native install is faster + simpler for inference workloads |

### 4. Network isolation when we containerize

Each containerized class gets its own Docker network. Sample policy:

```yaml
# docker-compose.yml
networks:
  sandbox-net:           # untrusted CLIs — no inter-container traffic
    internal: false      # outbound web allowed (LLM API calls)
  llm-net:               # local Ollama-talking workloads
    internal: true       # no outbound web; tailnet-only ingress
  media-net:             # ComfyUI / Flux — heavy
    internal: true
```

Cross-network traffic goes through explicit `external: true` references when sharing is needed. Default is "no, you don't see other containers."

### 5. APIs for everything cross-host

Where two surfaces on different hosts need to communicate (e.g. Nephew Control Tower on VPS → iMac watchdog state), the call is **always an HTTP(S) API over Tailscale**, never a direct mount, never a shared filesystem, never a database connection. Examples already in production: LEDGER-0008 (`:9876` watchdog state server).

## Consequences

### Positive

- Memory pressure stays manageable on the 7.8 GB VPS
- Single-operator stack stays single-operator-debuggable
- Each containerized tool has explicit justification, not "because Docker is good"
- Failure modes stay finite: a launchd job fails → `launchctl print`; a container fails → `docker logs`; not "the etcd cluster is in a split-brain"

### Negative

- We don't get K8s features (rolling updates, declarative state, multi-host scheduling). If we ever grow past ~5 nodes or ~20 services, we'll revisit.
- Manual `docker-compose` per containerized class instead of a unified scheduler. Acceptable at this scale.

### Trigger to revisit

Re-evaluate this ADR if **any** of these happen:

1. Active node count grows past 5 (currently 3: VPS + iMac + Mac mini)
2. Active service count grows past 25 (currently ~10)
3. A second operator joins ops rotation
4. Inference workloads need multi-host scheduling (DGX Spark + Mac mini pooling)
5. The 6-month calendar trigger (2026-11-20) — we re-read this and check

## References

- LEDGER-0001 (Mac mini Ollama + native install pattern)
- LEDGER-0005 (GitLab CE Omnibus in Docker — the containerization we already accepted)
- LEDGER-0007 runbook 05 (the OOM incident that anchored the "containers don't add memory" point)
- LEDGER-0010 (Sandbox CLI generator — the concrete implementation of "selective Docker for the unruly")
- `.claude/rules/contracts-and-prudence.md` — the operating philosophy this decision applies
