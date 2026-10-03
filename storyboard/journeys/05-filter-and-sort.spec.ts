import { expect, test } from '@playwright/test';
import { frame } from '../frame';
import { createTodo, utcDate } from '../seed';

// Brief: filter (completed / incomplete / overdue, optional) and sort (title, optional).
test('filters and sorting: the Overdue filter, "no match", and sorting by title', async ({
  page,
  request,
}) => {
  const prefix = `storyboard-filter-${Date.now()}-`;
  await createTodo(request, { title: `${prefix}overdue-one`, dueDate: utcDate(-4) });
  await createTodo(request, { title: `${prefix}overdue-two`, dueDate: utcDate(-6) });
  await createTodo(request, { title: `${prefix}apple`, dueDate: utcDate(20) });
  await createTodo(request, { title: `${prefix}Banana` });
  await createTodo(request, { title: `${prefix}cherry` });

  await page.goto('/');
  await expect(page.getByLabel('Show')).toBeVisible();
  await expect(page.getByLabel('Sort by')).toBeVisible();
  await expect(page.getByLabel('Order')).toBeVisible();
  await frame(
    page,
    'filter-and-sort',
    1,
    'The Show, Sort by and Order controls above the list.',
    'ui/filters-and-sorting',
  );

  const tasks = page.getByRole('list', { name: 'Tasks' });

  await page.getByLabel('Show').selectOption('Overdue');
  await expect(page.getByRole('button', { name: `${prefix}overdue-one` })).toBeVisible();
  await expect(page.getByRole('button', { name: `${prefix}overdue-two` })).toBeVisible();
  await expect(page.getByRole('button', { name: `${prefix}apple` })).toHaveCount(0);
  await frame(
    page,
    'filter-and-sort',
    2,
    'Show: Overdue lists only the overdue tasks.',
    'ui/task-list-with-tasks',
  );

  // Tick every currently overdue task (not only the two seeded above — any left over from an
  // earlier journey counts too), recording each title so it can be unticked again afterwards.
  // A plain .click() rather than .check(): completing is an async mutation (the checkbox's
  // `checked` prop follows the fetched todo, not an optimistic local toggle), so the control
  // doesn't settle into its new state within .check()'s own immediate post-click verification —
  // the toHaveCount() retry below waits for the mutation and the Overdue refetch instead.
  const overdueCheckboxes = tasks.getByRole('checkbox');
  const overdueCount = await overdueCheckboxes.count();
  const overdueTitles: string[] = [];
  for (let i = 0; i < overdueCount; i += 1) {
    const label = await overdueCheckboxes.nth(0).getAttribute('aria-label');
    if (label === null) throw new Error('overdue row checkbox has no aria-label');
    overdueTitles.push(label.slice('Mark "'.length, label.length - '" complete'.length));
    await overdueCheckboxes.nth(0).click();
    await expect(overdueCheckboxes).toHaveCount(overdueCount - i - 1);
  }
  await expect(page.getByText('No tasks match this filter.')).toBeVisible();
  await frame(
    page,
    'filter-and-sort',
    3,
    'Completing every overdue task leaves none matching Show: Overdue.',
    'ui/task-list-no-match',
  );

  await page.getByLabel('Show').selectOption('All');
  for (const title of overdueTitles) {
    await page.getByRole('checkbox', { name: `Mark "${title}" incomplete` }).click();
    await expect(page.getByRole('checkbox', { name: `Mark "${title}" complete` })).toBeVisible();
  }

  await page.getByLabel('Sort by').selectOption('Title');
  await page.getByLabel('Order').selectOption('Ascending');
  const allTitles = await tasks.getByRole('button').allTextContents();
  const mine = allTitles.filter((title) => title.startsWith(prefix));
  expect(mine).toEqual([
    `${prefix}apple`,
    `${prefix}Banana`,
    `${prefix}cherry`,
    `${prefix}overdue-one`,
    `${prefix}overdue-two`,
  ]);
  await frame(
    page,
    'filter-and-sort',
    4,
    'Sort by Title, Ascending orders titles case-insensitively.',
    'ui/task-list-with-tasks',
  );
});
