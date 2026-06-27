#!/usr/bin/env bash
#
# Flaky-test detection — surfaces flakes instead of hiding them.
# Runs the scope once; if anything fails, reruns ONLY the failed test files. A
# test that fails then passes is reported as FLAKY (quarantine list); one that
# fails both times is a REAL failure. Never silently retries to green.
#
# Usage: scripts/flaky-detect.sh [vitest scope ...]   (default: tests/)
set -uo pipefail
cd "$(dirname "$0")/.."
export TZ=UTC NODE_ENV=test
mkdir -p test-results
SCOPE=("${@:-tests/}")
VITEST="pnpm --filter @dealdrop/tests exec vitest"

echo "▶ run 1/2 (full scope)"
$VITEST run --reporter=json --outputFile=test-results/flaky-run1.json "${SCOPE[@]}"
if [ $? -eq 0 ]; then echo "✓ all green on first run — no flakes"; exit 0; fi

mapfile -t FAILED < <(node -e '
  const r = require("./test-results/flaky-run1.json");
  const s = new Set();
  for (const t of (r.testResults||[])) if (t.status !== "passed") s.add(t.name);
  process.stdout.write([...s].join("\n"));
')
[ "${#FAILED[@]}" -eq 0 ] && { echo "✗ run failed but no test files identified"; exit 1; }

printf '▶ run 2/2 (rerun %d failed file(s))\n' "${#FAILED[@]}"
$VITEST run --reporter=json --outputFile=test-results/flaky-run2.json "${FAILED[@]}"
rc=$?

node -e '
  const second = require("./test-results/flaky-run2.json");
  const stillFailing = (second.testResults||[]).filter(t => t.status !== "passed").map(t => t.name);
  const reran = (second.testResults||[]).map(t => t.name);
  const flaky = reran.filter(n => !stillFailing.includes(n));
  const fs = require("fs");
  fs.writeFileSync("test-results/quarantine.json", JSON.stringify({ flaky, stillFailing }, null, 2));
  if (flaky.length) { console.log("\n⚠ FLAKY (passed on rerun) — quarantine:"); flaky.forEach(f=>console.log("  - "+f)); }
  if (stillFailing.length) { console.log("\n✗ REAL failures (failed twice):"); stillFailing.forEach(f=>console.log("  - "+f)); }
'
# Exit non-zero only on REAL failures; flakes are reported but do not pass the gate silently.
if [ "$rc" -ne 0 ]; then echo "✗ real failures remain"; exit 1; fi
echo "⚠ failures were flaky — see test-results/quarantine.json (treat as defects)"; exit 0
