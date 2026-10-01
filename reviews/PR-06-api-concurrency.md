# Review — PR #6 test(api): concurrency invariant suite

- App commit range: `8424d19..139eb97` · Date: 2026-10-01 · Reviewer: Claude Code (automated) + solution-lead triage

## Automated review output

Scope of PR #6 (single commit `139eb97`): one new file, `apps/api/tests/http/todoRoutes.concurrency.test.ts`
(194 insertions, no other files touched — confirmed via `review-8424d19..139eb97.diff` and `git show 139eb97
--stat`). No `apps/api/src` changes; this PR only adds tests against the behaviour already implemented and
reviewed in PR #3 (Postgres adapter), PR #4 (service), and PR #5 (HTTP layer).

Diff reviewed line-by-line against spec §6 (Concurrency guarantees table and its five rows: atomic writes, no
lost updates, idempotent status changes, idempotent create, deterministic delete races) and the milestone
checklist. Cross-checked against `apps/api/src/repository/postgres/PgTodoRepository.ts`,
`apps/api/src/service/TodoService.ts`, and the implementer's mutation-check evidence
(`.superpowers/sdd/06-api-concurrency/task-1-report.md`).

**Correctness / Concurrency**
- All five §6 guarantees get a dedicated scenario, each run for 5 rounds against a real listening HTTP server
  (`runtime.app.listen(0)`) and real Postgres, matching the spec's own prescription ("assert invariants rather
  than timings... repeat each scenario several rounds"):
  1. Atomic writes — 50 parallel `POST /todos` → all 201, 50 unique ids, `countTodos() === 50`.
  2. No lost updates — two `PATCH`es from the same version → sorted statuses `[200, 412]`; final state matches
     the winner's title at version 2.
  3. No lost updates under mixed contention — 10 patches + 5 completes racing; asserts ≤1 successful patch and
     a final version consistent with exactly one complete plus the successful-patch count.
  4. Idempotent status changes — 20 parallel completes (all 200, version → 2), then 20 parallel reopens (all
     200, version → 3) — matches the `is_completed <> $2` conditional-update mechanism in
     `PgTodoRepository.setCompleted`.
  5. Deterministic delete races — 10 parallel deletes from the same version → sorted `[204, 404×9]`,
     `countTodos() === 0`.
  6/7. Two extra scenarios beyond the spec table's five rows, both in scope of §6's general "no lost updates"
     mechanism: delete-vs-patch from the same version (exactly one of `[204,404]`/`[412,200]` outcomes), and
     idempotent create with 5 parallel POSTs sharing one `Idempotency-Key` (one row, identical bodies, exactly
     one non-replayed response).
  8. Idempotent create with conflicting bodies on the same key → winner's requests get 201, the rest 422
     (`IdempotencyKeyReuseError`), matching PR #4's `hashCreateRequest` design.
- Independently re-read `PgTodoRepository.update`/`.delete`/`.setCompleted` (`apps/api/src/repository/postgres/
  PgTodoRepository.ts:62-93`): single-statement conditional `UPDATE ... WHERE id = $1 AND version = $2` /
  `DELETE ... WHERE id = $1 AND version = $2` / `UPDATE ... WHERE is_completed <> $2`, matching the spec's
  "Mechanism" column exactly for every row. No behavioural change was needed or made — the suite is purely
  confirmatory, as the task brief intended.

