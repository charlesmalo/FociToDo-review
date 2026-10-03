import { expect, test } from '@playwright/test';
import { frame } from '../frame';
import { createTodo } from '../seed';

// Brief: Update — a lost-update conflict surfaced to the user (spec §6 / api: Conventions).
test('editing a task that changes elsewhere shows the changed-elsewhere notice with the edit kept', async ({
  page,
  request,
}) => {
  const created = await createTodo(request, { title: 'Conflict demo: original title' });

  await page.goto('/');
  await page.getByRole('button', { name: 'Conflict demo: original title' }).click();
  await page.getByRole('button', { name: 'Edit' }).click();
  const dialog = page.getByRole('dialog', { name: 'Edit task' });
  await expect(dialog).toBeVisible();
  await dialog.getByLabel('Title').fill('Conflict demo: my edited title');

  // Someone else changes the same task through the API, with the version the dialog still has.
  const patchResponse = await request.patch(`/api/todos/${created.id}`, {
    data: { title: 'Conflict demo: changed by someone else' },
    headers: { 'If-Match': `"${created.version}"` },
  });
  if (!patchResponse.ok()) {
    throw new Error(`seed: PATCH failed with ${patchResponse.status()}`);
  }

  await dialog.getByRole('button', { name: 'Save' }).click();
  await expect(
    dialog.getByText(
      'This task was changed elsewhere and has been reloaded. Your edits are kept — review and save again.',
    ),
  ).toBeVisible();
  await expect(dialog.getByLabel('Title')).toHaveValue('Conflict demo: my edited title');
  await frame(
    page,
    'conflict',
    1,
    'Save after a conflicting change shows the changed-elsewhere notice with the edit kept.',
    'ui/dialog-changed-elsewhere',
  );
});
