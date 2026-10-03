# Storyboard — FociToDo @ 3dbb2ebc374e2e783f1164e35b1104224cdd6033

30 frames across 12 journeys; every wireframe in the app's docs/ui.md is paired with at least one frame. Each frame was captured only after the step's assertions passed.

## add

| # | Wireframe | Running app | What happened |
|---|---|---|---|
| 1 | <img src="wireframes/task-list-empty.svg" width="360" alt="Task list — empty"> | <img src="frames/add-01.png" width="420" alt="First visit: the list is empty and invites adding a task."> | First visit: the list is empty and invites adding a task. |
| 2 | <img src="wireframes/dialog-new-task.svg" width="360" alt="Dialog — new task"> | <img src="frames/add-02.png" width="420" alt="&quot;+ New task&quot; opens the New task dialog."> | "+ New task" opens the New task dialog. |
| 3 | <img src="wireframes/dialog-new-task.svg" width="360" alt="Dialog — new task"> | <img src="frames/add-03.png" width="420" alt="Entering a Due date prefills the Due time with 17:00."> | Entering a Due date prefills the Due time with 17:00. |
| 4 | <img src="wireframes/task-list-with-tasks.svg" width="360" alt="Task list — with tasks"> | <img src="frames/add-04.png" width="420" alt="After &quot;Add task&quot; the new task is in the list with its due date and time (17:00 UTC here)."> | After "Add task" the new task is in the list with its due date and time (17:00 UTC here). |

## list-and-view

| # | Wireframe | Running app | What happened |
|---|---|---|---|
| 1 | <img src="wireframes/task-list-with-tasks.svg" width="360" alt="Task list — with tasks"> | <img src="frames/list-and-view-01.png" width="420" alt="The list shows an overdue task, a due-soon task, a future task and a completed task, each deadline with its date and time."> | The list shows an overdue task, a due-soon task, a future task and a completed task, each deadline with its date and time. |
| 2 | <img src="wireframes/dialog-task-details.svg" width="360" alt="Dialog — task details"> | <img src="frames/list-and-view-02.png" width="420" alt="Opening the overdue task shows its details, marked Overdue."> | Opening the overdue task shows its details, marked Overdue. |

## edit

| # | Wireframe | Running app | What happened |
|---|---|---|---|
| 1 | <img src="wireframes/dialog-edit-task.svg" width="360" alt="Dialog — edit task"> | <img src="frames/edit-01.png" width="420" alt="Edit opens the form prefilled with the task's current values."> | Edit opens the form prefilled with the task's current values. |
| 2 | <img src="wireframes/dialog-task-details.svg" width="360" alt="Dialog — task details"> | <img src="frames/edit-02.png" width="420" alt="After Save, the task details show the new title."> | After Save, the task details show the new title. |

## complete

| # | Wireframe | Running app | What happened |
|---|---|---|---|
| 1 | <img src="wireframes/task-list-with-tasks.svg" width="360" alt="Task list — with tasks"> | <img src="frames/complete-01.png" width="420" alt="Ticking the checkbox marks the task completed."> | Ticking the checkbox marks the task completed. |
| 2 | <img src="wireframes/task-list-with-tasks.svg" width="360" alt="Task list — with tasks"> | <img src="frames/complete-02.png" width="420" alt="Unticking it again marks the task incomplete."> | Unticking it again marks the task incomplete. |

## filter-and-sort

| # | Wireframe | Running app | What happened |
|---|---|---|---|
| 1 | <img src="wireframes/filters-and-sorting.svg" width="360" alt="Filters and sorting"> | <img src="frames/filter-and-sort-01.png" width="420" alt="The Show, Sort by and Order controls, each named by its label alone."> | The Show, Sort by and Order controls, each named by its label alone. |
| 2 | <img src="wireframes/task-list-with-tasks.svg" width="360" alt="Task list — with tasks"> | <img src="frames/filter-and-sort-02.png" width="420" alt="Show: Completed lists only the completed task."> | Show: Completed lists only the completed task. |
| 3 | <img src="wireframes/task-list-with-tasks.svg" width="360" alt="Task list — with tasks"> | <img src="frames/filter-and-sort-03.png" width="420" alt="Show: Incomplete lists every task not yet completed."> | Show: Incomplete lists every task not yet completed. |
| 4 | <img src="wireframes/task-list-with-tasks.svg" width="360" alt="Task list — with tasks"> | <img src="frames/filter-and-sort-04.png" width="420" alt="Show: Overdue lists only the overdue tasks, each carrying the Overdue badge."> | Show: Overdue lists only the overdue tasks, each carrying the Overdue badge. |
| 5 | <img src="wireframes/task-list-with-tasks.svg" width="360" alt="Task list — with tasks"> | <img src="frames/filter-and-sort-05.png" width="420" alt="Show: Due soon lists only incomplete tasks due within 24 hours, each carrying the Due soon badge."> | Show: Due soon lists only incomplete tasks due within 24 hours, each carrying the Due soon badge. |
| 6 | <img src="wireframes/task-list-no-match.svg" width="360" alt="Task list — no match"> | <img src="frames/filter-and-sort-06.png" width="420" alt="Completing every overdue task leaves none matching Show: Overdue."> | Completing every overdue task leaves none matching Show: Overdue. |
| 7 | <img src="wireframes/task-list-with-tasks.svg" width="360" alt="Task list — with tasks"> | <img src="frames/filter-and-sort-07.png" width="420" alt="Sort by Title, Ascending orders titles case-insensitively."> | Sort by Title, Ascending orders titles case-insensitively. |
| 8 | <img src="wireframes/task-list-with-tasks.svg" width="360" alt="Task list — with tasks"> | <img src="frames/filter-and-sort-08.png" width="420" alt="Sort by Due, Ascending orders tasks by deadline, earliest first."> | Sort by Due, Ascending orders tasks by deadline, earliest first. |

