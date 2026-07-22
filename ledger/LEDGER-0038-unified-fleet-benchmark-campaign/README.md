---
ledgerId: LEDGER-0038
title: Record the unified fleet CI and Git benchmark campaign
status: shipped
opened: 2026-07-22
closed: 2026-07-22
related-pains: [PAIN-0013]
related-tickets: [LEDGER-0037]
triggers: [manual:benchmark-campaign]
---

# LEDGER-0038 — Unified fleet CI/Git benchmark campaign

## Ask

Fix the incomplete CI/Git measurements, test Onemac, Bigmac, and Zeromac alongside Twomac and
Spark, and record the findings in You-Sir Juan's Benchmark Laboratory memory.

## Outcome

Benchlab 0.3.0 added real Git lifecycle, dependency install, test, build, durable-write, queue-delay,
and recovery metrics. Spark, Onemac, Bigmac, and Twomac ran the exact build and Node 22.23.1; all
200 authoritative samples passed. Zeromac was recorded as unreachable. Onemac is the preferred Mac
CI worker at concurrency 1; Gitea remains on Spark; Twomac remains a memory/service isolation node.

## Runbooks

- [01-run-fleet-campaign.md](runbooks/01-run-fleet-campaign.md) — identity, reachability, deployment, execution, and evidence rules.

## Playbooks

- [verify-record.sh](playbooks/verify-record.sh) — verify the canonical summary and authoritative sample count.

## Replay (zero-AI)

```sh
bash ledger/LEDGER-0038-unified-fleet-benchmark-campaign/playbooks/verify-record.sh
```

## Verification

The playbook resolves the canonical `standard-benchmark-stack` checkout, validates the campaign
JSON, requires tool SHA `223d46e`, and requires 200 passed / zero failed authoritative samples.

## Undo

Revert this ledger commit. Benchmark receipts remain immutable in `standard-benchmark-stack`.
