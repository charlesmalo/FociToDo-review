import { expect, test } from '@playwright/test';
import { frame } from '../frame';
import { DAY, HOUR, createTodo, isoIn } from '../seed';

// Brief: filter (all / completed / incomplete / overdue) and sort (title, optional).
test('filters and sorting: every Show value, "no match", and sorting by title and by due', async ({
  page,
  request,
}) => {
  const prefix = `storyboard-filter-${Date.now()}-`;
  await createTodo(request, { title: `${prefix}overdue-one`, dueAt: isoIn(-4 * DAY) });
  await createTodo(request, { title: `${prefix}overdue-two`, dueAt: isoIn(-6 * DAY) });
  await createTodo(request, { title: `${prefix}soon`, dueAt: isoIn(2 * HOUR) });
  await createTodo(request, { title: `${prefix}apple`, dueAt: isoIn(20 * DAY) });
  await createTodo(request, { title: `${prefix}Banana` });
  await createTodo(request, { title: `${prefix}cherry` });
  const done = await createTodo(request, { title: `${prefix}done` });
  const completeResponse = await request.post(`/api/todos/${done.id}/complete`);
  if (!completeResponse.ok()) {
    throw new Error(`seed: complete failed with ${completeResponse.status()}`);
  }

  await page.goto('/');
  // F-92 regression guard: each control's accessible name is exactly its own label,
  // never the label plus every option's text (the real-browser-only defect the storyboard's
  // Playwright/Chromium run found and PR #20 fixed).
  await expect(page.getByRole('combobox', { name: 'Show', exact: true })).toBeVisible();
  await expect(page.getByRole('combobox', { name: 'Sort by', exact: true })).toBeVisible();
  await expect(page.getByRole('combobox', { name: 'Order', exact: true })).toBeVisible();
  await frame(
    page,
    'filter-and-sort',
    1,
    'The Show, Sort by and Order controls, each named by its label alone.',
    'ui/filters-and-sorting',
  );

  const tasks = page.getByRole('list', { name: 'Tasks' });

  await page.getByLabel('Show').selectOption('Completed');
  await expect(page.getByRole('button', { name: `${prefix}done` })).toBeVisible();
  await expect(page.getByRole('button', { name: `${prefix}apple` })).toHaveCount(0);
  await frame(
    page,
    'filter-and-sort',
    2,
    'Show: Completed lists only the completed task.',
    'ui/task-list-with-tasks',
  );

  await page.getByLabel('Show').selectOption('Incomplete');
  await expect(page.getByRole('button', { name: `${prefix}overdue-one` })).toBeVisible();
  await expect(page.getByRole('button', { name: `${prefix}apple` })).toBeVisible();
  await expect(page.getByRole('button', { name: `${prefix}done` })).toHaveCount(0);
  await frame(
    page,
    'filter-and-sort',
    3,
    'Show: Incomplete lists every task not yet completed.',
    'ui/task-list-with-tasks',
  );

  await page.getByLabel('Show').selectOption('Overdue');
  await expect(page.getByRole('button', { name: `${prefix}overdue-one` })).toBeVisible();
  await expect(page.getByRole('button', { name: `${prefix}overdue-two` })).toBeVisible();
  await expect(page.getByRole('button', { name: `${prefix}apple` })).toHaveCount(0);
  // Every row the Overdue filter lists must itself carry the Overdue badge.
  const overdueRowCount = await tasks.getByRole('listitem').count();
  expect(overdueRowCount).toBeGreaterThan(0);
  await expect(tasks.getByText('Overdue', { exact: true })).toHaveCount(overdueRowCount);
  await frame(
    page,
    'filter-and-sort',
    4,
    'Show: Overdue lists only the overdue tasks, each carrying the Overdue badge.',
    'ui/task-list-with-tasks',
  );

  await page.getByLabel('Show').selectOption('Due soon');
  await expect(page.getByRole('button', { name: `${prefix}soon` })).toBeVisible();
  await expect(page.getByRole('button', { name: `${prefix}apple` })).toHaveCount(0);
  await expect(page.getByRole('button', { name: `${prefix}overdue-one` })).toHaveCount(0);
  await expect(page.getByRole('button', { name: `${prefix}done` })).toHaveCount(0);
  // Every row the Due soon filter lists must itself carry the Due soon badge, and none is Overdue.
  const dueSoonRowCount = await tasks.getByRole('listitem').count();
  expect(dueSoonRowCount).toBeGreaterThan(0);
  await expect(tasks.getByText('Due soon', { exact: true })).toHaveCount(dueSoonRowCount);
  await expect(tasks.getByText('Overdue', { exact: true })).toHaveCount(0);
  await frame(
    page,
    'filter-and-sort',
    5,
    'Show: Due soon lists only incomplete tasks due within 24 hours, each carrying the Due soon badge.',
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
    6,
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
    `${prefix}done`,
    `${prefix}overdue-one`,
    `${prefix}overdue-two`,
    `${prefix}soon`,
  ]);
  await frame(
    page,
    'filter-and-sort',
    7,
    'Sort by Title, Ascending orders titles case-insensitively.',
    'ui/task-list-with-tasks',
  );

  await page.getByLabel('Sort by').selectOption('Due');
  await page.getByLabel('Order').selectOption('Ascending');
  // Tasks with a deadline come in deadline order; the seeded ones were due -6, -4, +2 h and +20 days.
  const dueOrder = [`${prefix}overdue-two`, `${prefix}overdue-one`, `${prefix}soon`, `${prefix}apple`];
  await expect(async () => {
    const titles = await tasks.getByRole('button').allTextContents();
    expect(titles.filter((title) => dueOrder.includes(title))).toEqual(dueOrder);
  }).toPass();
  await frame(
    page,
    'filter-and-sort',
    8,
    'Sort by Due, Ascending orders tasks by deadline, earliest first.',
    'ui/task-list-with-tasks',
  );
});
