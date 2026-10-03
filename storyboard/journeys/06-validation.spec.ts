import { expect, test } from '@playwright/test';
import { frame } from '../frame';

// Brief: Add — validation.
test('adding a task with an empty title shows a validation error', async ({ page }) => {
  await page.goto('/');
  await page.getByRole('button', { name: '+ New task' }).click();
  const dialog = page.getByRole('dialog', { name: 'New task' });
  await expect(dialog).toBeVisible();

  await dialog.getByRole('button', { name: 'Add task' }).click();
  await expect(dialog.getByText('Title is required')).toBeVisible();
  await frame(
    page,
    'validation',
    1,
    'Submitting with an empty title shows "Title is required".',
    'ui/dialog-new-task-with-errors',
  );
});
