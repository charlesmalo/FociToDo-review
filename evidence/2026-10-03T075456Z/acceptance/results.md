# Acceptance — https://github.com/charlesmalo/FociToDo.git @ 41a279aeb13ed7aa677fa8248db7b33f9bcf98c7

| ID | Source | Expectation | Result |
|---|---|---|---|
| BR-01 | brief: Add | `POST /api/todos {"title"}` → 201, `Location: /api/todos/<id>`, `ETag: "1"`, body has id, title, description null, dueDate null, isCompleted false, createdAt, version 1 | [PASS](transcripts/BR-01.txt) |
| BR-02 | brief: Add | Create with description and dueDate echoes both back | [PASS](transcripts/BR-02.txt) |
| BR-03 | brief: List | `GET /api/todos` → 200 JSON array whose items carry title, dueDate, isCompleted (and isOverdue) | [PASS](transcripts/BR-03.txt) |
| BR-04 | brief: View | `GET /api/todos/<id>` → 200 with `ETag` and the same todo | [PASS](transcripts/BR-04.txt) |
| BR-05 | brief: Update | `PATCH` title with `If-Match` → 200, new title, version 2, `ETag: "2"`, other fields unchanged | [PASS](transcripts/BR-05.txt) |
| BR-06 | brief: Update | `PATCH` description → changed | [PASS](transcripts/BR-06.txt) |
| BR-07 | brief: Update | `PATCH` dueDate → changed | [PASS](transcripts/BR-07.txt) |
| BR-08 | brief: Complete | `POST /api/todos/<id>/complete` → 200, isCompleted true | [PASS](transcripts/BR-08.txt) |
| BR-09 | brief: Incomplete | `POST /api/todos/<id>/incomplete` → 200, isCompleted false | [PASS](transcripts/BR-09.txt) |
| BR-10 | brief: Delete | `DELETE` with `If-Match` → 204, then `GET` → 404 | [PASS](transcripts/BR-10.txt) |
| BR-11 | brief: filter (optional) | `?status=completed` returns only completed todos | [PASS](transcripts/BR-11.txt) |
| BR-12 | brief: filter (optional) | `?status=incomplete` returns only incomplete todos | [PASS](transcripts/BR-12.txt) |
| BR-13 | brief: filter (optional) | `?status=overdue` returns only incomplete todos due before today (UTC) | [PASS](transcripts/BR-13.txt) |
| BR-14 | brief: filter (optional) | default and `?status=all` return completed and incomplete todos | [PASS](transcripts/BR-14.txt) |
| BR-15 | brief: sort (optional) | `?sort=dueDate&order=asc` orders by due date ascending | [PASS](transcripts/BR-15.txt) |
| BR-16 | brief: sort (optional) | `?sort=dueDate&order=desc` orders by due date descending | [PASS](transcripts/BR-16.txt) |
| BR-17 | brief: sort (optional) | default order is newest first (`createdAt` desc) | [PASS](transcripts/BR-17.txt) |
| BR-18 | brief: sort (optional) | `?sort=createdAt&order=asc` is oldest first | [PASS](transcripts/BR-18.txt) |
| BR-19 | brief: sort (optional) | `?sort=title` orders by title, asc and desc | [PASS](transcripts/BR-19.txt) |
| BR-20 | brief: Persistence | After restarting the api and db containers the app recovers on its own and the todo is still there | [FAIL](transcripts/BR-20.txt) |
| BR-21 | brief: Containerize (optional) | the web front end is served at `/` and deep links fall back to it (200 HTML) | [PASS](transcripts/BR-21.txt) |
