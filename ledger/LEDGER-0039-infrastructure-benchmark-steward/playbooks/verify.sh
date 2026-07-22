#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/../../.." && pwd)"
test -f "${root}/.claude/agents/infrastructure-benchmark-steward.md"
jq -e '
  .canonical_engine == "standard-benchmark-stack/benchlab" and
  ([.methods[] | select(.id == "benchlab")] | length) == 1 and
  ([.methods[] | select(.id == "disk-drill" and .status == "not-a-speed-benchmark")] | length) == 1
' "${root}/data/benchmark-method-registry.json" >/dev/null
echo "verified infrastructure-benchmark-steward"
