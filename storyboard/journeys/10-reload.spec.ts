import { expect, test } from '@playwright/test';
import { frame } from '../frame';
import { createTodo, utcDate } from '../seed';

// Brief: Persistence, as observed from the front end — the same list survives a reload.
test('reloading the page shows the same tasks', async ({ page, request }) => {
  await createTodo(request, {
    title: 'Reload demo: persists across reload',
    dueDate: utcDate(15),
  });

  await page.goto('/');
  await expect(page.getByRole('button', { name: 'Reload demo: persists across reload' })).toBeVisible();
  const tasks = page.getByRole('list', { name: 'Tasks' });
  const beforeTitles = await tasks.getByRole('button').allTextContents();

  await page.reload();
  await expect(page.getByRole('button', { name: 'Reload demo: persists across reload' })).toBeVisible();
  const afterTitles = await tasks.getByRole('button').allTextContents();
  expect(afterTitles).toEqual(beforeTitles);
  await frame(
    page,
    'reload',
    1,
    'Reloading the page shows the same tasks as before.',
    'ui/task-list-with-tasks',
  );
});
