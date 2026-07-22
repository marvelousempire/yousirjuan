---
ledgerId: LEDGER-0039
title: Establish the Infrastructure Benchmark Steward
status: shipped
opened: 2026-07-22
closed: 2026-07-22
related-pains: [PAIN-0013]
related-tickets: [LEDGER-0038]
triggers: [manual:benchmark-request, schedule:fleet-certification]
---

# LEDGER-0039 — Infrastructure Benchmark Steward

## Ask

Create a You-Sir Juan agent whose purpose is to benchmark the fleet like Speedtest and Geekbench,
understand exactly which tool produced each number, and decide which machine is best for each
infrastructure task or service. Bring the console into DustPan now while preserving its future
Briefcase App direction.

## Outcome

The Infrastructure Benchmark Steward and method registry now codify evidence identity,
compatibility, per-workload placement, external-tool boundaries, and promotion gates. DustPan owns
the read-only console; Benchlab remains the canonical engine and evidence store. DXP6800 storage
paths and Zeromac's current access posture are recorded without synthetic claims.
The hardware source now also covers every benchmarked fleet node with compute, memory, storage,
power envelope, port counts and rated speeds, attached peripherals, roles, and legacy limits so
DustPan can project capability beside measured performance. Service evidence must state whether it
is a health probe, a workload benchmark, or a certification campaign.

## Runbooks

- [01-method-and-placement.md](runbooks/01-method-and-placement.md) — required measurement and placement sequence.

## Playbooks

- [verify.sh](playbooks/verify.sh) — validate the agent and method registry.

## Replay (zero-AI)

```sh
bash ledger/LEDGER-0039-infrastructure-benchmark-steward/playbooks/verify.sh
```

## Verification

The playbook requires a canonical Benchlab method, rejects Disk Drill as a speed benchmark,
requires the installed steward agent, and validates hardware coverage for Spark, Fivemac, Onemac,
Twomac, Bigmac, Zeromac, and DXP6800.

## Undo

Revert this ledger commit. Raw benchmark receipts remain in `standard-benchmark-stack`.
