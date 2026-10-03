# Acceptance — https://github.com/charlesmalo/FociToDo.git @ 3dbb2ebc374e2e783f1164e35b1104224cdd6033

| ID | Source | Expectation | Result |
|---|---|---|---|
| BR-01 | brief: Add | `POST /api/todos {"title"}` → 201, `Location: /api/todos/<id>`, `ETag: "1"`, body has id, title, description null, dueAt null, isCompleted false, createdAt, version 1 | [PASS](transcripts/BR-01.txt) |
| BR-02 | brief: Add, spec 2026-10-03 §3.1 | Create with description and `dueAt` (`2030-01-02T12:00:00Z`) echoes both back, `dueAt` as `2030-01-02T12:00:00.000Z` | [PASS](transcripts/BR-02.txt) |
| BR-03 | brief: List | `GET /api/todos` → 200 JSON array whose items carry title, dueAt, isCompleted (and isOverdue) | [PASS](transcripts/BR-03.txt) |
| BR-04 | brief: View | `GET /api/todos/<id>` → 200 with `ETag` and the same todo | [PASS](transcripts/BR-04.txt) |
| BR-05 | brief: Update | `PATCH` title with `If-Match` → 200, new title, version 2, `ETag: "2"`, other fields unchanged | [PASS](transcripts/BR-05.txt) |
| BR-06 | brief: Update | `PATCH` description → changed | [PASS](transcripts/BR-06.txt) |
| BR-07 | brief: Update, spec 2026-10-03 §3.1 | `PATCH` `dueAt` → changed | [PASS](transcripts/BR-07.txt) |
| BR-08 | brief: Complete | `POST /api/todos/<id>/complete` → 200, isCompleted true | [PASS](transcripts/BR-08.txt) |
| BR-09 | brief: Incomplete | `POST /api/todos/<id>/incomplete` → 200, isCompleted false | [PASS](transcripts/BR-09.txt) |
| BR-10 | brief: Delete | `DELETE` with `If-Match` → 204, then `GET` → 404 | [PASS](transcripts/BR-10.txt) |
| BR-11 | brief: filter (optional) | `?status=completed` returns only completed todos | [PASS](transcripts/BR-11.txt) |
| BR-12 | brief: filter (optional) | `?status=incomplete` returns only incomplete todos | [PASS](transcripts/BR-12.txt) |
| BR-13 | brief: filter (optional), spec 2026-10-03 §3.2 | `?status=overdue` returns only incomplete todos whose deadline is in the past | [PASS](transcripts/BR-13.txt) |
| BR-14 | brief: filter (optional) | default and `?status=all` return completed and incomplete todos | [PASS](transcripts/BR-14.txt) |
| BR-15 | brief: sort (optional), spec 2026-10-03 §3.3 | `?sort=dueAt&order=asc` orders by deadline ascending, todos without a deadline last | [PASS](transcripts/BR-15.txt) |
| BR-16 | brief: sort (optional), spec 2026-10-03 §3.3 | `?sort=dueAt&order=desc` orders by deadline descending, todos without a deadline still last | [PASS](transcripts/BR-16.txt) |
| BR-17 | brief: sort (optional) | default order is newest first (`createdAt` desc) | [PASS](transcripts/BR-17.txt) |
| BR-18 | brief: sort (optional) | `?sort=createdAt&order=asc` is oldest first | [PASS](transcripts/BR-18.txt) |
| BR-19 | brief: sort (optional) | `?sort=title` orders by title, asc and desc | [PASS](transcripts/BR-19.txt) |
| BR-20 | brief: Persistence | After restarting the api and db containers the app recovers on its own and the todo is still there | [PASS](transcripts/BR-20.txt) |
| BR-21 | brief: Containerize (optional) | the web front end is served at `/` and deep links fall back to it (200 HTML) | [PASS](transcripts/BR-21.txt) |
| DR-01 | spec: DR-1 | `id` is a server-generated UUID (a client-sent id is rejected as an unknown field) | [PASS](transcripts/DR-01.txt) |
| DR-02 | spec: DR-6 | `createdAt` is an ISO-8601 UTC timestamp ending in `Z`, within a minute of now | [PASS](transcripts/DR-02.txt) |
| DR-03 | spec: DR-2 | title is trimmed (`"  hi  "` → `"hi"`) | [PASS](transcripts/DR-03.txt) |
| DR-04 | spec: DR-2 | a 200-character title is accepted | [PASS](transcripts/DR-04.txt) |
| DR-05 | spec: DR-2 | a 201-character title → 400 naming `title` | [PASS](transcripts/DR-05.txt) |
| DR-06 | spec: DR-2 | an empty title → 400 naming `title` | [PASS](transcripts/DR-06.txt) |
| DR-07 | spec: DR-2 | a whitespace-only title → 400 naming `title` | [PASS](transcripts/DR-07.txt) |
| DR-08 | spec: DR-3 | a 2000-character description is accepted | [PASS](transcripts/DR-08.txt) |
| DR-09 | spec: DR-3 | a 2001-character description → 400 naming `description` | [PASS](transcripts/DR-09.txt) |
| DR-10 | spec: DR-3 | an empty description is stored as `null` | [PASS](transcripts/DR-10.txt) |
| DR-11 | spec 2026-10-03 §3.1 | `dueAt` `2026-02-30T10:00:00Z` (not a real date) → 400 naming `dueAt` | [PASS](transcripts/DR-11.txt) |
| DR-12 | spec 2026-10-03 §3.1 | `dueAt` as a bare date (`2026-10-05`) or a date-time without an offset (`2026-10-05T10:00:00`) → 400 naming `dueAt` | [PASS](transcripts/DR-12.txt) |
| DR-13 | spec 2026-10-03 §3.1 | a past `dueAt` is accepted in both spellings and normalised to UTC with milliseconds: `2001-01-01T10:00:00+02:00` → `2001-01-01T08:00:00.000Z`; `2001-01-01T10:00:00.5Z` → `2001-01-01T10:00:00.500Z` | [PASS](transcripts/DR-13.txt) |
| DR-14 | spec 2026-10-03 §3.1 | the earliest instant `0001-01-01T00:00:00Z` is accepted and returned as `0001-01-01T00:00:00.000Z` | [PASS](transcripts/DR-14.txt) |
| DR-15 | spec 2026-10-03 §3.1 | year `0000` and year `10000` → 400 naming `dueAt` | [PASS](transcripts/DR-15.txt) |
| DR-16 | spec: DR-5 | `isCompleted` defaults to `false` and cannot be set on create (unknown field → 400) | [PASS](transcripts/DR-16.txt) |
| DR-17 | spec: DR-7 | `version` is read-only: sending it in PATCH → 400 | [PASS](transcripts/DR-17.txt) |
| DR-18 | spec 2026-10-03 §3.2 | `isOverdue` is relative to the deadline instant: 10 seconds in the past and incomplete → true; 5 minutes ahead → false; past but completed → false | [PASS](transcripts/DR-18.txt) |
| DR-19 | api: Conventions | every todo response's `ETag` equals `"<version>"` (create, get, patch, complete, incomplete) | [PASS](transcripts/DR-19.txt) |
| DR-20 | spec 2026-10-03 §3.1 | the idempotency request hash uses the normalised instant: the same `dueAt` written with `Z` and with `+02:00` under one `Idempotency-Key` replays the original 201 (`Idempotent-Replayed: true`, same id); a different instant under that key → 422 `/problems/idempotency-key-reuse` | [PASS](transcripts/DR-20.txt) |
| EC-01 | api: Problem types | a validation error is `application/problem+json` with `type /problems/validation-error`, `title`, `status 400` and `errors[]` of `{field, message}` | [PASS](transcripts/EC-01.txt) |
| EC-02 | api: Problem types | `GET` of an unknown UUID → 404 `/problems/not-found` | [PASS](transcripts/EC-02.txt) |
| EC-03 | api: Problem types | `GET /api/todos/abc` (not a UUID) → 400 naming `id` | [PASS](transcripts/EC-03.txt) |
| EC-04 | api: Conventions | `PATCH` with a stale `If-Match` → 412 `/problems/version-conflict` | [PASS](transcripts/EC-04.txt) |
| EC-05 | api: Conventions | `PATCH` without `If-Match` → 428 `/problems/precondition-required` | [PASS](transcripts/EC-05.txt) |
| EC-06 | api: Conventions | `DELETE` without `If-Match` → 428 | [PASS](transcripts/EC-06.txt) |
| EC-07 | api: Conventions | `DELETE` with a stale `If-Match` → 412 | [PASS](transcripts/EC-07.txt) |
| EC-08 | spec §5 | `If-Match: *` → 400 | [PASS](transcripts/EC-08.txt) |
| EC-09 | spec §5 | a weak `If-Match: W/"1"` → 400 | [PASS](transcripts/EC-09.txt) |
| EC-10 | api: Error precedence | invalid body and no `If-Match` → 400 (400 before 428) | [PASS](transcripts/EC-10.txt) |
| EC-11 | api: Error precedence | valid body, no `If-Match`, unknown id → 428 (428 before 404) | [PASS](transcripts/EC-11.txt) |
| EC-12 | api: Error precedence | valid body, `If-Match`, unknown id → 404 (404 before 412) | [PASS](transcripts/EC-12.txt) |
| EC-13 | api: Endpoints | `POST` with `Content-Type: application/json; charset=latin1` → 415 problem | [PASS](transcripts/EC-13.txt) |
| EC-14 | api: Endpoints | `PATCH` with an unsupported charset → 415 problem | [PASS](transcripts/EC-14.txt) |
| EC-15 | api: Problem types | an unknown route `/api/nope` → 404 problem | [PASS](transcripts/EC-15.txt) |
| EC-16 | api: Endpoints | `complete` / `incomplete` / `DELETE` of an unknown id (DELETE with `If-Match`) → 404 | [PASS](transcripts/EC-16.txt) |
| EC-17 | api: Problem types | a body over 16 kB → 413 `/problems/payload-too-large` | [PASS](transcripts/EC-17.txt) |
| CS-01 | spec §6 | completing a completed todo → 200 and the version does not change | [PASS](transcripts/CS-01.txt) |
| CS-02 | spec §6 | marking an incomplete todo incomplete → 200 and the version does not change | [PASS](transcripts/CS-02.txt) |
| CS-03 | api: Conventions | repeating a create with the same `Idempotency-Key` and body → 201, same id, `Idempotent-Replayed: true`, and only one todo exists | [PASS](transcripts/CS-03.txt) |
| CS-04 | api: Conventions | the same key with a different body → 422 `/problems/idempotency-key-reuse` | [PASS](transcripts/CS-04.txt) |
| CS-05 | openapi: IdempotencyKey | an invalid `Idempotency-Key` (contains a space, or 256 characters) → 400 | [PASS](transcripts/CS-05.txt) |
| CS-06 | spec §6 | after a complete bumps the version, a PATCH with the old `If-Match` → 412 (no lost update) | [PASS](transcripts/CS-06.txt) |
| CS-07 | api: Conventions | a first create with a key has no `Idempotent-Replayed` header | [PASS](transcripts/CS-07.txt) |
| RA-01 | README assumption 1 | no authentication: requests without credentials succeed and no `WWW-Authenticate` challenge is sent | [PASS](transcripts/RA-01.txt) |
| RA-02 | README assumption 2, spec 2026-10-03 §3.2 | overdue is a property of the instant, whatever the client's timezone: the same instant sent as `+14:00` and as `-12:00` (2 hours ago) gives identical `dueAt`, `isOverdue` (true) and `isDueSoon` (false); a deadline 2 days ahead is not overdue | [PASS](transcripts/RA-02.txt) |
| RA-03 | README assumption 3 | past deadlines (`dueAt`) are allowed when creating and when updating | [PASS](transcripts/RA-03.txt) |
| RA-04 | README assumption 4 | `PATCH {"description": null}` clears the description | [PASS](transcripts/RA-04.txt) |
| RA-05 | README assumption 4 | `PATCH {"dueAt": null}` clears the deadline | [PASS](transcripts/RA-05.txt) |
| RA-06 | README assumption 4 | `PATCH {"title": null}` → 400 (the title cannot be cleared) | [PASS](transcripts/RA-06.txt) |
| RA-07 | README assumption 4 | a PATCH changes only the fields it sends | [PASS](transcripts/RA-07.txt) |
| RA-08 | README assumption 5 | complete and incomplete need no `If-Match` | [PASS](transcripts/RA-08.txt) |
| RA-09 | README assumption 6 | a deleted todo is gone for good: absent from the list, `GET` → 404, a second `DELETE` with `If-Match` → 404 | [PASS](transcripts/RA-09.txt) |
| RA-10 | README assumption 7 | no pagination: 60 created todos all appear in one list response; `?page=2` → 400 | [PASS](transcripts/RA-10.txt) |
| RA-11 | README assumption 8 | idempotency keys apply to creates only: two PATCHes with the same key, each with the current `If-Match`, both apply | [PASS](transcripts/RA-11.txt) |
| RA-12 | README assumption 9, spec 2026-10-03 §3.1 | `dueAt` sent with an offset (`2030-07-15T09:30:00-04:00`) is returned normalised to UTC (`2030-07-15T13:30:00.000Z`); `createdAt` is UTC | [PASS](transcripts/RA-12.txt) |
| RA-13 | README assumption 10 | titles sort case-insensitively (`apple`, `Banana`, `cherry`) | [PASS](transcripts/RA-13.txt) |
| RA-14 | README assumption 10, spec 2026-10-03 §3.3 | todos without a deadline sort last in both orders of `sort=dueAt` | [PASS](transcripts/RA-14.txt) |
| RB-01 | robustness | malformed JSON → 400 `/problems/malformed-json` | [PASS](transcripts/RB-01.txt) |
| RB-02 | robustness | a `text/plain` body → 4xx problem, never 5xx | [PASS](transcripts/RB-02.txt) |
| RB-03 | robustness | an empty body → 4xx problem | [PASS](transcripts/RB-03.txt) |
| RB-04 | robustness | a JSON array body → 400 | [PASS](transcripts/RB-04.txt) |
| RB-05 | robustness | an unknown field → 400 whose `errors[]` names it | [PASS](transcripts/RB-05.txt) |
| RB-06 | robustness | `title` as a number → 400 naming `title` | [PASS](transcripts/RB-06.txt) |
| RB-07 | robustness | `dueAt` as a number → 400 naming `dueAt` | [PASS](transcripts/RB-07.txt) |
| RB-08 | robustness | a 10,000-character title → 400 naming `title` (not 5xx) | [PASS](transcripts/RB-08.txt) |
| RB-09 | robustness | non-ASCII titles (accents, CJK, emoji, right-to-left) round-trip unchanged | [PASS](transcripts/RB-09.txt) |
| RB-10 | api: Conventions | a NUL character (`\u0000`) in title or description → 400 | [PASS](transcripts/RB-10.txt) |
| RB-11 | robustness | odd ids never cause a 5xx: `..%2F..%2Fetc` (normalised by nginx outside /api) serves only the app's own index.html; a 1,000-character id → 4xx problem; `%00` (rejected by nginx's own request-line parser before proxying) → 4xx | [PASS](transcripts/RB-11.txt) |
| RB-12 | spec §5 | an unknown `status` value → 400 | [PASS](transcripts/RB-12.txt) |
| RB-13 | api: Conventions | an unknown query key → 400 | [PASS](transcripts/RB-13.txt) |
| RB-14 | robustness | `PUT /api/todos/<id>` (unsupported method) → 4xx problem | [PASS](transcripts/RB-14.txt) |
| RB-15 | openapi: IfMatch | `If-Match: "9999999999"` (beyond the version limit) → 400 | [PASS](transcripts/RB-15.txt) |
| RB-16 | robustness | deeply nested JSON (`{"title":{"a":{"b":…}}}` 50 levels) → 400, never 5xx | [PASS](transcripts/RB-16.txt) |
| RB-17 | robustness | SQL-looking text in a title is stored literally and the list still works | [PASS](transcripts/RB-17.txt) |
| RB-18 | robustness | HTML/script text in a title is stored and returned literally as JSON (no execution context) | [PASS](transcripts/RB-18.txt) |
| AD-01 | openapi: Health | `GET /api/health` → 200 `{"status":"ok","db":"up",…}` | [PASS](transcripts/AD-01.txt) |
| AD-02 | spec 2026-10-03 §2.1 | `GET /api/openapi.json` → 404 `/problems/not-found` problem (the API serves no OpenAPI document) | [PASS](transcripts/AD-02.txt) |
| AD-03 | spec 2026-10-03 §2.1 | `GET /api/docs/` → 404 `/problems/not-found` problem (the API serves no explorer) | [PASS](transcripts/AD-03.txt) |
| DS-01 | spec 2026-10-03 §3.2 | `isDueSoon` is true for an incomplete todo due 2 hours ahead (and `isOverdue` false); false 25 hours ahead; false when completed; false without a deadline | [PASS](transcripts/DS-01.txt) |
| DS-02 | spec 2026-10-03 §3.3 | `?status=due-soon` returns only the due-soon todos of its own title prefix (not the 25 h one, the overdue one, the completed one or the deadline-free one) | [PASS](transcripts/DS-02.txt) |
| DS-03 | spec 2026-10-03 §3.2 | at most one of `isOverdue` / `isDueSoon` is true: every due-soon-filtered todo has `isOverdue` false, every overdue-filtered todo has `isDueSoon` false | [PASS](transcripts/DS-03.txt) |
| DS-04 | spec 2026-10-03 §3.3 | the renamed key: `?sort=dueDate` → 400 naming `sort`; a body with `dueDate` → 400 naming `dueDate` | [PASS](transcripts/DS-04.txt) |
