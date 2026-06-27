#!/usr/bin/env bash
#
# Browser E2E + accessibility (Playwright + axe). Opt-in:
#   E2E_BASE_URL   URL of a running admin web (required; else skip)
# Uses the pre-installed Chromium; never runs `playwright install`.
# Skips cleanly (exit 0) when deps or target are unavailable.
set -uo pipefail
cd "$(dirname "$0")/.."

if [ -z "${E2E_BASE_URL:-}" ]; then
  printf '\033[1;33m! E2E_BASE_URL not set — skipping browser e2e/a11y (point it at a running admin web)\033[0m\n'
  exit 0
fi
if ! pnpm exec playwright --version >/dev/null 2>&1; then
  printf '\033[1;33m! @playwright/test not installed — skipping. Install: pnpm add -Dw @playwright/test @axe-core/playwright\033[0m\n'
  exit 0
fi

echo "▶ Playwright e2e + a11y against $E2E_BASE_URL"
pnpm exec playwright test --config e2e-browser/playwright.config.ts
