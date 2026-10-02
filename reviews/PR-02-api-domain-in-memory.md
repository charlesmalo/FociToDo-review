# Review — PR #2 feat(api): domain model, in-memory storage and repository contract

- App commit range: `c2eb6ae..5ae431e` (`5ae431e` is a pre-squash SHA, not on main; the curated branch merged as `a698697`) · Date: 2026-10-01 · Reviewer: Claude Code (automated) + solution-lead triage
- PR not yet merged; this review is recorded ahead of merge per the controller's instruction.

## Automated review output

Scope of PR #2 (commits `ed58363` domain model/errors/clock/id ports, `c54f188` repository ports and deterministic ordering, `5ae431e` in-memory adapters and the repository contract suite; `c54f188` and `5ae431e` are pre-squash SHAs, not on main — curated to `985e363` and `7efd1c2`): the `@foci/api` workspace's pure domain layer, the storage-port interfaces (`TodoRepository`, `IdempotencyStore`, `UnitOfWork`, `Storage`, `DatabaseProbe`), the first (in-memory) storage adapter, and the adapter-agnostic `repository.contract.ts` suite that will also run against the Postgres adapter in PR 3. No `service`, `http`, or `app.ts` code exists yet — out of scope for this PR by plan sequencing.

Diff reviewed line-by-line (`review-c2eb6ae..5ae431e.diff`, 999 insertions across 28 files) against `docs/superpowers/specs/2026-09-30-foci-todo-design.md` §5.2–5.3, §6, and `global-constraints.md`. Also read the three per-task reports and their embedded TDD transcripts (RED/GREEN/full-gate), and cross-checked the working tree's local `reports/coverage/coverage-summary.json` against the current `vitest.config.ts` coverage config.

