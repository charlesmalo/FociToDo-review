import { expect, test } from '@playwright/test';
import { frame } from '../frame';
import { DAY, HOUR, createTodo, deadlineText, isoIn } from '../seed';

// Deadlines are instants: the same seeded tasks read the same in every timezone, except that the
// local date and time follow the viewer's zone. Expected texts are computed from the instants.
test('the same deadlines show the same badges and each viewer’s local time', async ({
  browser,
  baseURL,
  request,
}) => {
  const overdueAt = isoIn(-2 * DAY);
  const soonAt = isoIn(2 * HOUR);
  await createTodo(request, { title: 'Zones demo: overdue task', dueAt: overdueAt });
  await createTodo(request, { title: 'Zones demo: due soon task', dueAt: soonAt });

  const zones = [
    { timezoneId: 'America/New_York', step: 1, place: 'New York' },
    { timezoneId: 'Asia/Tokyo', step: 2, place: 'Tokyo' },
  ];
  const seen: string[] = [];
  for (const { timezoneId, step, place } of zones) {
    const context = await browser.newContext({
      baseURL,
      locale: 'en-US',
      timezoneId,
      viewport: { width: 1100, height: 760 },
    });
    try {
      const page = await context.newPage();
      await page.goto('/');
      const tasks = page.getByRole('list', { name: 'Tasks' });
      const overdueRow = tasks.getByRole('listitem').filter({ hasText: 'Zones demo: overdue task' });
      const soonRow = tasks.getByRole('listitem').filter({ hasText: 'Zones demo: due soon task' });

      await expect(overdueRow.getByText(deadlineText(overdueAt, timezoneId))).toBeVisible();
      await expect(overdueRow.getByText('Overdue', { exact: true })).toBeVisible();
      await expect(overdueRow.getByText('Due soon', { exact: true })).toHaveCount(0);
      await expect(soonRow.getByText(deadlineText(soonAt, timezoneId))).toBeVisible();
      await expect(soonRow.getByText('Due soon', { exact: true })).toBeVisible();
      await expect(soonRow.getByText('Overdue', { exact: true })).toHaveCount(0);
      seen.push(deadlineText(soonAt, timezoneId));

      await frame(
        page,
        'two-timezones',
        step,
        `Viewed from ${place} (${timezoneId}): the same Overdue and Due soon badges, with the deadlines in local time.`,
        'ui/task-list-with-tasks',
      );
    } finally {
      await context.close();
    }
  }
  // Tokyo is 13 or 14 hours ahead of New York, so the two local readings of one instant differ.
  expect(seen[0]).not.toEqual(seen[1]);
});
