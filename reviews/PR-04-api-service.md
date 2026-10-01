# Review — PR #4 feat(api): service layer

- App commit range: `bdbb54b..c2445fb` · Date: 2026-10-01 · Reviewer: Claude Code (automated) + solution-lead triage
- PR not yet merged; this review is recorded ahead of merge per the controller's instruction.

## Automated review output

Scope of PR #4 (commits `bffd56b` request hashing + health service, `c2445fb` `TodoService` use cases): three new files under `apps/api/src/service/` (`HealthService.ts`, `TodoService.ts`, `requestHash.ts`) and their mirrored tests (410 insertions, 6 files, no other files touched). No `http`/`app.ts` code exists yet — out of scope by plan sequencing, same as PR #1–#3.

Diff reviewed line-by-line (`review-bdbb54b..c2445fb.diff`) against spec §5.2 (domain ports/errors), §5.4 (`TodoService` use-case table and the idempotent-create race), §6 (concurrency guarantees), §9 (testing strategy), and `global-constraints.md`.

**Correctness**
- `TodoService.create`: without a key, builds `{ id: ids.next(), version: 1, isCompleted: false, createdAt: clock.now() }` and inserts — matches §5.4 verbatim. With a key, builds the todo/view in memory, then inside `unitOfWork.run`: `idempotency.claim(...)` first; claimed → insert + return `replayed: false`; not claimed → `idempotency.find(...)`; hash match → replay stored body (`TodoViewSchema.parse(existing.body)`), hash mismatch → `IdempotencyKeyReuseError`. Matches §5.4's claim-first/replay/reuse-reject shape exactly. The "not claimed" branch returns normally rather than explicitly rolling back (already raised in per-task review, see Triage).
- `update`/`delete`: `expectedVersion === undefined` → `PreconditionRequiredError` checked before any repository call, confirmed by the "requires a version (428 before anything else)" test using an id that would otherwise 404. On a failed conditional write, `notFoundOrConflict` re-reads via `findById`: missing → `TodoNotFoundError` (404), present → `VersionConflictError` (412) — matches §5.4's table and the global-constraints error-precedence rule at the service level (400/HTTP layer is out of scope here).
- `complete`/`uncomplete`: delegate to `setCompleted`; `null` → `TodoNotFoundError`. Version-bump-only-on-change semantics are the repository's responsibility (PR #2/#3) and are exercised end-to-end by the "is idempotent and bumps the version only on change" test.
- `list`/`get`/view-building: `today()` is computed once per call from `Clock` (UTC, via `utcDate`) and passed uniformly into `toView`, so overdue is derived consistently with DR-8; no stored/cached `isOverdue`.
- `HealthService.check()`: resolves `{ status: 'ok', db: 'up', schemaVersion }` on a successful probe, `{ status: 'degraded', db: 'down', schemaVersion: null }` on any rejection — matches `DatabaseProbe`'s contract ("rejects when database unreachable") and the §5.5 health endpoint's two-state shape; HTTP's 200/503 mapping is a later-PR concern.
- `requestHash.hashCreateRequest`: SHA-256 over a JSON array `[title, description ?? null, dueDate ?? null]` — absent/`null` optionals hash identically (by design, matching how `CreateTodo` normalises `''` → `null` upstream), array form keeps field boundaries explicit (tested directly: `{title:'a',description:'b'}` vs `{title:'ab',description:null}` hash differently).
- No new dependency added; no SQL/adapter code touched — correctly stays above the repository-port line specified by §5.3/§5.4.

