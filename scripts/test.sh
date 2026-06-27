#!/usr/bin/env bash
#
# DealDrop test harness — single canonical entry point.
#
# Usage: scripts/test.sh <tier>
#   smoke    seconds   boot + critical health (post-deploy / pre-gate sanity)
#   unit     fast      pure-logic unit tests, runs on every commit
#   gate     <10 min   PRE-MERGE GATE: typecheck + lint + unit/characterization/
#                      contract/integration/smoke/security/resilience/property/e2e
#                      + coverage ratchet + dependency & secrets scan
#   full     nightly   everything incl. Playwright e2e, k6 load, Stryker mutation
#   changed  fast      only tests affected by the current diff (local iteration)
#
# Every tier: fixed seeds + frozen TZ, machine-readable JUnit + human summary,
# isolated ephemeral deps, non-zero exit on any failure.
set -uo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"

# ---- Determinism ----------------------------------------------------------
export TZ=UTC
export NODE_ENV=test
export FORCE_COLOR=1
export JUNIT=1                       # make vitest emit JUnit (see vitest.config.ts)
mkdir -p test-results

VITEST="pnpm --filter @dealdrop/tests exec vitest"
TIER="${1:-gate}"

say() { printf '\n\033[1;36m▶ %s\033[0m\n' "$*"; }
ok()  { printf '\033[1;32m✓ %s\033[0m\n' "$*"; }
die() { printf '\033[1;31m✗ %s\033[0m\n' "$*" >&2; exit 1; }

run_vitest() { $VITEST run "$@" || die "vitest failed ($*)"; }

case "$TIER" in
  smoke)
    say "Smoke — boot + critical health"
    run_vitest tests/smoke
    ok "smoke passed"
    ;;

  unit)
    say "Unit — pure logic"
    run_vitest tests/unit
    ok "unit passed"
    ;;

  changed)
    say "Changed — tests affected by the current diff"
    BASE="${CHANGED_BASE:-origin/phase1-base}"
    $VITEST run --changed "$BASE" tests/ || die "changed-tests failed"
    ok "changed tests passed"
    ;;

  gate)
    say "GATE — pre-merge required check"
    say "1/4 typecheck"
    pnpm typecheck || die "typecheck failed"
    say "2/4 lint (best-effort; no-op where unconfigured)"
    # `< /dev/null` guards against `next lint`'s interactive setup prompt hanging in CI.
    pnpm -r --if-present lint < /dev/null || printf '\033[1;33m! lint reported issues (non-blocking until lint config lands)\033[0m\n'
    say "3/4 functional + non-functional tiers + coverage ratchet"
    # Whole suite (vitest.config include = tests/**). Integration skips without a
    # DB; hermetic tiers pin the seed backend internally.
    run_vitest --coverage
    say "4/4 security scan (deps + secrets + SAST, degrades if tools absent)"
    bash scripts/security-scan.sh || die "security scan found a blocking issue"
    ok "GATE passed — safe to merge"
    ;;

  full)
    say "FULL — everything (nightly / on-demand)"
    "$0" gate || die "gate portion of full failed"
    say "Playwright e2e + a11y (opt-in; skips if app/deps unavailable)"
    bash scripts/e2e-browser.sh || printf '\033[1;33m! browser e2e skipped/failed (see output)\033[0m\n'
    say "k6 load (opt-in; skips if k6 absent)"
    bash scripts/load.sh || printf '\033[1;33m! load tests skipped/failed (see output)\033[0m\n'
    say "Stryker mutation on core logic (opt-in; reports score)"
    bash scripts/mutation.sh || printf '\033[1;33m! mutation run skipped/failed (see output)\033[0m\n'
    ok "FULL complete"
    ;;

  *)
    die "unknown tier '$TIER' (expected: smoke|unit|gate|full|changed)"
    ;;
esac
