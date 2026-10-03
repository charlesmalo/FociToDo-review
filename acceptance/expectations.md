# Expectation catalogue

Every expectation the independent acceptance run checks, with where it comes from. Each row is proven by `check_<ID>` in `checks/*.sh`, black-box over HTTP through nginx at `http://web:8080`, using the requests the web front end sends. Sources: the take-home **brief**; the design **spec** (`docs/superpowers/specs/2026-09-30-foci-todo-design.md` in the app); the app's **api** guide (`docs/api.md`); **README** assumptions; **robustness** (hostile input the app must reject cleanly — a 4xx with problem details, never a 5xx).

## Independence

This catalogue, its checks (`acceptance/checks/*.sh`) and the storyboard journeys (`storyboard/journeys/*.spec.ts`) are written only from these allowed sources: the take-home brief, the design spec (`docs/superpowers/specs/2026-09-30-foci-todo-design.md`), the app's API guide (`docs/api.md`), the app's README, and the served `/api/openapi.json`. They are never written from, or adapted from, the app's own test code (`apps/*/tests`, `packages/*/tests`, `e2e/`) — every check here interacts with a freshly started stack only as a black box, over HTTP or through a browser pointed at `http://web:8080`. Reading the app's UI source to find an element's accessible name (its label, role or text) is allowed (R49) and is how the storyboard's selectors were written; reading the app's test files is not. The plan's reference user journey was drafted by the app's own author, so some sample data in the storyboard (for example "Buy oat milk") coincides with the app's own `e2e` fixtures — this is a coincidence of authorship, not a dependency on the app's tests.

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

## Data rules

| ID | Source | Expectation |
|---|---|---|
| DR-01 | spec: DR-1 | `id` is a server-generated UUID (a client-sent id is rejected as an unknown field) |
| DR-02 | spec: DR-6 | `createdAt` is an ISO-8601 UTC timestamp ending in `Z`, within a minute of now |
| DR-03 | spec: DR-2 | title is trimmed (`"  hi  "` → `"hi"`) |
| DR-04 | spec: DR-2 | a 200-character title is accepted |
| DR-05 | spec: DR-2 | a 201-character title → 400 naming `title` |
| DR-06 | spec: DR-2 | an empty title → 400 naming `title` |
| DR-07 | spec: DR-2 | a whitespace-only title → 400 naming `title` |
| DR-08 | spec: DR-3 | a 2000-character description is accepted |
| DR-09 | spec: DR-3 | a 2001-character description → 400 naming `description` |
| DR-10 | spec: DR-3 | an empty description is stored as `null` |
| DR-11 | spec: DR-4 | `dueDate` `2026-02-30` (not a real date) → 400 naming `dueDate` |
| DR-12 | spec: DR-4 | `dueDate` `2026-1-5` (not `YYYY-MM-DD`) → 400 naming `dueDate` |
| DR-13 | spec: DR-4 | a past `dueDate` (`2001-01-01`) is accepted |
| DR-14 | api: Conventions | the earliest date `0001-01-01` is accepted |
| DR-15 | api: Conventions | year `0000` → 400 naming `dueDate` |
| DR-16 | spec: DR-5 | `isCompleted` defaults to `false` and cannot be set on create (unknown field → 400) |
| DR-17 | spec: DR-7 | `version` is read-only: sending it in PATCH → 400 |
| DR-18 | spec: DR-8 | `isOverdue`: due yesterday (UTC) and incomplete → true; due today → false; due yesterday but completed → false |
| DR-19 | api: Conventions | every todo response's `ETag` equals `"<version>"` (create, get, patch, complete, incomplete) |

## Error contract

| ID | Source | Expectation |
|---|---|---|
| EC-01 | api: Problem types | a validation error is `application/problem+json` with `type /problems/validation-error`, `title`, `status 400` and `errors[]` of `{field, message}` |
| EC-02 | api: Problem types | `GET` of an unknown UUID → 404 `/problems/not-found` |
| EC-03 | api: Problem types | `GET /api/todos/abc` (not a UUID) → 400 naming `id` |
| EC-04 | api: Conventions | `PATCH` with a stale `If-Match` → 412 `/problems/version-conflict` |
| EC-05 | api: Conventions | `PATCH` without `If-Match` → 428 `/problems/precondition-required` |
| EC-06 | api: Conventions | `DELETE` without `If-Match` → 428 |
| EC-07 | api: Conventions | `DELETE` with a stale `If-Match` → 412 |
| EC-08 | spec §5 | `If-Match: *` → 400 |
| EC-09 | spec §5 | a weak `If-Match: W/"1"` → 400 |
| EC-10 | api: Error precedence | invalid body and no `If-Match` → 400 (400 before 428) |
| EC-11 | api: Error precedence | valid body, no `If-Match`, unknown id → 428 (428 before 404) |
| EC-12 | api: Error precedence | valid body, `If-Match`, unknown id → 404 (404 before 412) |
| EC-13 | api: Endpoints | `POST` with `Content-Type: application/json; charset=latin1` → 415 problem |
| EC-14 | api: Endpoints | `PATCH` with an unsupported charset → 415 problem |
| EC-15 | api: Problem types | an unknown route `/api/nope` → 404 problem |
| EC-16 | api: Endpoints | `complete` / `incomplete` / `DELETE` of an unknown id (DELETE with `If-Match`) → 404 |
| EC-17 | api: Problem types | a body over 16 kB → 413 `/problems/payload-too-large` |