**Tests**: 20 new `TodoService` tests + 2 `HealthService` + 4 `requestHash` tests (26 total, task reports) run against the in-memory adapter exclusively — appropriate for a service-layer PR (the Postgres-backed concurrency proof already exists at the repository level from PR #3; the real 5-way-POST/§6 HTTP-level concurrency suite is pinned to the PR that adds the HTTP layer). Independently re-ran `vitest run --project api-unit --coverage` in the `dev` container: all 86 api-unit tests pass, and `apps/api/src/service/{HealthService,TodoService,requestHash}.ts` each report 100% stmt/branch/func/line (the global threshold fails only because this run excludes the Postgres `.int.test.ts` project, which is expected and unrelated to this PR). `grep -rn "v8 ignore"` across the new files: no hits. Also independently ran `eslint` and `tsc --noEmit` against `apps/api/src/service` and `apps/api/tests/service`: both clean.

**Architecture**: `TodoService.ts`/`HealthService.ts` import only `@foci/shared`, `../domain/*`, `../repository/ports.js`, and (for `TodoService`) the sibling `requestHash.js` — no import from `repository/postgres` or `repository/in-memory`, consistent with the `import-x/no-restricted-paths` zone (`eslint.config.js`: service "may depend on repository ports only"). `app.ts` still doesn't exist, so the composition-root rule has nothing to violate yet.

**Already resolved / clarified during per-task review (not re-litigated, recorded as Accept below per the controller's list):**
- The expiry test (`'treats a key older than 24 hours as new'`) doesn't assert the expired record is actually replaced in storage or pin the exact TTL boundary (one tick past 24h, not the boundary itself) (F-13).
- No test for a malformed stored replay body (`TodoViewSchema.parse(existing.body)` throwing) or for a rollback path when the todo insert fails after a successful claim (F-14).
- On a live-key claim failure, the code returns normally from the `unitOfWork.run` callback (committing an empty unit of work) where §5.4 says "roll back"; since nothing was written on that path, the observable behaviour is identical to an explicit rollback (F-15).

**No Critical or Important findings.** This PR is a close-to-verbatim implementation of pre-approved task briefs (both task reports state "no deviations from the brief"). Independent re-verification of the diff against spec §5.2/§5.4/§6 and the global constraints, plus an independent coverage/lint/typecheck run, found no behavioural mismatch. Three pre-identified Low-severity items are carried into the triage table below as new findings (F-13…F-15); none affect correctness, and all are accepted as-is per the controller's pre-triage.

## Triage

| Finding | Severity | Category | Decision | Reason |
|---|---|---|---|---|
| F-13 The 24h-expiry test doesn't assert the old record is replaced in storage, nor pin the exact TTL boundary instant | Low | tests | Accept | The test proves the externally observable behaviour that matters (an expired key is treated as new, a second row is created); the Postgres-level `ON CONFLICT ... WHERE created_at < notBefore` statement (PR #3) is what actually guarantees replacement, and is exercised by the Postgres contract suite. A boundary-exact timer test would be marginal extra coverage of the same guarantee. |
| F-14 No test for a malformed stored replay body, or for rollback when the todo insert fails after a successful claim | Low | tests | Accept | `TodoViewSchema.parse(existing.body)` throwing on a corrupt stored body is a defence against storage-layer corruption that no code path in this PR can produce (every `claim` call is fed a freshly-built, schema-valid `view`); a failing insert after a successful claim is a `UnitOfWork` concern already covered by `PgUnitOfWork`'s rollback-and-rethrow tests (PR #3, F-6). Not a correctness gap in this PR's own code. |
| F-15 On a live-key claim failure, the code returns normally (the unit of work commits) where §5.4's prose says "roll back" | Low | correctness | Accept | Nothing was written before the `claim` returned `false` (no prior statement in that branch), so a commit and a rollback are observably identical — zero rows affected either way. Wording-level deviation from the spec's prose, not a behavioural one. |

## Checklist

Copy of `checklists/milestone-review.md` with results for PR #4:

### Correctness
- [x] Behaviour matches the spec sections the PR claims (status codes, headers, validation messages) — verified against §5.2 (domain ports/errors) and §5.4 (`TodoService` use-case table, idempotent-create race); no status codes/headers exist yet (HTTP layer, PR 5).
- [x] Error precedence 400 → 428 → 404 → 412 preserved — at the service level: `PreconditionRequiredError` (428) is thrown before any repository call in `update`/`delete`; `notFoundOrConflict` correctly orders 404 before 412 on a failed conditional write. 400 (validation) is an HTTP-layer concern, not yet implemented.
- [x] No silent catch-alls; unexpected errors become logged 500s — `TodoService`'s one `throw new Error(...)` on a disappeared idempotency record propagates uncaught (fails loudly, proven by a dedicated test); `HealthService`'s `catch` is the documented degraded-health contract, not a silent swallow (it changes the return value, doesn't hide a bug). No logging code exists yet (later PR).

### Concurrency
- [x] Every write is a single statement or inside the unit of work — `create` with a key wraps `claim` + `todos.create` in `unitOfWork.run`; without a key, a single `todos.create` call.
- [x] Version bumps only on real changes; conditional writes use the version — delegated unchanged to the repository adapters (PR #2/#3); `update`/`delete` pass `expectedVersion` through; `setCompleted`'s only-on-change rule is exercised end-to-end by the "bumps the version only on change" test.
- [x] New code paths covered by an invariant test if they touch shared state — the 5-parallel-same-key-create race is re-proven at the service level ("creates exactly one todo for concurrent requests sharing a key").

### Tests
- [x] Test written first (visible in the commit) and mirrors the source path — confirmed via both task reports' RED/GREEN evidence; `apps/api/tests/service/*.test.ts` mirrors `apps/api/src/service/*.ts` 1:1.
- [x] 100% coverage without `v8 ignore` — confirmed via both task reports' full-gate output (100/100/100/100, every new `service/*.ts` file individually 100%) and independently via a fresh `vitest run --project api-unit --coverage` (all three new files individually 100% stmt/branch/func/line) and `grep -rn "v8 ignore"` (none found).
- [x] Assertions check behaviour, not implementation details or timings — reviewed all new test files; assertions check returned values, thrown error types, and storage side effects (`storage.todos.list(...)`), not internal call sequencing or wall-clock timing.

### Architecture
- [x] Layer rules respected (lint passes); composition only in `app.ts` — independently ran `eslint` against `apps/api/src/service` and `apps/api/tests/service`: clean; manually confirmed no import from `repository/postgres` or `repository/in-memory`. `app.ts` doesn't exist yet so the composition-root rule has nothing to violate.
- [x] No new dependency without a reason in the commit or an ADR — no new dependency added by this PR.

### Docs
- [ ] README / guides / OpenAPI still accurate (no drift) — **N/A for this PR**: README and docs/ land in PR 10; nothing exists yet to drift.
- [ ] New decisions recorded as ADRs — **N/A for this PR**: no design decisions beyond the pre-approved task briefs; both task reports record "no deviations."

### Security & operability
- [x] Inputs validated with shared schemas; no secrets or stack traces in responses — `TodoService`/`HealthService` consume already-validated `CreateTodo`/`UpdateTodo`/`ListTodosQuery` types from `@foci/shared`; no new input surface (no HTTP yet); reviewed all new files for stray credentials or debug output, none found.
- [ ] Images non-root; no dev dependencies in runtime images — **N/A for this PR**: no Dockerfile changes; `api`/`web` runtime images land in later PRs.

**Verdict: clean.** No Critical or Important findings. Three Low-severity items (F-13…F-15) are accepted as-is per the controller's pre-triage; none affect correctness, concurrency guarantees, or the 100% coverage gate. Independently re-ran the api-unit test project, eslint, and tsc against the new files to confirm the task reports' claims.
