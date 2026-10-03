# Review — PR #23: feat(deadlines): deadlines as UTC instants with a due-soon flag

- App commit range: `a49823a..3dbb2eb (3 commits: `15b2e54` feat(deadlines), `3d76854` test(e2e), `68e4977` docs(deadlines))` · merged as `3dbb2ebc374e2e783f1164e35b1104224cdd6033` · PR: https://github.com/charlesmalo/FociToDo/pull/23 (branch `feat/deadline-instants`) · Date: 2026-10-03 · Reviewer: Claude Code (automated) + solution-lead triage
- Origin: planned change (spec `docs/superpowers/specs/2026-10-03-api-docs-and-deadlines-design.md` §3, ADR 0017): the date-only `dueDate` becomes `dueAt`, an exact UTC instant, with an `isDueSoon` flag (incomplete and due within the next 24 hours), a `status=due-soon` filter and `sort=dueAt`. The contract change itself is a design decision, not a finding; the findings below are defects found while building it.

## Automated review output

Scope of PR #23 (3 commits, 72 files, +1392/-353): shared schemas (`DueAtSchema`), domain (`isDueSoon`, `DUE_SOON_WINDOW_MS`), both repositories, the migration `1759190400002_due-at-instants.sql` (including cached idempotency responses), OpenAPI, the web form (local date and time to one instant), list badges and a 60 s refetch, an e2e journey across two timezones, and ADR 0017.

**The change**:
- `dueAt` is RFC 3339 with an offset or `Z`, normalised to UTC with milliseconds; a bare date, a date-time without an offset, an impossible calendar date and years 0000 and 10000 are rejected with `400`.
- `isOverdue` and `isDueSoon` are derived from the instant on every read and are never both true; `status=due-soon` and `sort=dueAt` (deadline-free todos last) replace the old `dueDate` sort key, which now gets a `400`.
- The idempotency request hash uses the normalised instant, so the same instant written with `Z` or an offset replays rather than conflicting.
- The form takes a local date and time, converts to one `dueAt`, and resends the stored value untouched when the user did not change the deadline.

