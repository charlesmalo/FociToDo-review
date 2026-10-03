# Storyboard — FociToDo @ 5c43da9c1490a28e17daf8842e0e01958b737ad1

22 frames across 11 journeys; every wireframe in the app's docs/ui.md is paired with at least one frame. Each frame was captured only after the step's assertions passed.

## add

| # | Wireframe | Running app | What happened |
|---|---|---|---|
| 1 | <img src="wireframes/task-list-empty.svg" width="360" alt="Task list — empty"> | <img src="frames/add-01.png" width="420" alt="First visit: the list is empty and invites adding a task."> | First visit: the list is empty and invites adding a task. |
| 2 | <img src="wireframes/dialog-new-task.svg" width="360" alt="Dialog — new task"> | <img src="frames/add-02.png" width="420" alt="&quot;+ New task&quot; opens the New task dialog."> | "+ New task" opens the New task dialog. |
| 3 | <img src="wireframes/task-list-with-tasks.svg" width="360" alt="Task list — with tasks"> | <img src="frames/add-03.png" width="420" alt="After &quot;Add task&quot; the new task is in the list with its due date."> | After "Add task" the new task is in the list with its due date. |

## list-and-view

| # | Wireframe | Running app | What happened |
|---|---|---|---|
| 1 | <img src="wireframes/task-list-with-tasks.svg" width="360" alt="Task list — with tasks"> | <img src="frames/list-and-view-01.png" width="420" alt="The list shows an overdue task, a future task and a completed task."> | The list shows an overdue task, a future task and a completed task. |
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
| 1 | <img src="wireframes/filters-and-sorting.svg" width="360" alt="Filters and sorting"> | <img src="frames/filter-and-sort-01.png" width="420" alt="The Show, Sort by and Order controls above the list."> | The Show, Sort by and Order controls above the list. |
| 2 | <img src="wireframes/task-list-with-tasks.svg" width="360" alt="Task list — with tasks"> | <img src="frames/filter-and-sort-02.png" width="420" alt="Show: Overdue lists only the overdue tasks."> | Show: Overdue lists only the overdue tasks. |
| 3 | <img src="wireframes/task-list-no-match.svg" width="360" alt="Task list — no match"> | <img src="frames/filter-and-sort-03.png" width="420" alt="Completing every overdue task leaves none matching Show: Overdue."> | Completing every overdue task leaves none matching Show: Overdue. |
| 4 | <img src="wireframes/task-list-with-tasks.svg" width="360" alt="Task list — with tasks"> | <img src="frames/filter-and-sort-04.png" width="420" alt="Sort by Title, Ascending orders titles case-insensitively."> | Sort by Title, Ascending orders titles case-insensitively. |

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
