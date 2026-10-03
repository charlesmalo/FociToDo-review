import { expect, test } from '@playwright/test';
import { frame } from '../frame';
import { DAY, createTodo, isoIn } from '../seed';

// Brief: Update title/description/due date.
test("editing a task's title shows the prefilled form, then the saved title in its details", async ({
  page,
  request,
}) => {
  const dueAt = isoIn(10 * DAY);
  await createTodo(request, {
    title: 'Edit demo: original title',
    description: 'Receipts in the blue folder',
    dueAt,
  });

  await page.goto('/');
  await page.getByRole('button', { name: 'Edit demo: original title' }).click();
  await expect(page.getByRole('dialog', { name: 'Task details' })).toBeVisible();

  await page.getByRole('button', { name: 'Edit' }).click();
  const editDialog = page.getByRole('dialog', { name: 'Edit task' });
  await expect(editDialog).toBeVisible();
  await expect(editDialog.getByLabel('Title')).toHaveValue('Edit demo: original title');
  await expect(editDialog.getByLabel('Description')).toHaveValue('Receipts in the blue folder');
  // The page runs in UTC, so the form shows the instant's UTC date and time.
  await expect(editDialog.getByLabel('Due date')).toHaveValue(dueAt.slice(0, 10));
  await expect(editDialog.getByLabel('Due time')).toHaveValue(dueAt.slice(11, 16));
  await frame(
    page,
    'edit',
    1,
    "Edit opens the form prefilled with the task's current values.",
    'ui/dialog-edit-task',
  );

  await editDialog.getByLabel('Title').fill('Edit demo: updated title');
  await editDialog.getByRole('button', { name: 'Save' }).click();

  const detailsDialog = page.getByRole('dialog', { name: 'Task details' });
  await expect(detailsDialog).toBeVisible();
  await expect(detailsDialog.getByText('Edit demo: updated title')).toBeVisible();
  await frame(
    page,
    'edit',
    2,
    'After Save, the task details show the new title.',
    'ui/dialog-task-details',
  );
});