**Independent verification** (this review's own runs at the merged `main` commit `3dbb2eb`, which includes both PR #22 and PR #23; not run per PR):
- **Contract, black-box**: acceptance 104/104 PASS at `3dbb2eb`, including DR-11..DR-15 and DR-20 (instant validation, normalisation, idempotent replay), DR-18 and DS-01..DS-03 (`isOverdue`, `isDueSoon`, `status=due-soon`), BR-15/BR-16 and RA-14 (`sort=dueAt`), RA-02 (the same instant sent as `+14:00` and `-12:00` reads identically), and DS-04 (the old `dueDate` key is rejected) — [`evidence/2026-10-03T215055Z/acceptance/results.md`](../evidence/2026-10-03T215055Z/acceptance/results.md).
- **UI across timezones**: the storyboard journey `two-timezones` shows the same deadlines and badges from a New York and a Tokyo browser; 29 frames, 12 journeys, 13/13 wireframes paired — [`evidence/2026-10-03T215412Z/storyboard/storyboard.md`](../evidence/2026-10-03T215412Z/storyboard/storyboard.md).
- **Gate and e2e**: 62 test files, 546 tests, coverage 100/100/100/100; e2e 10 passed — [`evidence/2026-10-03T215759Z/summary.md`](../evidence/2026-10-03T215759Z/summary.md), [`evidence/2026-10-03T215759Z/e2e.log`](../evidence/2026-10-03T215759Z/e2e.log).
- **Concurrency and load**: stress 5/5 scenarios PASS, 13/13 invariants hold; the mixed-load scenario now sends `sort=dueAt` and a `dueAt` instant (the load script was updated for the renamed contract) — [`evidence/2026-10-03T215927Z/stress/summary.md`](../evidence/2026-10-03T215927Z/stress/summary.md).
- **Dependencies**: scans unchanged from `153d719` (0 HIGH/CRITICAL on `api` and `web`; `npm audit` 0 vulnerabilities) — [`evidence/2026-10-03T220217Z/scans/summary.md`](../evidence/2026-10-03T220217Z/scans/summary.md).

## Findings

| Finding | Severity | Category | Decision | Reason |
|---|---|---|---|---|
| F-106 Zod 4 ran `.refine` after the ISO-format check failed, so an invalid `dueAt` produced two issues | Minor | correctness | Fix | Fixed in this PR — the year-range refinement runs only when there are no prior issues, one `dueAt` error per bad value |
| F-107 V8's `Date` rolls an impossible local date (Feb 30) into March, so the form would have saved a different day | Important | correctness | Fix | Fixed in this PR — the conversion round-trips the parsed date and passes impossible input through, so the server's `400` shows under Due date |
| F-108 A migration header comment beginning `-- Down Migration` was read by node-pg-migrate as the up/down separator and truncated the up migration | Important | correctness | Fix | Fixed in this PR — comment reworded; the down/up test runs through the real runner |
| F-109 Editing a title re-serialised the deadline from the local inputs and changed the stored instant | Important | correctness | Fix | Fixed in this PR — the form snapshots the initial `dueAt` and resends it exactly when the deadline is untouched |
| F-110 The local-to-UTC conversion was only tested in UTC, where local and UTC coincide | Important | tests | Fix | Fixed in this PR — unit tests in `America/New_York` (including a DST gap) and an e2e from New York to Tokyo |
| F-111 The form-created e2e used a fixed 18:00 New York deadline, flaky depending on when it runs | Important | tests | Fix | Fixed in this PR — the deadline is now + 3 h in New York wall-clock, the Tokyo expectation computed from the same instant |
| F-112 Badges could go stale on an idle page | Minor | correctness | Fix | Fixed in this PR — the list refetches every 60 s, with a test of the configured option |
| F-113 On the one fall-back night a year, now + 3 h can land in New York's repeated 01:xx hour and the e2e could resolve the other instant | Low | tests | Accept | At most one possible CI retry a year |

## CI

- PR CI, head commit `68e4977` (run [37155942861](https://github.com/charlesmalo/FociToDo/actions/runs/37155942861)): green, 4/4 jobs — lint/typecheck/tests, images, diagrams, e2e.
- Main CI on the merge commit `3dbb2eb` (run [37156200771](https://github.com/charlesmalo/FociToDo/actions/runs/37156200771)): green, 4/4 jobs.

## Checklist

Copy of `checklists/milestone-review.md` with results for PR #23:

### Correctness
- [x] Behaviour matches the spec sections the PR claims (status codes, headers, validation messages) — spec §3.1–§3.3, confirmed black-box by DR-11..DR-15, DR-18, DR-20, DS-01..DS-04 at `3dbb2eb`.
- [x] Error precedence 400 → 428 → 404 → 412 preserved — EC-01..EC-17 PASS in the same 104/104 run.
- [x] No silent catch-alls; unexpected errors become logged 500s — out-of-range instants return `400`, not a Postgres `500` (DR-15, RB-07).

### Concurrency
- [x] Every write is a single statement or inside the unit of work — unchanged; `due_at` is written through the existing repository statements.
- [x] Version bumps only on real changes; conditional writes use the version — unchanged; CS-01..CS-07 PASS.
- [x] New code paths covered by an invariant test if they touch shared state — the load mix now exercises `dueAt` patches and `sort=dueAt`; stress 13/13 invariants hold.

### Tests
- [x] Test written first (visible in the commit) and mirrors the source path — e.g. `domain/todo.ts` → `tests/domain/todo.test.ts`, the migration → `tests/migrations/dueAtMigration.int.test.ts`.
- [x] 100% coverage without `v8 ignore` — gate re-run at 100% (546 tests at `3dbb2eb`).
- [x] Assertions check behaviour, not implementation details or timings — after F-110 and F-111 the timezone tests run in a non-UTC zone and the e2e deadline is computed relative to now.

### Architecture
- [x] Layer rules respected (lint passes); composition only in `app.ts` — lint green; `isDueSoon` lives in `domain/`.
- [x] No new dependency without a reason in the commit or an ADR — no new dependency; ADR 0017 records the instant decision.

### Docs
- [x] README / guides / OpenAPI still accurate (no drift) — `apps/api/openapi.json` and `docs/api/index.html` regenerated; the committed-file-matches-generated test passes.
- [x] New decisions recorded as ADRs — ADR 0017 (deadlines are UTC instants).

### Security & operability
- [x] Inputs validated with shared schemas; no secrets or stack traces in responses — one shared `DueAtSchema`; the old key is rejected (DS-04).
- [x] Images non-root; no dev dependencies in runtime images — unchanged; scans at `3dbb2eb` report 0 HIGH/CRITICAL on `api` and `web`.

**Verdict: clean after fixes. Six Important findings (a migration that could truncate itself, a form that could silently change the saved instant or day, and timezone behaviour that was untested or flaky) were found in review and fixed in the same PR; the contract is independently re-proven at 104/104.**
