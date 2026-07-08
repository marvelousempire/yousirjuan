Status: proposed

# Plan 0007 — Benchmark cassettes for the You-Sir Juan Hardware Console

## Context

While tracking down a Flipper Zero USB connection issue, the operator discovered the
root cause was a charging-only cable (no data lines) — the Mac saw nothing to
enumerate until a data-capable cable was used. That, plus a purchase-history check
that surfaced a confirmed OWC Thunderbolt 5 cable order (`data/hardware-spec-registry.json`
→ `owc-tb5-cables`) with no equivalent measured-throughput record, prompted the
question: **the family owns a lot of cables, drives, and docks — but has no
standard way to measure whether any given one is actually delivering the speed it's
rated for.**

The **You-Sir Juan · Hardware Console** (`yousirjuan-console`, a Cassette Factory
prototype — `cassette.json` id `yousirjuan-console`, door `yousirjuan-console.localhost`,
backend `server.mjs` + `console-page.mjs`) already ships **receipt-backed benchmarks —
Geekbench-style comparison tiles** (see `cassette.json` description) via
`renderStackBenchmarks` / `renderBenchmarkCompare` in
`scripts/lib/console-hardware-panels.mjs` (Nephew-side), reading from
`optimus-nephew/benchmarks/receipts/`. Today those receipts cover **stack/LLM**
benchmarks (llmq, fleet posture). There is no equivalent receipt category for
**physical hardware throughput** — cable speed, drive speed, network link speed.

## Approach

Extend the existing receipt-backed benchmark model with new benchmark **categories**,
each its own "cassette" inside the Hardware Console rather than one monolithic
benchmark page. This keeps each measurement type independently addable/removable
(per `cassette-discipline` — the Console is the player, each benchmark type is a
tape) and keeps this plan documentation-only in `yousirjuan`, per the existing
`REPOS-CONTRACT.md` boundary (yousirjuan = hardware/infra docs; Nephew ships the
Console's actual code, cassette catalogue, and Pockit-facing JS — see Plan 0005/0006).

### Benchmark categories (first three)

| Category | What it measures | Reference tool |
|---|---|---|
| **Cable throughput** | Real sustained transfer speed on a specific cable (TB5/TB4/USB4/Cat8), not the rating printed on the box | `iperf3` (network cables) or a loopback file-copy test between two TB5-attached drives for TB/USB cables |
| **Drive speed** | Sequential + random read/write on a specific drive/enclosure (NVMe, HDD, SD) | `dd` (sequential) + a small random-IO tool (e.g. `fio` if available, else a scripted random-offset `dd` loop) |
| **Network link** | LAN/WG throughput between two fleet nodes on a specific physical link | `iperf3` client/server pair |

Each category ships as a `benchmarks/receipts/<category>/*.json` file (same shape
as the existing stack-benchmark receipts: timestamp, machine, measured value(s),
the specific hardware item id it corresponds to — cross-referencing
`data/hardware-spec-registry.json` entries like `owc-tb5-cables` or
`ugreen-dxp6800-pro`), a small script that runs the actual measurement and writes
the receipt, and a panel renderer (`renderCableBenchmarks`, `renderDriveBenchmarks`,
`renderNetworkBenchmarks`) added alongside the existing `renderStackBenchmarks` /
`renderBenchmarkCompare` in the Console's Nephew-side panel library.

### Cable-to-registry linkage

Every cable/drive benchmark receipt must name the **exact registry entry** it
measured (e.g. `"hardware_id": "owc-tb5-cables"`, `"length_ft": 0.98`) so the
Console can show "this specific cable measured 78 Gb/s on 2026-07-08" next to its
purchase record, rather than a generic unlabeled number. This closes the gap this
plan started from: a cable purchase (`owc-tb5-cables`) with no linked performance
data.

## Out of scope (per REPOS-CONTRACT.md)

- Editing `cassette-catalogue.json`, tower-api routes, or any Pockit/Nephew JS —
  that work happens in the `nephew` repo, not here.
- Building the actual `renderCableBenchmarks` / `renderDriveBenchmarks` panel code —
  this plan documents the shape; implementation is a Nephew-side plan that cites
  this one.

## Critical files (this repo, docs/data only)

| File | Change |
|---|---|
| `data/hardware-spec-registry.json` | `owc-tb5-cables` entry added (this PR) — the record a benchmark receipt will eventually link to |
| `plans/0007-benchmark-cassettes-hardware-console.md` | this plan |
| `plans/README.md` | index row added |
| `docs/setup/32-hardware-full-spec-sheet.md` | (follow-up) add a section describing the benchmark-receipt schema once the Nephew-side implementation ships |

## Verification

1. `data/hardware-spec-registry.json` parses as valid JSON and includes `owc-tb5-cables`
   with a `purchases[]` array (`node -e "JSON.parse(require('fs').readFileSync('data/hardware-spec-registry.json'))"`).
2. `plans/README.md` lists this plan.
3. Follow-up Nephew-side plan (once filed) links back to this plan by number.
