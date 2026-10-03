import { expect, test } from '@playwright/test';
import { frame } from '../frame';
import { createTodo } from '../seed';

// Brief: Delete — a task opened from a stale list after it was removed elsewhere.
test('a task deleted elsewhere shows "This task no longer exists." when opened', async ({
  page,
  request,
}) => {
  const created = await createTodo(request, { title: 'Deleted demo: disappearing task' });

  await page.goto('/');
  await expect(page.getByRole('button', { name: 'Deleted demo: disappearing task' })).toBeVisible();

  const deleteResponse = await request.delete(`/api/todos/${created.id}`, {
    headers: { 'If-Match': `"${created.version}"` },
  });
  if (!deleteResponse.ok()) {
    throw new Error(`seed: DELETE failed with ${deleteResponse.status()}`);
  }

  await page.getByRole('button', { name: 'Deleted demo: disappearing task' }).click();
  await expect(
    page.getByRole('dialog', { name: 'Task details' }).getByText('This task no longer exists.'),
  ).toBeVisible();
  await frame(
    page,
    'deleted-elsewhere',
    1,
    'Opening a task deleted elsewhere shows "This task no longer exists."',
    'ui/dialog-task-no-longer-exists',
  );
});
