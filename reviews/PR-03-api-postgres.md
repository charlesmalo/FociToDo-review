# Review — PR #3 feat(api): Postgres storage and migrations

- App commit range: `a698697..ef4bc8c` · Date: 2026-10-01 · Reviewer: Claude Code (automated) + solution-lead triage
- PR not yet merged; this review is recorded ahead of merge per the controller's instruction.

## Automated review output

Scope of PR #3 (commits `74a8519` SQL migrations + the Postgres test harness, `ef4bc8c` the Postgres storage adapter passing the repository contract): two `node-pg-migrate` migrations (`todos`, `idempotency_keys`), the test-only Postgres harness (`testDatabase.ts`, `globalSetup.ts`, the new `api-db` Vitest project), and the second storage adapter (`PgTodoRepository`, `PgIdempotencyStore`, `PgUnitOfWork`, `PgDatabaseProbe`, `createPostgresStorage`, `rows.ts`) plus its tests, run both in isolation and through the adapter-agnostic `repository.contract.ts` suite inherited from PR #2. No `service`, `http`, or `app.ts` code exists yet — out of scope by plan sequencing, same as PR #2.

Diff reviewed line-by-line (`review-a698697..ef4bc8c.diff`, 904 insertions across 18 files; `package-lock.json` is 416 of those lines and was skimmed only for consistency — it adds exactly `pg`, `node-pg-migrate`, `@types/pg` and their transitive dependencies, nothing unexpected) against spec §5.1 (schema), §5.3 (repository ports / Postgres adapter semantics), §5.4 (idempotent-create transaction), §6 (concurrency guarantees), §9 (testing strategy), and `global-constraints.md`. Also read both task reports (`task-1-report.md`, `task-3-report.md`; there is no task-2-report.md — task 2 and 3's work were reported together in `task-3-report.md`) and cross-checked their TDD transcripts and full-gate coverage output against the current working tree.

**Correctness**
- `apps/api/migrations/1759190400000_create-todos.sql` / `…0001_create-idempotency-keys.sql`: column list, types, `CHECK` constraints (`length(btrim(title)) > 0`, `version > 0`), and the `todos_created_at_idx` index match spec §5.1 verbatim, including the `varchar(200)`/`varchar(2000)` length enforcement relied on by `schema.int.test.ts`.
- `PgTodoRepository.ts`: `create`/`findById`/`list`/`update`/`setCompleted`/`delete` all match the spec's prescribed SQL in §5.3 statement-for-statement — conditional `UPDATE … WHERE id = $1 AND version = $2 RETURNING …` (zero rows → `null`), conditional `UPDATE … WHERE is_completed <> $2` with a `findById` fallback on zero rows, conditional `DELETE` returning whether a row was removed. `due_date` is selected via `to_char(due_date, 'YYYY-MM-DD')` so it never round-trips through a JS `Date` (no timezone shift — directly addresses global-constraints Review Focus item 5, carried over from the in-memory adapter).
- `orderBy`: `lower(title) COLLATE "C"` for title sort, `NULLS LAST` only on `dueDate`, and the fixed `created_at DESC, id ASC` tie-break appended to every sort — matches §5.3 and the Postgres locale (`--locale-provider=builtin --builtin-locale=C.UTF-8`) from `global-constraints.md`. Status filters (`STATUS_FILTERS`) and sort expressions (`SORT_EXPRESSIONS`) are fixed lookup tables keyed by the validated `TodoStatus`/`TodoSortField` unions, not raw interpolated user input — no SQL-injection surface.
- `PgIdempotencyStore.ts`: `find` treats `created_at >= notBefore` as live (matches the "expired" semantics proven by the contract suite); `claim`'s `INSERT … ON CONFLICT (key) DO UPDATE … WHERE idempotency_keys.created_at < notBefore` is the exact statement spec §5.4 describes, with `rowCount === 1` signalling success — this single statement is what gives idempotent-create its primary-key serialisation.
- `PgUnitOfWork.ts`: checks a client out of the pool, `BEGIN`/work/`COMMIT`; on failure, `ROLLBACK` and rethrow the original error; if `ROLLBACK` itself throws, the client is destroyed (`release(true)`) instead of returned to the pool — correctly distinguishes "transaction aborted cleanly" from "connection is unusable."
- `createPostgresStorage.ts`: wires `PgTodoRepository`/`PgIdempotencyStore` against the raw `Pool` (each call is its own single-statement transaction) and `PgUnitOfWork` against the `Pool` for multi-step work — matches the port contract (`Storage` = `{ todos, idempotency, unitOfWork }`) unchanged from PR #2.
- `rows.ts`: `TodoRow`→`Todo` mapping (`toTodo`, `firstTodo`) is a pure, allocation-fresh conversion on every row — satisfies the "detached copies" contract tests (no shared references back to driver-internal state) without needing an explicit `structuredClone`, since the pg driver already produces fresh JS values per query.
- `tests/support/testDatabase.ts`: `testDatabaseUrl()` refuses any `DATABASE_URL` whose database name doesn't end in `_test` before any destructive `TRUNCATE` — a real safety check, not just a comment, and it's exercised implicitly on every `api-db` run.
- Verified the Postgres contract run is actually wired into CI: `compose.yaml`'s pre-existing `db-test` (tmpfs-backed, `pg_isready` healthcheck) is a dependency of the `test` service, and `vitest.config.ts`'s new `api-db` project (`globalSetup: globalSetup.ts`, `fileParallelism: false`) applies the real migrations via `node-pg-migrate`'s `runner()` before any `.int.test.ts` runs — so `.github/workflows/ci.yml`'s existing `docker compose --profile test run --rm --build test` now exercises real Postgres, not just in-memory.
- No HTTP, service, or `app.ts` code exists yet, so error precedence, silent-catch-all, and composition-root checklist items have nothing to verify (confirmed intentional by plan sequencing, as in PR #1/#2).

**Tests**: Confirmed via both task reports' RED→GREEN→full-gate TDD evidence (task 1: 139 tests after adding the schema/harness; task 2+3: 75 → 173 tests after adding the Postgres adapter, with the 28-test `describeRepositoryContract` suite passing unmodified against Postgres) and independently via a fresh read of the working tree (`grep -rn "v8 ignore"` across the new files returns nothing; `apps/api/package.json` matches the diff's added `pg@^8.23.1`, `node-pg-migrate@^9.0.0`, `@types/pg@^8.23.1` exactly). Both task reports record a full-gate coverage run at 100/100/100/100 with every new `postgres/*.ts` file individually at 100%. Every new source file mirrors its test path 1:1 (`src/repository/postgres/PgTodoRepository.ts` → `tests/repository/postgres/...`), consistent with the project convention; `tests/support/testDatabase.ts`/`globalSetup.ts` are shared test infrastructure (outside the coverage `include` globs), matching the precedent set by `tests/support/fakes.ts`/`todoFactory.ts` in PR #2.

**Architecture**: No file under `apps/api/src/repository/postgres/**` imports from `apps/api/src/repository/in-memory/**` (confirmed by direct inspection of all six new source files) — the only cross-references are `../ports.js`, `../../domain/todo.js`, and `@foci/shared`, identical to the import shape the in-memory adapter already uses. No `app.ts` exists yet, so there is nothing to violate the composition-root rule. The three new dependencies (`pg`, `node-pg-migrate`, `@types/pg`) are justified by the PR's stated purpose (a Postgres adapter needs a Postgres driver and a migration runner) and documented in the task report.

**Already resolved / clarified during per-task review (not re-litigated, recorded as Accept below per the controller's list):**
- `PgUnitOfWork.test.ts` lacks a failing-`BEGIN` case and a single-release assertion (F-6).
- `PgDatabaseProbe.test.ts`'s "no migration has run" test name overstates what an empty mock `rows` array actually proves (F-7).
- `PgDatabaseProbe.int.test.ts` hard-codes the latest migration's filename, coupling it to migration history (F-8).
- `orderBy` repeats `created_at` in the `ORDER BY` clause when sorting by `createdAt` (F-9).
- `PgIdempotencyStore.claim`'s `JSON.stringify(undefined)` would bind `NULL` into a `NOT NULL` column — unreachable today (F-10).
- `globalSetup.ts` uses node-pg-migrate 9's real `logger` option; a prior report's claim that `log` is simply "unsupported" undersold that `logger` is the correct typed replacement — the code itself is correct (F-11).
- `schema.int.test.ts` checks constraints on `todos` only; `idempotency_keys`'s own column constraints aren't independently schema-tested, though the table is exercised by the Postgres contract run (F-12).

**No Critical or Important findings.** This PR is a close-to-verbatim implementation of pre-approved task briefs (both task reports state "no code deviations" / "all files created verbatim from the briefs," with one mechanical, already-documented adaptation to node-pg-migrate 9's real `logger` API). Independent re-verification of the diff against spec §5.1/§5.3/§5.4/§6 and the global constraints found no behavioural mismatch. Seven pre-identified Low-severity polish items are carried into the triage table below as new findings (F-6…F-12); none affect correctness, and all are accepted as-is.

## Triage

| Finding | Severity | Category | Decision | Reason |
|---|---|---|---|---|
| F-6 `PgUnitOfWork.test.ts` has no failing-`BEGIN` test case and no single-release assertion | Low | tests | Accept | Existing `BEGIN`/`COMMIT`/`ROLLBACK`/destroy-on-rollback-failure cases already cover the class's real failure modes; a failing-`BEGIN` case would exercise the same `catch`/`release` path already proven by the "rolls back and rethrows" and "destroys the client" tests. Polish only. |
| F-7 `PgDatabaseProbe.test.ts`'s test name "reports no schema version when no migration has run" overstates what the mock proves | Low | tests | Accept | The assertion itself (`schemaVersion: null` on empty `rows`) is correct and matches `PgDatabaseProbe.ts`'s `rows[0]?.name ?? null`; only the test's prose name is broader than the mock scenario. Cosmetic. |
| F-8 `PgDatabaseProbe.int.test.ts` hard-codes the latest migration filename, coupling the test to migration history | Low | tests | Accept | Correct and necessary to prove the probe reads the real `pgmigrations` table end-to-end; will need a one-line update whenever a new migration is added, which is expected maintenance, not a defect. |
| F-9 `orderBy` repeats `created_at` in the `ORDER BY` clause when `sort = 'createdAt'` | Low | correctness | Accept | Same column, same direction, twice — redundant but produces identical, correct ordering; no behavioural effect and matches the brief verbatim. |
| F-10 `PgIdempotencyStore.claim`'s `JSON.stringify(undefined)` would bind `NULL` into the `NOT NULL` `response_body` column | Low | correctness | Accept | Unreachable today: `TodoService`'s idempotent-create path (landing in a later PR) always builds a concrete response body before calling `claim`. Would surface as a clear constraint-violation error, not silent corruption, if it ever happened. |
| F-11 `globalSetup.ts` correctly uses node-pg-migrate 9's `logger` option; an earlier report's claim that `log` is simply unsupported was imprecise | Low | docs | Accept | The code is correct (confirmed against the installed library's real `RunnerOptionConfig` type); only a prior report's phrasing was imprecise. No action needed. |
| F-12 `schema.int.test.ts` only exercises `CHECK`/length constraints on `todos`, not `idempotency_keys` | Low | tests | Accept | `idempotency_keys`'s constraints are exercised indirectly by every `createPostgresStorage.int.test.ts` run (the full repository contract against real Postgres); a dedicated schema test for that table would be marginal extra coverage of the same guarantees. |

## Checklist

Copy of `checklists/milestone-review.md` with results for PR #3:

### Correctness
- [x] Behaviour matches the spec sections the PR claims (status codes, headers, validation messages) — verified against §5.1 (schema), §5.3 (Postgres adapter semantics), §5.4 (idempotent-create transaction shape).
- [ ] Error precedence 400 → 428 → 404 → 412 preserved — **N/A for this PR**: no HTTP error handler exists yet (lands in PR 5).
- [ ] No silent catch-alls; unexpected errors become logged 500s — **N/A for this PR**: no error handler/logging code exists yet; `PgUnitOfWork`'s one `catch` rethrows the original error after attempting rollback, it does not swallow anything.

### Concurrency
- [x] Every write is a single statement or inside the unit of work — every `PgTodoRepository`/`PgIdempotencyStore` method is one SQL statement; the idempotent-create path (claim + insert) is wrapped in `PgUnitOfWork.run`, a real `BEGIN`/`COMMIT`/`ROLLBACK` transaction on a dedicated pooled client.
- [x] Version bumps only on real changes; conditional writes use the version — `update`/`delete` are conditional on `expectedVersion`; `setCompleted` bumps the version only inside the conditional `WHERE is_completed <> $2` branch, matching the same rule already established for the in-memory adapter.
- [x] New code paths covered by an invariant test if they touch shared state — the adapter-agnostic contract suite's UnitOfWork commit/rollback and 5-way concurrent same-key claim race now also runs against real Postgres via `createPostgresStorage.int.test.ts`, proving the invariant holds under an actual transaction, not just the in-memory mutex.

### Tests
- [x] Test written first (visible in the commit) and mirrors the source path — confirmed via both task reports' RED/GREEN evidence; `apps/api/tests/repository/postgres/**` and `apps/api/tests/migrations/**` mirror their source 1:1.
- [x] 100% coverage without `v8 ignore` — confirmed via both task reports' full-gate output (100/100/100/100, every new `postgres/*.ts` file individually 100%) and `grep -rn "v8 ignore"` (none found) across the new files.
- [x] Assertions check behaviour, not implementation details or timings — reviewed all new test files; `PgUnitOfWork.test.ts` asserts the sequence of SQL statements issued (`BEGIN`/`COMMIT`/`ROLLBACK`) and the release flag, which is the class's documented contract, not an internal implementation detail; no wall-clock timing anywhere.

### Architecture
- [x] Layer rules respected (lint passes); composition only in `app.ts` — manually verified no `postgres/*.ts` file imports from `in-memory/*`; only `../ports.js`, `../../domain/todo.js`, `@foci/shared`; `app.ts` doesn't exist yet so the composition-root rule has nothing to violate.
- [x] No new dependency without a reason in the commit or an ADR — `pg`, `node-pg-migrate`, `@types/pg` are exactly what a Postgres adapter and its migration runner require, documented in the task report.

### Docs
- [ ] README / guides / OpenAPI still accurate (no drift) — **N/A for this PR**: README and docs/ land in PR 10; nothing exists yet to drift.
- [ ] New decisions recorded as ADRs — **N/A for this PR**: the one implementation adaptation (node-pg-migrate 9's `logger` option in place of the brief's assumed `log`) is a mechanical fix to match the installed library's real API, not a design decision, and is recorded in the task report rather than a new ADR.

### Security & operability
- [x] Inputs validated with shared schemas; no secrets or stack traces in responses — no new input surface in this PR (no HTTP yet); reviewed all new files for stray credentials or debug output, none found; `testDatabaseUrl()` actively refuses to run destructive tests against a non-`_test` database.
- [ ] Images non-root; no dev dependencies in runtime images — **N/A for this PR**: no Dockerfile changes; `api`/`web` runtime images land in later PRs.

**Verdict: clean.** No Critical or Important findings. Seven Low-severity polish items (F-6…F-12) are accepted as-is per the controller's pre-triage; none affect correctness, concurrency guarantees, or the 100% coverage gate.
