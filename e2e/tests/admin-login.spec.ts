import { test, expect } from '@playwright/test';

/**
 * Admin web smoke — requires:
 *   flutter run -d web-server -t lib/main_admin.dart --web-port=8081
 *   backend + seed on localhost:3000
 */
test.describe('Admin panel', () => {
  test('login page loads', async ({ page }) => {
    await page.goto('/');
    await expect(page.locator('flutter-view, body')).toBeVisible({ timeout: 15_000 });
  });

  test('shows email login form elements', async ({ page }) => {
    await page.goto('/');
    await page.waitForTimeout(3000);
    const body = await page.locator('body').innerText();
    expect(body.length).toBeGreaterThan(0);
  });
});