## Concurrency surface

| ID | Source | Expectation |
|---|---|---|
| CS-01 | spec §6 | completing a completed todo → 200 and the version does not change |
| CS-02 | spec §6 | marking an incomplete todo incomplete → 200 and the version does not change |
| CS-03 | api: Conventions | repeating a create with the same `Idempotency-Key` and body → 201, same id, `Idempotent-Replayed: true`, and only one todo exists |
| CS-04 | api: Conventions | the same key with a different body → 422 `/problems/idempotency-key-reuse` |
| CS-05 | openapi: IdempotencyKey | an invalid `Idempotency-Key` (contains a space, or 256 characters) → 400 |
| CS-06 | spec §6 | after a complete bumps the version, a PATCH with the old `If-Match` → 412 (no lost update) |
| CS-07 | api: Conventions | a first create with a key has no `Idempotent-Replayed` header |

## README assumptions

| ID | Source | Expectation |
|---|---|---|
| RA-01 | README assumption 1 | no authentication: requests without credentials succeed and no `WWW-Authenticate` challenge is sent |
| RA-02 | README assumption 2 | overdue is judged against today in UTC: due 2 days ago → overdue; due in 2 days → not |
| RA-03 | README assumption 3 | past due dates are allowed when creating and when updating |
| RA-04 | README assumption 4 | `PATCH {"description": null}` clears the description |
| RA-05 | README assumption 4 | `PATCH {"dueDate": null}` clears the due date |
| RA-06 | README assumption 4 | `PATCH {"title": null}` → 400 (the title cannot be cleared) |
| RA-07 | README assumption 4 | a PATCH changes only the fields it sends |
| RA-08 | README assumption 5 | complete and incomplete need no `If-Match` |
| RA-09 | README assumption 6 | a deleted todo is gone for good: absent from the list, `GET` → 404, a second `DELETE` with `If-Match` → 404 |
| RA-10 | README assumption 7 | no pagination: 60 created todos all appear in one list response; `?page=2` → 400 |
| RA-11 | README assumption 8 | idempotency keys apply to creates only: two PATCHes with the same key, each with the current `If-Match`, both apply |
| RA-12 | README assumption 9 | `dueDate` is returned exactly as sent (no timezone shift); `createdAt` is UTC |
| RA-13 | README assumption 10 | titles sort case-insensitively (`apple`, `Banana`, `cherry`) |
| RA-14 | README assumption 10 | todos without a due date sort last in both orders |

## Robustness

| ID | Source | Expectation |
|---|---|---|
| RB-01 | robustness | malformed JSON → 400 `/problems/malformed-json` |
| RB-02 | robustness | a `text/plain` body → 4xx problem, never 5xx |
| RB-03 | robustness | an empty body → 4xx problem |
| RB-04 | robustness | a JSON array body → 400 |
| RB-05 | robustness | an unknown field → 400 whose `errors[]` names it |
| RB-06 | robustness | `title` as a number → 400 naming `title` |
| RB-07 | robustness | `dueDate` as a number → 400 naming `dueDate` |
| RB-08 | robustness | a 10,000-character title → 400 naming `title` (not 5xx) |
| RB-09 | robustness | non-ASCII titles (accents, CJK, emoji, right-to-left) round-trip unchanged |
| RB-10 | api: Conventions | a NUL character (`\u0000`) in title or description → 400 |
| RB-11 | robustness | odd ids never cause a 5xx: `..%2F..%2Fetc` (normalised by nginx outside /api) serves only the app's own index.html; a 1,000-character id → 4xx problem; `%00` (rejected by nginx's own request-line parser before proxying) → 4xx |
| RB-12 | spec §5 | an unknown `status` value → 400 |
| RB-13 | api: Conventions | an unknown query key → 400 |
| RB-14 | robustness | `PUT /api/todos/<id>` (unsupported method) → 4xx problem |
| RB-15 | openapi: IfMatch | `If-Match: "9999999999"` (beyond the version limit) → 400 |
| RB-16 | robustness | deeply nested JSON (`{"title":{"a":{"b":…}}}` 50 levels) → 400, never 5xx |
| RB-17 | robustness | SQL-looking text in a title is stored literally and the list still works |
| RB-18 | robustness | HTML/script text in a title is stored and returned literally as JSON (no execution context) |

## API documentation and health

| ID | Source | Expectation |
|---|---|---|
| AD-01 | openapi: Health | `GET /api/health` → 200 `{"status":"ok","db":"up",…}` |
| AD-02 | spec: OpenAPI | `GET /api/openapi.json` → 200 OpenAPI 3.1 document with paths for `/api/todos`, `/api/todos/{id}`, `/api/todos/{id}/complete`, `/api/todos/{id}/incomplete`, `/api/health` |
| AD-03 | README: Quick start | `GET /api/docs` → 200 HTML (the API explorer) (following redirects) |
