# Review — PR #1 feat: foundation tooling and shared contract

- App commit range: `e4965d0..16b814b` · Date: 2026-10-01 · Reviewer: Claude Code (automated) + solution-lead triage
- PR not yet merged; this review is recorded ahead of merge per the controller's instruction.

## Automated review output

Scope of PR #1 (per `docs/superpowers/plans/2026-09-30-foci-todo/01-foundation-shared-contract.md`): npm-workspaces tooling (TypeScript, ESLint layer rules, Prettier, Vitest with a 100% coverage gate), the Docker `test`/`dev` harness, the CI test job, AI-agent docs, and the complete `@foci/shared` contract package (`problem.ts`, `todo.ts`, `listQuery.ts`, `headers.ts`, `index.ts`). No `apps/api` or `apps/web` code exists yet — out of scope for this PR by plan sequencing.

Diff reviewed line-by-line (`review-e4965d0..16b814b.diff`, 4454 lines; all non-`package-lock.json` hunks read in full, ~1160 lines across 20 new files) against the spec (`docs/superpowers/specs/2026-09-30-foci-todo-design.md`) and `global-constraints.md`.

**Correctness**
- `packages/shared/src/problem.ts`: `PROBLEM_TYPES` matches the §5.5 error-format table exactly (9 distinct `/problems/...` URIs); `ProblemSchema` matches the RFC 9457 shape; `toFieldErrors` correctly flattens Zod issues, fans out `unrecognized_keys` into one field error per key, and uses `field: null` for root-level issues per amendment A8.
- `packages/shared/src/todo.ts`: `CreateTodoSchema`/`UpdateTodoSchema` correctly enforce DR-2 (title trim/1–200), DR-3 (description ≤2000, `''`→`null`), DR-4 (strict real `YYYY-MM-DD`, past allowed); strict-object rejection of client-supplied `id`/`createdAt`/`isCompleted`/`version`/`isOverdue` and unknown keys matches §5.5; `UpdateTodoSchema` correctly refuses to let `title` be cleared (assumption 4) while allowing `description`/`dueDate` to be cleared with `null`.
- `packages/shared/src/listQuery.ts`: `ListTodosQuerySchema` matches §5.5 list-query rules (defaults `all`/`createdAt`/`desc`); `z.strictObject` + scalar enums correctly reject both unknown keys and repeated/array query values (Review Focus item 1) at the schema layer.
- `packages/shared/src/headers.ts`: `IfMatchSchema` regex `^"[1-9]\d{0,8}"$` enforces a strong ETag of a 1–9-digit positive integer with no leading zero, matching the global constraint and keeping `MAX_VERSION` (999,999,999) safely under Postgres `integer` range (Review Focus item 3). `IdempotencyKeySchema` and `toEtag` are correct and minimal.
- `eslint.config.js`: `import-x/no-restricted-paths` zones implement the §4.4 layer table (domain/service/repository/http, plus web todos/dev/api) exactly, including the extra `no-restricted-imports` bans on `pg`/`express`/`pino*` in `domain`/`service` and `pg` in `http`. Task 1's report documents a probe that positively confirmed the zone wiring actually fires (not just configured).
- Tooling manifests (`package.json`, `tsconfig.base.json`, `vitest.config.ts`, `Dockerfile`, `compose.yaml`) match global constraints: TypeScript `~6.0.3`, ESM everywhere, explicit `.js` extensions in shared source, coverage thresholds 100/100/100/100 with the exact three exclusions, `COVERAGE_DIR` wiring between Dockerfile/compose/vitest config all consistent.

**Concurrency / Architecture / Docs / Security checklist items**: mostly not yet applicable — this PR has no repository, service, or HTTP code, so "every write is a single statement," "version bumps only on real changes," "composition only in app.ts," "images non-root," and "README/OpenAPI accurate" have nothing to verify yet. Confirmed this is intentional sequencing (plan files 02–10 add that code) rather than a gap.

**Tests**: Confirmed 100% coverage via the committed `reports/coverage/coverage-summary.json` (lines/branches/functions/statements all 100 in the `total` row) and via the four task reports' TDD evidence (RED then GREEN for each file, final full-gate run green). `grep -rn "v8 ignore"` across `packages/` and `apps/` returns nothing — no coverage escape hatches. Assertions in `packages/shared/tests/*.test.ts` check output values and error messages, not implementation details or timings.

