import { expect, test } from '@playwright/test';
import { frame } from '../frame';
import { createTodo } from '../seed';

// Brief: Delete.
test('deleting a task asks for confirmation, then removes it from the list', async ({
  page,
  request,
}) => {
  await createTodo(request, { title: 'Delete demo: task to remove' });

  await page.goto('/');
  await page.getByRole('button', { name: 'Delete demo: task to remove' }).click();
  await expect(page.getByRole('dialog', { name: 'Task details' })).toBeVisible();

  await page.getByRole('button', { name: 'Delete' }).click();
  const confirm = page.getByRole('group', { name: 'Confirm delete' });
  await expect(confirm.getByText('Delete this task?')).toBeVisible();
  await frame(
    page,
    'delete',
    1,
    'Delete asks "Delete this task?" before removing it.',
    'ui/dialog-delete-confirmation',
  );

  await confirm.getByRole('button', { name: 'Yes, delete' }).click();
  await expect(page.getByRole('dialog')).toHaveCount(0);
  await expect(page.getByRole('button', { name: 'Delete demo: task to remove' })).toHaveCount(0);
  await frame(
    page,
    'delete',
    2,
    'After "Yes, delete" the task is gone from the list.',
    'ui/task-list-with-tasks',
  );
});
