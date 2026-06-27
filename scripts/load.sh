#!/usr/bin/env bash
#
# Load / performance tests (k6). Opt-in: requires k6 and a running target.
#   LOAD_TARGET   base URL of a running API (default http://localhost:3000)
# Skips cleanly (exit 0) if k6 is not installed — never blocks the gate.
# Performance budgets are asserted inside perf/*.js via k6 thresholds, so a
# regression past budget makes k6 exit non-zero.
set -uo pipefail
cd "$(dirname "$0")/.."

if ! command -v k6 >/dev/null 2>&1; then
  printf '\033[1;33m! k6 not installed — skipping load tests (install: https://k6.io/docs/get-started/installation/)\033[0m\n'
  exit 0
fi

export LOAD_TARGET="${LOAD_TARGET:-http://localhost:3000}"
mkdir -p test-results
echo "▶ k6 load test against $LOAD_TARGET"
k6 run --summary-export=test-results/k6-summary.json perf/api-smoke.js
