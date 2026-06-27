import { defineConfig, devices } from '@playwright/test';

/**
 * Playwright config for browser-level E2E + accessibility checks against a
 * RUNNING target (the admin web, or any deployed URL). Opt-in: driven by
 * scripts/e2e-browser.sh, which only runs when E2E_BASE_URL is set.
 *
 * Uses the pre-installed Chromium (PLAYWRIGHT_BROWSERS_PATH=/opt/pw-browsers);
 * no `playwright install` is performed.
 */
export default defineConfig({
  testDir: '.',
  testMatch: '**/*.spec.ts',
  forbidOnly: Boolean(process.env.CI),
  retries: 0, // flakes are defects — surfaced via scripts/flaky-detect.sh, not retried away
  reporter: [
    ['list'],
    ['junit', { outputFile: '../test-results/playwright-junit.xml' }],
  ],
  use: {
    baseURL: process.env.E2E_BASE_URL,
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },
  projects: [{ name: 'chromium', use: { ...devices['Desktop Chrome'] } }],
});
