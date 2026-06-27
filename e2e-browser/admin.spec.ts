import AxeBuilder from '@axe-core/playwright';
import { expect, test } from '@playwright/test';

/**
 * Browser E2E + accessibility for the admin console. Runs against E2E_BASE_URL
 * (a running admin web instance). Critical-journey smoke + automated a11y (axe)
 * on key pages. Kept small — deep behavior lives in the API tiers.
 */

test.describe('admin console — smoke + a11y', () => {
  test('login page renders and is accessible', async ({ page }) => {
    await page.goto('/login');
    await expect(page).toHaveTitle(/dealdrop|admin|login/i);

    const results = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa'])
      .analyze();
    // No serious or critical accessibility violations on the entry page.
    const serious = results.violations.filter((v) => ['serious', 'critical'].includes(v.impact ?? ''));
    expect(serious, JSON.stringify(serious, null, 2)).toEqual([]);
  });

  test('dashboard is reachable after the login route', async ({ page }) => {
    // Smoke only: the page responds and renders a shell without a hard error.
    const res = await page.goto('/dashboard');
    expect(res?.status()).toBeLessThan(500);
  });
});
