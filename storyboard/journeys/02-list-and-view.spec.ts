import { expect, test } from '@playwright/test';
import { frame } from '../frame';
import { DAY, HOUR, createTodo, deadlineText, isoIn } from '../seed';

// Brief: List (title, due date, completion status) and View by id.
test("list shows an overdue, a due-soon, a future and a completed task; view the overdue task's details", async ({
  page,
  request,
}) => {
  // Deadlines relative to now, far from the 0 h and 24 h boundaries; the page runs in UTC.
  const overdueAt = isoIn(-2 * DAY);
  const soonAt = isoIn(2 * HOUR);
  const futureAt = isoIn(10 * DAY);

  await createTodo(request, {
    title: 'List demo: overdue task',
    description: 'Two days overdue',
    dueAt: overdueAt,
  });
  await createTodo(request, { title: 'List demo: due soon task', dueAt: soonAt });
  await createTodo(request, { title: 'List demo: future task', dueAt: futureAt });
  const completed = await createTodo(request, { title: 'List demo: completed task' });
  const completeResponse = await request.post(`/api/todos/${completed.id}/complete`);
  if (!completeResponse.ok()) {
    throw new Error(`seed: complete failed with ${completeResponse.status()}`);
  }

  await page.goto('/');
  const tasks = page.getByRole('list', { name: 'Tasks' });
  const overdueRow = tasks.getByRole('listitem').filter({ hasText: 'List demo: overdue task' });
  await expect(page.getByRole('button', { name: 'List demo: overdue task' })).toBeVisible();
  await expect(overdueRow.getByText(deadlineText(overdueAt, 'UTC'))).toBeVisible();
  await expect(overdueRow.getByText('Overdue', { exact: true })).toBeVisible();
  await expect(overdueRow.getByText('Due soon', { exact: true })).toHaveCount(0);
  const soonRow = tasks.getByRole('listitem').filter({ hasText: 'List demo: due soon task' });
  await expect(soonRow.getByText(deadlineText(soonAt, 'UTC'))).toBeVisible();
  await expect(soonRow.getByText('Due soon', { exact: true })).toBeVisible();
  await expect(soonRow.getByText('Overdue', { exact: true })).toHaveCount(0);
  const futureRow = tasks.getByRole('listitem').filter({ hasText: 'List demo: future task' });
  await expect(futureRow.getByText(deadlineText(futureAt, 'UTC'))).toBeVisible();
  await expect(futureRow.getByText('Overdue', { exact: true })).toHaveCount(0);
  await expect(futureRow.getByText('Due soon', { exact: true })).toHaveCount(0);
  await expect(page.getByRole('button', { name: 'List demo: future task' })).toBeVisible();
  await expect(page.getByRole('button', { name: 'List demo: completed task' })).toBeVisible();
  await expect(
    page.getByRole('checkbox', { name: 'Mark "List demo: completed task" incomplete' }),
  ).toBeChecked();
  await frame(
    page,
    'list-and-view',
    1,
    'The list shows an overdue task, a due-soon task, a future task and a completed task, each deadline with its date and time.',
    'ui/task-list-with-tasks',
  );

  await page.getByRole('button', { name: 'List demo: overdue task' }).click();
  const dialog = page.getByRole('dialog', { name: 'Task details' });
  await expect(dialog).toBeVisible();
  await expect(dialog.getByText('List demo: overdue task')).toBeVisible();
  await expect(dialog.getByText('Not completed')).toBeVisible();
  await expect(dialog.getByText(deadlineText(overdueAt, 'UTC').replace(/^Due /, ''))).toBeVisible();
  await expect(dialog.getByText('Overdue', { exact: true })).toBeVisible();
  await frame(
    page,
    'list-and-view',
    2,
    'Opening the overdue task shows its details, marked Overdue.',
    'ui/dialog-task-details',
  );
});