**No Critical or Important findings.** Two Low-severity items were already flagged in per-task review and are carried into the triage table below without re-litigation.

## Triage

| Finding | Severity | Category | Decision | Reason |
|---|---|---|---|---|
| F-1 v8 coverage report's per-file row shows `packages/shared/src/index.ts` at 0% while the aggregate/gate-checked `total` row is 100% | Low | tests | Accept | Documented cosmetic artifact of the v8 provider for a file with zero coverable statements (pure re-exports); does not affect the enforced threshold or the actual coverage guarantee. No action needed unless `index.ts` later gains real logic. |
| F-2 `packages/shared/tests/headers.test.ts` rejects `"1000000000"` (10 digits) rather than the spec's literal boundary example `"9999999999"` | Low | tests | Accept | Same boundary condition (any ≥10-digit value fails the same `^"[1-9]\d{0,8}"$` regex); behaviourally equivalent test, cosmetic naming/documentation mismatch only. |

## Checklist

Copy of `checklists/milestone-review.md` with results for PR #1:

### Correctness
- [x] Behaviour matches the spec sections the PR claims (status codes, headers, validation messages) — verified against §2.2, §4.2–4.4, §5.5, §8.1–8.4, §9.2–9.3.
- [ ] Error precedence 400 → 428 → 404 → 412 preserved — **N/A for this PR**: no HTTP error handler exists yet (lands in PR 5 per the plan); problem *types* are defined correctly but not yet wired to any precedence logic.
- [ ] No silent catch-alls; unexpected errors become logged 500s — **N/A for this PR**: no error handler/logging code exists yet.

### Concurrency
- [ ] Every write is a single statement or inside the unit of work — **N/A for this PR**: no repository/service code exists yet.
- [ ] Version bumps only on real changes; conditional writes use the version — **N/A for this PR**: no repository code exists yet; `version` is only a schema field so far.
- [ ] New code paths covered by an invariant test if they touch shared state — **N/A for this PR**: no shared mutable state exists yet.

### Tests
- [x] Test written first (visible in the commit) and mirrors the source path — confirmed via task reports' RED/GREEN evidence; `packages/shared/tests/*.test.ts` mirrors `packages/shared/src/*.ts` 1:1.
- [x] 100% coverage without `v8 ignore` — confirmed via `reports/coverage/coverage-summary.json` aggregate and `grep` for `v8 ignore` (none found). Per-file `index.ts` display quirk noted as F-1 (accepted).
- [x] Assertions check behaviour, not implementation details or timings — reviewed all five test files; assertions target parsed values, error messages and issue shapes.

### Architecture
- [x] Layer rules respected (lint passes); composition only in `app.ts` — layer-rule zones correctly implement §4.4 and were positively probed (task 1 report); `app.ts` doesn't exist yet so the composition-root rule has nothing to violate.
- [x] No new dependency without a reason in the commit or an ADR — all added devDependencies/dependencies are tooling (ESLint/Prettier/Vitest/TypeScript/Zod) called for directly by the plan and spec §4.2.

### Docs
- [ ] README / guides / OpenAPI still accurate (no drift) — **N/A for this PR**: README and docs/ are delivered in PR 10 per the plan; nothing exists yet to drift.
- [ ] New decisions recorded as ADRs — **N/A for this PR**: no new design decisions were made beyond what the approved spec/ADR list (§10) already covers; this PR is pure implementation of previously-approved tooling choices.

### Security & operability
- [x] Inputs validated with shared schemas; no secrets or stack traces in responses — shared schemas are strict by design; no secrets found in committed files (`.claude/settings.json` is a permission allowlist only; `compose.yaml`'s `todo`/`todo` credentials are the spec's documented dev-only defaults, §8.2).
- [ ] Images non-root; no dev dependencies in runtime images — **N/A for this PR**: only the `test` Docker target exists so far; `api`/`web` runtime images land in later PRs.

**Verdict: clean.** No Critical or Important findings. Two previously-known Low-severity items accepted as-is.