## validation

| # | Wireframe | Running app | What happened |
|---|---|---|---|
| 1 | <img src="wireframes/dialog-new-task-with-errors.svg" width="360" alt="Dialog — new task with errors"> | <img src="frames/validation-01.png" width="420" alt="Submitting with an empty title shows &quot;Title is required&quot;."> | Submitting with an empty title shows "Title is required". |

## conflict

| # | Wireframe | Running app | What happened |
|---|---|---|---|
| 1 | <img src="wireframes/dialog-changed-elsewhere.svg" width="360" alt="Dialog — changed elsewhere"> | <img src="frames/conflict-01.png" width="420" alt="Save after a conflicting change shows the changed-elsewhere notice with the edit kept."> | Save after a conflicting change shows the changed-elsewhere notice with the edit kept. |

## deleted-elsewhere

| # | Wireframe | Running app | What happened |
|---|---|---|---|
| 1 | <img src="wireframes/dialog-task-no-longer-exists.svg" width="360" alt="Dialog — task no longer exists"> | <img src="frames/deleted-elsewhere-01.png" width="420" alt="Opening a task deleted elsewhere shows &quot;This task no longer exists.&quot;"> | Opening a task deleted elsewhere shows "This task no longer exists." |

## delete

| # | Wireframe | Running app | What happened |
|---|---|---|---|
| 1 | <img src="wireframes/dialog-delete-confirmation.svg" width="360" alt="Dialog — delete confirmation"> | <img src="frames/delete-01.png" width="420" alt="Delete asks &quot;Delete this task?&quot; before removing it."> | Delete asks "Delete this task?" before removing it. |
| 2 | <img src="wireframes/task-list-with-tasks.svg" width="360" alt="Task list — with tasks"> | <img src="frames/delete-02.png" width="420" alt="After &quot;Yes, delete&quot; the task is gone from the list."> | After "Yes, delete" the task is gone from the list. |

## reload

| # | Wireframe | Running app | What happened |
|---|---|---|---|
| 1 | <img src="wireframes/task-list-with-tasks.svg" width="360" alt="Task list — with tasks"> | <img src="frames/reload-01.png" width="420" alt="Reloading the page shows the same tasks as before."> | Reloading the page shows the same tasks as before. |

## loading-and-error

| # | Wireframe | Running app | What happened |
|---|---|---|---|
| 1 | <img src="wireframes/task-list-loading.svg" width="360" alt="Task list — loading"> | <img src="frames/loading-and-error-01.png" width="420" alt="While the list request is in flight: &quot;Loading tasks…&quot;."> | While the list request is in flight: "Loading tasks…". |
| 2 | <img src="wireframes/task-list-load-error.svg" width="360" alt="Task list — load error"> | <img src="frames/loading-and-error-02.png" width="420" alt="After the retries fail: the error banner with Retry."> | After the retries fail: the error banner with Retry. |
| 3 | <img src="wireframes/task-list-with-tasks.svg" width="360" alt="Task list — with tasks"> | <img src="frames/loading-and-error-03.png" width="420" alt="Retry succeeds and the list loads."> | Retry succeeds and the list loads. |

## two-timezones

| # | Wireframe | Running app | What happened |
|---|---|---|---|
| 1 | <img src="wireframes/task-list-with-tasks.svg" width="360" alt="Task list — with tasks"> | <img src="frames/two-timezones-01.png" width="420" alt="Viewed from New York (America/New_York): the same Overdue and Due soon badges, with the deadlines in local time."> | Viewed from New York (America/New_York): the same Overdue and Due soon badges, with the deadlines in local time. |
| 2 | <img src="wireframes/dialog-new-task.svg" width="360" alt="Dialog — new task"> | <img src="frames/two-timezones-02.png" width="420" alt="In the New York browser: a task entered with Due date 2030-01-15 and Due time 09:30 (local)."> | In the New York browser: a task entered with Due date 2030-01-15 and Due time 09:30 (local). |
| 3 | <img src="wireframes/task-list-with-tasks.svg" width="360" alt="Task list — with tasks"> | <img src="frames/two-timezones-03.png" width="420" alt="Viewed from Tokyo (Asia/Tokyo): the same Overdue and Due soon badges, with the deadlines in local time."> | Viewed from Tokyo (Asia/Tokyo): the same Overdue and Due soon badges, with the deadlines in local time. |
