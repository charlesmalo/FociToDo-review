import { expect, test } from '@playwright/test';
import { frame } from '../frame';
import { createTodo, utcDate } from '../seed';

// Brief: List (title, due date, completion status) and View by id.
test("list shows an overdue, a future and a completed task; view the overdue task's details", async ({
  page,
  request,
}) => {
  const overdueDate = utcDate(-2);
  const futureDate = utcDate(5);

  await createTodo(request, {
    title: 'List demo: overdue task',
    description: 'Two days overdue',
    dueDate: overdueDate,
  });
  await createTodo(request, { title: 'List demo: future task', dueDate: futureDate });
  const completed = await createTodo(request, { title: 'List demo: completed task' });
  const completeResponse = await request.post(`/api/todos/${completed.id}/complete`);
  if (!completeResponse.ok()) {
    throw new Error(`seed: complete failed with ${completeResponse.status()}`);
  }

  await page.goto('/');
  await expect(page.getByRole('button', { name: 'List demo: overdue task' })).toBeVisible();
  await expect(page.getByText(`Due ${overdueDate}`)).toBeVisible();
  await expect(page.getByRole('button', { name: 'List demo: future task' })).toBeVisible();
  await expect(page.getByRole('button', { name: 'List demo: completed task' })).toBeVisible();
  await expect(
    page.getByRole('checkbox', { name: 'Mark "List demo: completed task" incomplete' }),
  ).toBeChecked();
  await frame(
    page,
    'list-and-view',
    1,
    'The list shows an overdue task, a future task and a completed task.',
    'ui/task-list-with-tasks',
  );

  await page.getByRole('button', { name: 'List demo: overdue task' }).click();
  const dialog = page.getByRole('dialog', { name: 'Task details' });
  await expect(dialog).toBeVisible();
  await expect(dialog.getByText('List demo: overdue task')).toBeVisible();
  await expect(dialog.getByText('Not completed')).toBeVisible();
  await frame(
    page,
    'list-and-view',
    2,
    'Opening the overdue task shows its details, marked Overdue.',
    'ui/dialog-task-details',
  );
});
