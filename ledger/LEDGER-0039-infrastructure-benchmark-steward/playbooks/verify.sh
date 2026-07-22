#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/../../.." && pwd)"
test -f "${root}/.claude/agents/infrastructure-benchmark-steward.md"
jq -e '
  .canonical_engine == "standard-benchmark-stack/benchlab" and
  ([.methods[] | select(.id == "benchlab")] | length) == 1 and
  ([.methods[] | select(.id == "disk-drill" and .status == "not-a-speed-benchmark")] | length) == 1
' "${root}/data/benchmark-method-registry.json" >/dev/null
jq -e '
  (["dgx-spark", "macbook-pro-m5-max", "macbook-pro-m1", "imac-2017", "imac-2012", "zeromac", "ugreen-dxp6800-pro"] - (.devices | keys) | length) == 0 and
  .devices["macbook-pro-m5-max"].ports.thunderbolt5_80gbps == 3 and
  .devices["dgx-spark"].power.gb10_tdp_w == 140 and
  .devices["ugreen-dxp6800-pro"].power.drive_access_w == 43.07
' "${root}/data/hardware-spec-registry.json" >/dev/null
echo "verified infrastructure-benchmark-steward"
