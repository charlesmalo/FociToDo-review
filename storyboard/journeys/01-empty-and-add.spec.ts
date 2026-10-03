import { expect, test } from '@playwright/test';
import { frame } from '../frame';

// Brief: Add. Runs first on the fresh database, so the list starts genuinely empty.
test('empty list, then add a task', async ({ page }) => {
  await page.goto('/');
  await expect(page.getByText('No tasks yet. Add your first one.')).toBeVisible();
  await frame(
    page,
    'add',
    1,
    'First visit: the list is empty and invites adding a task.',
    'ui/task-list-empty',
  );

  await page.getByRole('button', { name: '+ New task' }).click();
  const dialog = page.getByRole('dialog', { name: 'New task' });
  await expect(dialog).toBeVisible();
  await frame(page, 'add', 2, '"+ New task" opens the New task dialog.', 'ui/dialog-new-task');

  // Scoped to the dialog: the page's "Sort by" filter select is also labelled with text that
  // contains "Title" and "Due date" (its own label plus its options' text), so an unscoped
  // getByLabel('Title') / getByLabel('Due date') would match both and throw a strict-mode error.
  await dialog.getByLabel('Title').fill('Buy oat milk');
  await dialog.getByLabel('Due date').fill('2030-01-15');
  await dialog.getByRole('button', { name: 'Add task' }).click();
  await expect(page.getByRole('button', { name: 'Buy oat milk' })).toBeVisible();
  await frame(
    page,
    'add',
    3,
    'After "Add task" the new task is in the list with its due date.',
    'ui/task-list-with-tasks',
  );
});
