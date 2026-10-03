# Expectation catalogue

Every expectation the independent acceptance run checks, with where it comes from. Each row is proven by `check_<ID>` in `checks/*.sh`, black-box over HTTP through nginx at `http://web:8080`, using the requests the web front end sends. Sources: the take-home **brief**; the design **spec** (`docs/superpowers/specs/2026-09-30-foci-todo-design.md` in the app); the app's **api** guide (`docs/api.md`); **README** assumptions; **robustness** (hostile input the app must reject cleanly — a 4xx with problem details, never a 5xx).

## Brief actions

| ID | Source | Expectation |
|---|---|---|
| BR-01 | brief: Add | `POST /api/todos {"title"}` → 201, `Location: /api/todos/<id>`, `ETag: "1"`, body has id, title, description null, dueDate null, isCompleted false, createdAt, version 1 |
| BR-02 | brief: Add | Create with description and dueDate echoes both back |
| BR-03 | brief: List | `GET /api/todos` → 200 JSON array whose items carry title, dueDate, isCompleted (and isOverdue) |
| BR-04 | brief: View | `GET /api/todos/<id>` → 200 with `ETag` and the same todo |
| BR-05 | brief: Update | `PATCH` title with `If-Match` → 200, new title, version 2, `ETag: "2"`, other fields unchanged |
| BR-06 | brief: Update | `PATCH` description → changed |
| BR-07 | brief: Update | `PATCH` dueDate → changed |
| BR-08 | brief: Complete | `POST /api/todos/<id>/complete` → 200, isCompleted true |
| BR-09 | brief: Incomplete | `POST /api/todos/<id>/incomplete` → 200, isCompleted false |
| BR-10 | brief: Delete | `DELETE` with `If-Match` → 204, then `GET` → 404 |
| BR-11 | brief: filter (optional) | `?status=completed` returns only completed todos |
| BR-12 | brief: filter (optional) | `?status=incomplete` returns only incomplete todos |
| BR-13 | brief: filter (optional) | `?status=overdue` returns only incomplete todos due before today (UTC) |
| BR-14 | brief: filter (optional) | default and `?status=all` return completed and incomplete todos |
| BR-15 | brief: sort (optional) | `?sort=dueDate&order=asc` orders by due date ascending |
| BR-16 | brief: sort (optional) | `?sort=dueDate&order=desc` orders by due date descending |
| BR-17 | brief: sort (optional) | default order is newest first (`createdAt` desc) |
| BR-18 | brief: sort (optional) | `?sort=createdAt&order=asc` is oldest first |
| BR-19 | brief: sort (optional) | `?sort=title` orders by title, asc and desc |
| BR-20 | brief: Persistence | After restarting the api and db containers the app recovers on its own and the todo is still there |
| BR-21 | brief: Containerize (optional) | the web front end is served at `/` and deep links fall back to it (200 HTML) |
