#!/usr/bin/env bash
set -euo pipefail

benchmark_root="${STANDARD_BENCHMARK_STACK_ROOT:-${HOME}/Developer/standard-benchmark-stack}"
summary="${benchmark_root}/receipts/campaigns/fleet-ci-git-expanded-2026-07-22/summary.json"

test -f "${summary}" || { echo "missing campaign summary: ${summary}" >&2; exit 1; }
jq -e '
  .tool.version == "0.3.0" and
  (.tool.git_sha | startswith("223d46e")) and
  .authoritative_samples.passed == 200 and
  .authoritative_samples.failed == 0 and
  ([.hosts[] | select(.status == "benchmarked")] | length) == 4 and
  ([.hosts[] | select(.id == "zeromac" and .status == "unreachable")] | length) == 1
' "${summary}" >/dev/null

echo "verified fleet-ci-git-expanded-2026-07-22"
