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

  // Entered in New York as 09:30 on 15 January 2030 (EST, UTC-5, a fixed fact of the timezone
  // database): the stored instant must be 14:30 UTC, which reads 11:30 PM that day in Tokyo.
  const enteredTitle = 'Zones demo: entered in New York';
  const enteredAt = '2030-01-15T14:30:00.000Z';

  const zones = [
    { timezoneId: 'America/New_York', step: 1, place: 'New York' },
    { timezoneId: 'Asia/Tokyo', step: 3, place: 'Tokyo' },
  ];
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

      await frame(
        page,
        'two-timezones',
        step,
        `Viewed from ${place} (${timezoneId}): the same Overdue and Due soon badges, with the deadlines in local time.`,
        'ui/task-list-with-tasks',
      );

      if (timezoneId === 'America/New_York') {
        await page.getByRole('button', { name: '+ New task' }).click();
        const dialog = page.getByRole('dialog', { name: 'New task' });
        await expect(dialog).toBeVisible();
        await dialog.getByLabel('Title').fill(enteredTitle);
        await dialog.getByLabel('Due date').fill('2030-01-15');
        await dialog.getByLabel('Due time').fill('09:30');
        await expect(dialog.getByLabel('Due date')).toHaveValue('2030-01-15');
        await expect(dialog.getByLabel('Due time')).toHaveValue('09:30');
        await frame(
          page,
          'two-timezones',
          2,
          'In the New York browser: a task entered with Due date 2030-01-15 and Due time 09:30 (local).',
          'ui/dialog-new-task',
        );
        await dialog.getByRole('button', { name: 'Add task' }).click();
        await expect(dialog).toBeHidden();

        // Black box: the stored instant is the New York wall-clock time converted to UTC.
        const response = await request.get('/api/todos');
        expect(response.ok()).toBe(true);
        const todos: { title: string; dueAt: string | null }[] = await response.json();
        const stored = todos.filter((todo) => todo.title === enteredTitle);
        expect(stored).toHaveLength(1);
        expect(stored[0].dueAt).toBe(enteredAt);
      }

      // Entered-task row: the same instant reads in each viewer's local time.
      const enteredRow = tasks.getByRole('listitem').filter({ hasText: enteredTitle });
      await expect(enteredRow.getByText(deadlineText(enteredAt, timezoneId))).toBeVisible();
    } finally {
      await context.close();
    }
  }});