**Tests**
- Independently re-ran the full gate from a clean build: `docker compose --profile test run --rm --build
  test` → `format:check`, `lint`, `typecheck` all clean; **29 test files, 277 tests, all passing** (269 from
  PR #5's baseline + 8 new concurrency tests); **100% stmt/branch/func/line coverage**, same two pre-existing
  0%-coverage cosmetic rows (`repository/ports.ts`, `shared/index.ts`) as every prior PR, no new exclusions.
  `grep -rn "v8 ignore"` across the new test file and `apps/api/src`: no hits.
- Mutation-check evidence (from the implementer's report, independently assessed rather than re-run): a
  literal reading of the plan's prescribed mutation to `PgTodoRepository.update` (delete only `AND version =
  $2` from the SQL text) leaves `expectedVersion` as an orphaned, untyped bind parameter at position `$2` —
  Postgres's extended query protocol can't type it, so both concurrent PATCHes fail with `500`, not the
  predicted `[200, 200]`. The implementer correctly diagnosed this as a protocol artifact (neither write even
  executes) and used a corrected, faithful mutation (also dropping `expectedVersion` from the `values` array)
  which reproduces `[200, 200]` exactly as §6 predicts, and which also flips the mixed-contention test from
  ≤1 to 10 successful patches. Only `update`'s version guard was mutation-tested this way; `delete`'s guard and
  the idempotency claim-first ordering in `TodoService.create` were not independently mutated in the app repo.
  Revert was verified clean (`git diff apps/api/src/` empty).
- Assertions check final state and status-code sets, not call counts or timings, consistent with "assert
  invariants rather than timings."

**Already raised as Minor in the per-task review (not re-litigated; recorded as Low/Accept below per the
controller's pre-triage):**
- Delete-vs-patch test's name ("... state matches the winner") overstates what's checked: only `countTodos()`
  (0 or 1) is asserted for the patch-wins branch, not that the surviving row's title actually equals `'Edited'`.
- The conflicting-bodies idempotent-create test doesn't independently assert exactly one non-replayed 201 (no
  check of `created.length === 1` or the `idempotent-replayed` header); its per-response assertion is only
  consistent with, not a direct proof of, a single winner.
- The atomic-writes test doesn't schema-validate the 50 response bodies against `TodoViewSchema` — it only
  checks `status === 201`, id uniqueness, and row count.
- `beforeAll` (`todoRoutes.concurrency.test.ts:16-21`) calls `server = runtime.app.listen(0)` without awaiting
  a `'listening'` event before tests run.
- Only `PgTodoRepository.update`'s version guard was mutation-tested in the app repo; `delete`'s guard and the
  idempotency claim-first path are deferred to the review repo's k6 stress pass.
- The SDD plan's literal mutation text is wrong for this codebase (produces `[500, 500]` via an orphaned `$2`
  bind parameter, not the predicted `[200, 200]`); the corrected, behaviourally-faithful mutation does
  reproduce `[200, 200]`.

**No new Critical or Important findings.** The suite is a pure test addition, passed on first run against the
unmodified implementation (no regression, no new `src/` behaviour), and its own mutation check against the
most safety-critical line in scope (`PgTodoRepository.update`'s `WHERE ... AND version = $2`) demonstrates the
"no lost updates" test is not vacuous. All items below are coverage/robustness-of-the-test-suite nits already
identified at the per-task level, carried forward here as Low/Accept.

## Triage

| Finding | Severity | Category | Decision | Reason |
|---|---|---|---|---|
| F-21 Delete-vs-patch test name ("... state matches the winner") overstates: only row count (0/1) is checked for the patch-wins branch, not that the surviving row's title equals the patcher's title | Low | tests | Accept | Marginal extra coverage; the title-persistence path is already proven by the "no lost updates" test's own `toMatchObject({ title: winner?.body.title, ... })` assertion against the same `update` code path. |
| F-22 Conflicting-bodies idempotent-create test doesn't independently assert exactly one non-replayed 201 (`created.length === 1` / `idempotent-replayed` header) | Low | tests | Accept | The per-response consistency check (`status === titles[index] === winnerTitle ? 201 : 422`) combined with `countTodos() === 1` makes a >1-winner race very hard to pass undetected in practice, but is not a direct proof; the sibling "idempotent create" test two cases above does check the non-replayed count explicitly for the same-body case. |
| F-23 Atomic-writes test doesn't schema-validate the 50 response bodies against `TodoViewSchema` | Low | tests | Accept | `todoRoutes.int.test.ts` already schema-validates `TodoView` shape for every route; re-validating under load adds coverage of load, not of schema correctness, which is adapter-independent. |
| F-24 `beforeAll` doesn't await the server's `'listening'` event before tests run (`todoRoutes.concurrency.test.ts:16-21`) | Low | tests | Accept | No flakiness observed across 8 scenarios × 5 rounds on first run or re-run; Node's `listen(0)` on loopback resolves fast enough in practice that this hasn't manifested, but it is a latent race worth an `await new Promise(resolve => server.on('listening', resolve))` if flakiness ever appears. |
| F-25 Only `PgTodoRepository.update`'s version guard was mutation-tested in the app repo; `delete`'s conditional guard and `TodoService.create`'s claim-first ordering were not independently mutated here | Low | tests | Accept | Deferred by design to the review repo's k6 stress-and-fault-injection pass (separate from this PR's scope); the `delete` guard uses the identical `WHERE id = $1 AND version = $2` pattern already proven fragile-but-correct by the `update` mutation, and the deterministic-delete-races scenario already exercises it under real contention. |
| F-26 The SDD plan's literal mutation instruction for Step 3 (delete only `AND version = $2` from the SQL text) produces `[500, 500]` (orphaned `$2` bind parameter) in this codebase, not the predicted `[200, 200]` | Low | docs | Accept | Documentation/plan-artifact issue, not an app defect — the implementer correctly diagnosed the protocol-level cause and substituted a faithful equivalent mutation that does reproduce `[200, 200]`. Worth fixing in the plan source for future reviewers, out of scope for this app PR. |

## Checklist

Copy of `checklists/milestone-review.md` with results for PR #6:

### Correctness
- [x] Behaviour matches the spec sections the PR claims (status codes, headers, validation messages) — no new behaviour; the suite proves existing §6-claimed behaviour (status-code sets, final version/state) against the real HTTP+Postgres stack.
- [x] Error precedence 400 → 428 → 404 → 412 preserved — unchanged; not re-exercised by this PR (already proven in PR #5), and not in scope for a pure concurrency suite.
- [x] No silent catch-alls; unexpected errors become logged 500s — unchanged; no new error paths.

### Concurrency
- [x] Every write is a single statement or inside the unit of work — confirmed by direct re-read of `PgTodoRepository.update`/`.delete`/`.setCompleted` (single-statement conditional writes) and `TodoService.create`'s `unitOfWork.run` for idempotent create; unchanged from PR #4/#5, independently re-verified here.
- [x] Version bumps only on real changes; conditional writes use the version — `setCompleted`'s `WHERE is_completed <> $2` and `update`'s `WHERE version = $2` both confirmed; directly exercised by the idempotent-status-changes scenario (version bumps exactly once across 20 parallel completes).
- [x] New code paths covered by an invariant test if they touch shared state — N/A in the strict sense (no new `src/` code paths); the PR instead retroactively adds the invariant-test coverage for all five §6 guarantees that was missing until now, which is this PR's whole purpose.

### Tests
- [~] Test written first (visible in the commit) and mirrors the source path — N/A in the traditional TDD sense: this is a single confirmatory test file added in one commit against already-implemented, already-reviewed `src/` behaviour (PRs #3–#5), not a red-green cycle; it does not mirror one `src/` file but exercises `PgTodoRepository`, `TodoService`, and `todoRoutes.ts` together end-to-end, which is correct for a concurrency/invariant suite.
- [x] 100% coverage without `v8 ignore` — independently re-ran `docker compose --profile test run --rm --build test` from a clean build: 277/277 tests pass (269 baseline + 8 new), 100% stmt/branch/func/line, same two pre-existing cosmetic 0% rows as every prior PR; `grep -rn "v8 ignore"` found nothing new.
- [~] Assertions check behaviour, not implementation details or timings — true for 6 of 8 scenarios; F-21/F-22/F-23 (above) note three spots where the assertions are slightly weaker than their test names imply (row-count-only checks rather than full state/schema checks). None are false positives — all accepted as Low.

### Architecture
- [x] Layer rules respected (lint passes); composition only in `app.ts` — confirmed via the full gate's lint step (passed); the test file imports only `createRuntime`/`Runtime` from `app.ts`, `loadConfig`, and test-support helpers — no new `src/` imports or composition.
- [x] No new dependency without a reason in the commit or an ADR — no new dependencies; `supertest` was already a dev dependency from PR #5.

### Docs
- [ ] README / guides / OpenAPI still accurate (no drift) — **N/A for this PR**: test-only change, no user-facing or API-surface change.
- [ ] New decisions recorded as ADRs — **N/A for this PR**: no design decisions; brief itself records three minor deviations (commit-trailer model name, the corrected mutation, and the absence of a "per-PR procedure" doc), none requiring an ADR.

### Security & operability
- [x] Inputs validated with shared schemas; no secrets or stack traces in responses — unchanged; not exercised by this PR beyond what PR #5 already covers.
- [x] Images non-root; no dev dependencies in runtime images — unchanged; not touched by this PR.

**Verdict: clean.** No Critical or Important findings. This PR is a pure, additive test file that closes the
NFR-4 concurrency-guarantee gap left open since PR #5 (all five spec §6 rows now have a direct, independently
re-run, passing invariant test against the real stack, plus a mutation check proving the "no lost updates"
test is not vacuous). Six Low-severity items are accepted as-is (F-21…F-26): five are coverage nits in the new
test file itself (test names slightly overstating what's asserted, or a latent-but-unobserved `beforeAll` race)
and one is a documentation defect in the SDD plan's own mutation-testing instructions, not in the app. Full
gate independently re-run from a clean Docker build: 277/277 tests passing, 100% coverage, lint/typecheck/
format clean. Stress/fault-injection verification of the `delete` guard and the idempotency claim-first
ordering (k6) is explicitly deferred to the review repo, per NFR-4's traceability note below.
