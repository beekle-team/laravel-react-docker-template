import { test, expect } from 'playwright/test';

test.describe('Landing page', () => {
    test('shows the welcome screen', async ({ page }) => {
        await page.goto('/');

        await expect(page).toHaveTitle(/Welcome/i);
        await expect(page.getByRole('link', { name: 'Log in' })).toBeVisible();
        await expect(page.getByRole('link', { name: 'Register' })).toBeVisible();
    });
});