**Correctness**
- `apps/api/src/domain/todo.ts`: `Todo`/`TodoPatch` match spec §5.2; `isOverdue` (`!isCompleted && dueDate !== null && dueDate < today`) and `toView` match the state diagram's note and `TodoView` (checked field-for-field against `packages/shared/src/todo.ts`'s `TodoViewSchema`) exactly.
- `apps/api/src/domain/errors.ts`: all four error classes/messages match spec §5.2 and the §5.5 error-format table's source column verbatim.
- `apps/api/src/domain/clock.ts` / `ids.ts`: `Clock`/`IdGenerator` ports match spec; `utcDate` correctly uses `toISOString().slice(0,10)` (UTC, not local offset — verified by the "near midnight" test).
- `apps/api/src/repository/ports.ts`: `TodoRepository`, `IdempotencyStore`, `UnitOfWork`, `Storage` match spec §5.3 verbatim (plus `DatabaseProbe`/`DatabaseStatus`, forward declarations for the `/api/health` route in a later PR — harmless, unused so far).
- `apps/api/src/repository/in-memory/ordering.ts`: `compareCodePoints` iterates by code point (not UTF-16 units), matching Postgres `COLLATE "C"`; `matchesStatus` and `compareTodos` match spec exactly, including `NULLS LAST` in both directions and the fixed `created_at DESC, id ASC` tie-break applied independent of the requested sort direction.
- `InMemoryTodoRepository`: `create`/`findById`/`list`/`update`/`setCompleted`/`delete` match the port contracts; `update` always bumps the version on a successful conditional write (per the controller's recorded ruling that "version only on real changes" applies to `setCompleted`, not `update`); `setCompleted` bumps the version only when the flag actually changes, matching spec §5.3.
- `InMemoryIdempotencyStore`: `find`/`claim` correctly treat records with `createdAt < notBefore` as expired and allow them to be reclaimed, matching spec §5.4's `ON CONFLICT … WHERE created_at < notBefore` semantics.
- `AsyncMutex` / `InMemoryUnitOfWork`: promise-tail mutex correctly serialises `run()` calls and releases the lock on both success and failure; `UnitOfWork.run` snapshots the two `Map`s before invoking `work` and restores them only on throw, matching spec §5.3's "serialises callbacks with an async mutex" and the commit/rollback behaviour proven by the contract suite (including the 5-way concurrent same-key claim test — exactly one claim succeeds).
- `repository.contract.ts`: a thorough, adapter-agnostic suite (round-trip, duplicate id, partial/null-clearing updates, stale-version refusal, unknown-id handling, status filter × sort × tie-break combinations, idempotency expiry/replacement, unit-of-work commit/rollback/race) that will double as the Postgres adapter's acceptance test in PR 3.
- No HTTP, service, or `app.ts` code exists yet, so error precedence, silent-catch-all, and composition-root checklist items have nothing to verify (confirmed intentional by plan sequencing, as in PR #1).

**Already resolved during per-task review (not re-litigated, recorded as Fixed below):**
- (a) An unneeded `coverage.exclude` entry for the types-only `repository/ports.ts` was added speculatively in task 2, then removed in a same-task fix round after verifying the full gate reports 100%/100%/100%/100% without it (confirmed independently: current `vitest.config.ts` excludes only `apps/api/src/server.ts`, `apps/web/src/main.tsx`, `**/*.d.ts`; the working tree's `reports/coverage/coverage-summary.json` shows `total` 100/100/100/100 with `ports.ts` correctly shown at 0/0 coverable statements, same cosmetic pattern as `packages/shared/src/index.ts` from PR #1's F-1).
- (b) `InMemoryTodoRepository` and `InMemoryIdempotencyStore` originally copied records with shallow spreads (`{ ...todo }`), leaking the reference-typed `Date` (`createdAt`) and `body` (`unknown`) fields; a caller mutating a returned value silently corrupted the stored row — behaviour Postgres cannot reproduce. Fixed by switching every copy-in/copy-out path to `structuredClone(...)`, with two new contract tests (`'returns detached dates'`, `'stores and returns detached records'`) pinning the fix for both adapters going forward. Verified present in the final diff (`structuredClone` used throughout `InMemoryTodoRepository.ts` and `InMemoryIdempotencyStore.ts`).

**Tests**: Confirmed via the three task reports' RED→GREEN→full-gate TDD evidence (14 → 104 → 132+ tests, each gate run exit 0) and independently via the working tree's `reports/coverage/coverage-summary.json` (`total`: 133/133 lines, 154/154 statements, 50/50 functions, 66/66 branches, all 100%). `grep -rn "v8 ignore" packages apps` returns nothing. Every new test file mirrors its source path 1:1 (`src/domain/todo.ts` → `tests/domain/todo.test.ts`, etc.); `repository.contract.ts` and `tests/support/*` are shared test infrastructure, not source-mirroring unit tests, consistent with the pattern established in PR #1. Assertions check return values, stored-state side effects, and error behaviour — not implementation details or timings (the one timing-adjacent test, `AsyncMutex`'s ordering test, asserts event order via a recorded array, not wall-clock timing).

**Architecture**: `eslint.config.js`'s `import-x/no-restricted-paths` zones (already wired in PR #1) are first exercised by real files in this PR — manually verified no domain file imports from `repository`/`service`/`http`, and no repository file imports from `service`/`http`; the only cross-package import is `@foci/shared` (the shared contract, not an inner app layer), which the zone rules do not restrict. No `app.ts` exists yet, so there is nothing to violate the composition-root rule. No new third-party dependency was added (`apps/api/package.json` depends only on the workspace's `@foci/shared`).

**No Critical or Important findings remain open.** One Important finding (the reference-leak bug, item (b) above) was caught and fixed within this PR's own per-task review cycle before merge, with regression tests. One Low-severity process nit (a stale commit message) and the two already-known items are carried into the triage table below.

## Triage

| Finding | Severity | Category | Decision | Reason |
|---|---|---|---|---|
| F-3 In-memory `TodoRepository`/`IdempotencyStore` leaked reference-typed `Date`/`body` fields through shallow-spread copies, letting a caller's mutation of a returned value silently corrupt the stored row | Important | correctness | Fix | Already fixed in-branch via `structuredClone` on every copy-in/copy-out path, with two new contract tests (`'returns detached dates'`, `'stores and returns detached records'`) pinning the behaviour for every future adapter. Verified present in the final diff. |
| F-4 Speculative `coverage.exclude` entry added for the types-only `repository/ports.ts` without first confirming the gate needed it | Low | tests | Fix | Already fixed in-branch: removed after the full gate confirmed 100/100/100/100 without it; verified independently against the current `vitest.config.ts` and the working tree's coverage summary. |
| F-5 Commit `c54f188`'s message says it "excludes types-only ports.ts from coverage thresholds," but the final squashed commit carries no such `vitest.config.ts` change (the exclusion was added and removed within the same task, per F-4, and the fix-round commit was folded in) | Low | docs | Accept | Cosmetic commit-message/history mismatch only; the code and the coverage gate are correct in the final state. No action needed. |

## Checklist

Copy of `checklists/milestone-review.md` with results for PR #2:

### Correctness
- [x] Behaviour matches the spec sections the PR claims (status codes, headers, validation messages) — verified against §5.2 (domain), §5.3 (repository ports and in-memory semantics), §6 (concurrency guarantees, in-memory subset).
- [ ] Error precedence 400 → 428 → 404 → 412 preserved — **N/A for this PR**: no HTTP error handler exists yet (lands in PR 5).
- [ ] No silent catch-alls; unexpected errors become logged 500s — **N/A for this PR**: no error handler/logging code exists yet.

### Concurrency
- [x] Every write is a single statement or inside the unit of work — in-memory repository methods contain no internal `await`, so each runs to completion without interleaving; multi-step work (idempotency claim + todo insert) is wrapped in `UnitOfWork.run`, serialised by `AsyncMutex`.
- [x] Version bumps only on real changes; conditional writes use the version — `update`/`delete` are conditional on `expectedVersion`; `setCompleted` bumps the version only when the flag changes (per the controller's recorded ruling that "version only on real changes" applies to `complete`/`incomplete`, not `update`, which bumps on every successful conditional write per §5.3).
- [x] New code paths covered by an invariant test if they touch shared state — the contract suite's "lets exactly one of several concurrent units claim the same key" test (5 parallel `unitOfWork.run` calls, `Promise.all`) asserts the invariant rather than timing.

### Tests
- [x] Test written first (visible in the commit) and mirrors the source path — confirmed via all three task reports' RED/GREEN evidence; `apps/api/tests/**` mirrors `apps/api/src/**` 1:1 (plus shared `tests/support/*` and the adapter-agnostic `tests/repository/repository.contract.ts`).
- [x] 100% coverage without `v8 ignore` — confirmed via the working tree's `reports/coverage/coverage-summary.json` (`total` 100/100/100/100) and `grep -rn "v8 ignore"` (none found) across `packages/` and `apps/`.
- [x] Assertions check behaviour, not implementation details or timings — reviewed all eight new test files; assertions target returned values, stored-state side effects, and recorded event order, not internal implementation or wall-clock timing.

### Architecture
- [x] Layer rules respected (lint passes); composition only in `app.ts` — manually verified no `domain`/`repository` file imports an outer layer; `app.ts` doesn't exist yet so the composition-root rule has nothing to violate.
- [x] No new dependency without a reason in the commit or an ADR — `apps/api/package.json`'s only dependency is the workspace's own `@foci/shared`; no new third-party packages.

### Docs
- [ ] README / guides / OpenAPI still accurate (no drift) — **N/A for this PR**: README and docs/ land in PR 10; nothing exists yet to drift.
- [ ] New decisions recorded as ADRs — **N/A for this PR**: the one interpretive decision made (PATCH bumps the version on every successful conditional update; "version only on real changes" applies to `complete`/`incomplete`) is a clarification of already-approved spec §5.3 behaviour, recorded in the controller's ruling log rather than a new ADR.

### Security & operability
- [x] Inputs validated with shared schemas; no secrets or stack traces in responses — no new input surface in this PR (no HTTP yet); repository/domain code introduces no secrets; reviewed all new files for stray credentials or debug output, none found.
- [ ] Images non-root; no dev dependencies in runtime images — **N/A for this PR**: only the `test` Docker target is touched (one added `COPY` line for `apps/api/package.json`); `api`/`web` runtime images land in later PRs.

**Verdict: clean.** No Critical or Important findings remain open. One Important finding from this PR's own per-task review cycle (F-3) was already fixed in-branch with regression tests before this milestone review; two Low-severity items (F-4, F-5) are accepted as-is.
