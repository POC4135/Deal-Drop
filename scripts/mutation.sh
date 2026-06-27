#!/usr/bin/env bash
#
# Mutation testing (Stryker) on the core pure logic. Reports a mutation score
# and breaks below the configured threshold (stryker.conf.json). Opt-in: if
# Stryker isn't installed, prints an install hint and skips (exit 0).
#
# MUTATE can override the target glob(s) for a faster focused run, e.g.
#   MUTATE=services/api/src/modules/trust/engine.ts scripts/mutation.sh
set -uo pipefail
cd "$(dirname "$0")/.."

if ! pnpm exec stryker --version >/dev/null 2>&1; then
  printf '\033[1;33m! Stryker not installed — skipping mutation run.\033[0m\n'
  printf '  Install: pnpm add -Dw @stryker-mutator/core @stryker-mutator/vitest-runner\n'
  exit 0
fi

mkdir -p test-results
if [ -n "${MUTATE:-}" ]; then
  pnpm exec stryker run --mutate "$MUTATE"
else
  pnpm exec stryker run
fi
