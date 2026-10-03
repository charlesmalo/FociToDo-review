import { expect, test } from '@playwright/test';
import { frame } from '../frame';
import { createTodo } from '../seed';

// Brief: Complete and Incomplete.
test("ticking a task's checkbox completes it, unticking marks it incomplete again", async ({
  page,
  request,
}) => {
  await createTodo(request, { title: 'Complete demo: wash the car' });

  await page.goto('/');
  // A plain .click() rather than .check(): completing is an async mutation (the checkbox's
  // `checked` prop follows the fetched todo, not an optimistic local toggle), so the control
  // doesn't settle into its new state within .check()'s own immediate post-click verification.
  // The explicit expect() below retries until the mutation and refetch have landed.
  await page
    .getByRole('checkbox', { name: 'Mark "Complete demo: wash the car" complete' })
    .click();
  await expect(
    page.getByRole('checkbox', { name: 'Mark "Complete demo: wash the car" incomplete' }),
  ).toBeChecked();
  await frame(page, 'complete', 1, 'Ticking the checkbox marks the task completed.', 'ui/task-list-with-tasks');

  await page
    .getByRole('checkbox', { name: 'Mark "Complete demo: wash the car" incomplete' })
    .click();
  await expect(
    page.getByRole('checkbox', { name: 'Mark "Complete demo: wash the car" complete' }),
  ).not.toBeChecked();
  await frame(page, 'complete', 2, 'Unticking it again marks the task incomplete.', 'ui/task-list-with-tasks');
});
