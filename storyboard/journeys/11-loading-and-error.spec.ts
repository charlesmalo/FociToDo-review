import { expect, test } from '@playwright/test';
import { frame } from '../frame';

// Brief: List — the loading state and a failed load, surfaced through the real client retries.
test('a delayed list request shows loading, a failing one shows the error banner, and Retry recovers', async ({
  page,
}) => {
  await page.route('**/api/todos**', async (route) => {
    if (route.request().method() !== 'GET') {
      await route.continue();
      return;
    }
    await new Promise((resolve) => setTimeout(resolve, 1_500));
    await route.abort('failed');
  });

  await page.goto('/');
  await expect(page.getByText('Loading tasks…')).toBeVisible();
  await frame(
    page,
    'loading-and-error',
    1,
    'While the list request is in flight: "Loading tasks…".',
    'ui/task-list-loading',
  );

  // The client retries twice with backoff before giving up — allow generous time for that.
  const errorBanner = page.getByRole('alert');
  await expect(
    errorBanner.getByText('Could not reach the server. Check your connection and try again.'),
  ).toBeVisible({ timeout: 15_000 });
  await expect(errorBanner.getByRole('button', { name: 'Retry' })).toBeVisible();
  await frame(
    page,
    'loading-and-error',
    2,
    'After the retries fail: the error banner with Retry.',
    'ui/task-list-load-error',
  );

  await page.unroute('**/api/todos**');
  await errorBanner.getByRole('button', { name: 'Retry' }).click();
  await expect(page.getByRole('list', { name: 'Tasks' })).toBeVisible();
  await expect(page.getByRole('alert')).toHaveCount(0);
  await frame(
    page,
    'loading-and-error',
    3,
    'Retry succeeds and the list loads.',
    'ui/task-list-with-tasks',
  );
});
