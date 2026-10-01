# Review — PR #12 fix: final review — fix wave for the whole-project review

- App commit range: `6b6f395..9a83851` (base = `main`) · Date: 2026-10-01 · Reviewer: Claude Code (automated) + solution-lead triage
- This is the single fix wave produced from the final whole-project review (all prior PRs 1–11). It has already
  had a scoped re-review by the fix implementer's own report
  (`.superpowers/sdd/00-index/final-fix-report.md`, status `DONE_WITH_CONCERNS`, concerns all minor and recorded
  below). This review is bookkeeping plus a light independent check against the diff
  (`review-6b6f395..9a83851.diff`, 37 non-lockfile files, 9 commits).

## Findings fixed in this PR

### Critical

**Web edit/delete flow could lose updates after a background refetch.** `TodoDetailsPanel.tsx` sent
`version: current.version` from the live detail query on Save/Delete. TanStack Query refetches on window focus;
if that refetch landed while a user had the edit form open (or the delete-confirm step showing), Save/Delete would
silently send the *new* version instead of the one the user was actually looking at, overwriting another tab's
change with no 412.

**Fix** (`febb3a2`): new `editBase` state captures the version when edit mode starts (set during render, the
"adjust state while rendering" pattern, so it covers both entering edit mode and mounting already in edit mode);
Save sends `editBase`, not `current.version`. On a 412, `rebasePending` is set, and once the triggered refetch
settles (`!todo.isFetching`), `editBase` adopts the refreshed version — so a second Save (after the user reviews
the notice) targets the fresh version instead of looping. Delete got the same treatment: `confirmingDelete: boolean`
became `deleteBase: number | null`, captured when Delete is clicked.
**Tests**: two new component tests in `TodoDetailsPanel.test.tsx` — Save after an `invalidateQueries`-triggered
refetch still sends the pre-refetch version and gets/handles a 412; Delete does the same. RED showed `[2, 2]`
instead of `[1, 2]` (Save) and the delete call keyed on the wrong version; existing 412-flow tests stay green.

### Important

**Year-0000 due dates and NUL characters in text fields reached Postgres and caused a 500.**
`z.iso.date()` accepts `0000-01-01`/`0000-02-29` (Postgres's `date` type has no year 0), and `\u0000` in
title/description passes Zod but Postgres's `text` rejects it.

**Fix** (`4f6046d`): `packages/shared/src/todo.ts` adds a `hasNoNul` refinement to both `TitleSchema` and
`DescriptionSchema` (`Title/Description must not contain control character U+0000`), and a
`!value.startsWith('0000')` refinement to `DueDateSchema`, reusing the existing message
(`Due date must be a real date in YYYY-MM-DD format`, now the `DUE_DATE_ERROR` constant). `openapi.json` is
unchanged — Zod refinements don't surface in the generated JSON Schema, confirmed by the committed-document test
passing without regeneration. docs/api.md's Validation row and README assumption 3 now state the rules.
**Tests**: boundary cases in `packages/shared/tests/todo.test.ts` (`0001-01-01` accepted, `0000-01-01`/`0000-02-29`
rejected; NUL rejected in both fields) and an `it.each` HTTP integration case in `todoRoutes.int.test.ts` asserting
400 (not 500) for each, as separate requests (so a combined request can't pass with only one half fixed). RED
showed the expected 500.

**PATCH's 415 (unsupported body charset) was missing from the OpenAPI contract**, even though the behaviour
existed (global JSON parser runs before routing) and `docs/api.md` already listed it (F-42/F-27 docs/contract
drift from PRs 7 and 10).

**Fix** (`b3492bf`): `apps/api/src/http/openapi.ts` adds `415: problem('Unsupported body charset')` to the PATCH
operation; `apps/api/openapi.json` regenerated (+10 lines, the same shape as POST's existing 415 entry).
**Tests**: new PATCH `Content-Type: application/json; charset=latin1` → 415 case in `todoRoutes.int.test.ts`, and
the real contract RED in `openapi.int.test.ts`'s "for documented error responses" conformance test (previously
missing `415` from the list of statuses seen for PATCH).

### Minor (group D) and docs (group E)

| Item | Finding (origin) | Fix | Commit |
|---|---|---|---|
| D4/D16 | F-19: a second SIGTERM/SIGINT re-ran `shutdown()` on an already-closed pool | `shuttingDown` guard flag; `loadConfigOrExit()` catches `ConfigError`, logs message only (no stack), `process.exit(1)` | `11b30eb` |
| D5 | F-43: `DevPortal` reused `DocView`/`MermaidBlock` across tab switches with no `key`, risking stale diagram state | `<DocView key={page.path} …>`; new test navigating two docs with diagrams | `77682b2` |
| D6 | F-29: `@scarf/scarf` (via `swagger-ui-dist`) runs network-calling postinstall telemetry on every `npm ci` | `ENV SCARF_ANALYTICS=false` in the Dockerfile `base` stage | `9a287e1` |
| D7 | F-32: after a successful delete, the dialog's opener is gone from the DOM, so focus-restore no-ops to `<body>` | `TodoDialog` takes a required `fallbackFocusRef`; restores focus to the opener only `if (opener?.isConnected)`, else the fallback (`TodoPage` wires "+ New task") | `d5cfee2` |
| D8 | F-21: delete-vs-patch concurrency test only checked row count (0/1) on the PATCH-wins branch, not the surviving row's content | `eachRound` now alternates send order by round so both outcomes are exercised; when PATCH wins, GETs the todo and asserts `title: 'Edited', version: 2` | `e44b794` |
| D14 | F-44/F-49: CI/local builds showed "built unknown"/fixed `1.0.0` regardless of actual build time/version | Dockerfile `build-web`: empty `ARG BUILD_DATE=` with shell default `${BUILD_DATE:-$(date -u +%Y-%m-%d)}`; `compose.yaml` web build args now pass `APP_VERSION` too | `9a287e1` |
| E9 | `docs/api.md`'s `Idempotency-Key` example was truncated (`7d1c…`), not valid ASCII | Full example key `7d1c2b9e-4a3f-4e8b-9c1d-2f6a8b0e5c41` | `9a83851` |
| E10 | All 14 ADRs' Consequences rendered `+ … − …` as one bullet | Split into `- **Positive:** …` / `- **Negative:** …` lines | `9a83851` |
| E11 | `CLAUDE.md` labelled conventions (no-SQL-outside-repository, no-fetch-outside-todoClient, single composition root) as "enforced by ESLint" | Split into "Enforced by ESLint (import boundaries)" vs. "Conventions (kept by review, not by lint)" | `9a83851` |
| E12 | `compose.yaml` hard-coded DB credentials, not overridable per spec §8.2 | `POSTGRES_USER`/`POSTGRES_PASSWORD` now `${VAR:-todo}`, all four `DATABASE_URL`s and both healthchecks built from them; documented (commented) in `.env.example`; `db-test` keeps `todo_test` | `9a83851` |
| E13 | README lacked a note about root-owned `reports/` on Linux | One-line note with the `docker run --rm -v "$PWD":/w alpine rm -rf /w/reports` fix | `9a83851` |

## Verification (from the fix report, not re-run by this review)

- Full gate: `docker compose --profile test run --rm --build test` → `Test Files 57 passed (57)`, `Tests 417 passed
  (417)`, 100/100/100/100 coverage.
- e2e: `docker compose -p foci-e2e … run --rm --build e2e` → `9 passed`; matching `down -v` → exit 0.
- `docker compose config` → exit 0, rendered with both default and overridden `POSTGRES_USER`/`POSTGRES_PASSWORD`.
- RED/GREEN evidence shown in the report for items A, B, C, D5, D7, D8.

## Self-reported concerns (from the fix report, carried forward, no action needed)

1. D5 (DevPortal key) had no true RED — `DocView`'s inline `components` map already forced React to remount
   `MermaidBlock` on a page change, so the reviewed leak doesn't reproduce today; the `key` was kept anyway as an
   explicit guarantee, with a regression test.
2. D8 (concurrency alternation) still depends on OS scheduling to exercise both outcomes; verified with a
   mutant (caught 2/2 runs) but not deterministic.
3. D14: Docker's `RUN` layer caching means an unchanged-source rebuild keeps the earlier `BUILD_DATE` — treated as
   correct behaviour (same content).
4. E12: a DB password containing URL-reserved characters would break `DATABASE_URL` construction — documented in
   `.env.example`, not encoded/escaped.

## Independent check (this review, read-only against the diff)

Reviewed the full diff directly (not solely the fix report's narrative), with particular attention to the Critical
item's render-phase state logic and the two Important fixes:

- `TodoDetailsPanel.tsx`'s render-phase `setEditBase`/`setRebasePending` calls are unconditional-per-branch (not
  inside effects), matching React's documented "adjust state during render" pattern; hook call order is unchanged
  across renders (all `useState` calls precede the early `isPending`/`isError` returns). The `rebasePending &&
  !todo.isFetching` gate correctly waits for the mutation's own `onSettled`-triggered invalidation/refetch before
  adopting a new base version, rather than racing it.
- `packages/shared/src/todo.ts`: the NUL refinement is chained after `.trim()`/length checks on title and before
  `.nullable()`/the empty-string transform on description — order is correct (refine only runs against a string).
  The dueDate refinement correctly reuses `DUE_DATE_ERROR` so the message doesn't change. Confirmed `openapi.json`
  has no corresponding diff for this commit (Zod refinements are opaque to `z.toJSONSchema`), consistent with the
  report's claim.
- `openapi.ts`/`openapi.json`/`todoRoutes.int.test.ts`/`openapi.int.test.ts` 415 addition is a straightforward,
  symmetric copy of POST's existing 415 documentation; the new test pins already-existing runtime behaviour.
- `TodoDialog.tsx`/`TodoPage.tsx`: `fallbackFocusRef` is a required prop (no untested "undefined fallback"
  branch); `(opener?.isConnected ? opener : fallbackFocusRef.current)?.focus()` is correct and matches the new
  `TodoPage.test.tsx` assertion.
- `todoRoutes.concurrency.test.ts`: the round-alternation `.then(([edited, removed]) => [removed, edited] as
  const)` correctly restores `[deleted, patched]` order regardless of which request was issued first, so the
  existing `outcome`/`countTodos` assertions are unaffected.
- `compose.yaml`/Dockerfile build-date/credentials changes read consistently end to end (shell default in the
  `RUN` line, matching `ARG`/`ENV` plumbing, `compose.yaml` passing through the same variables with the same
  defaults).

**No new Critical or Important findings from this review's own pass.** One pre-existing, already-known quirk is
being formally recorded rather than left implicit (see findings log): `dueDate: '0000-13-01'` (an already-invalid
month *and* the newly-rejected year 0000) produces two identical `400` validation messages for the `dueDate` field
in the `errors` array, because the base `z.iso.date()` format/calendar check and the new `!startsWith('0000')`
refine both fail and both carry the same `DUE_DATE_ERROR` text. This was a controller ruling (R17) during the fix
wave's scoping and is parked, not a regression — recorded as Low/Accept below.

## Checklist

Copy of `checklists/milestone-review.md` with results for PR #12:

### Correctness
- [x] Behaviour matches the spec sections the PR claims (status codes, headers, validation messages) — 412 lost-
  update fix, 400-not-500 for year-0000/NUL inputs, and the PATCH 415 contract entry all verified against source.
- [x] Error precedence 400 → 428 → 404 → 412 preserved — unchanged; `todoRoutes.int.test.ts`'s existing precedence
  test still passes, no reordering in `openapi.ts` or the route handlers.
- [x] No silent catch-alls; unexpected errors become logged 500s — `save()`/`confirmDelete()` still rethrow/report
  non-412/404 errors; `server.ts`'s new `loadConfigOrExit` rethrows anything that isn't a `ConfigError`.

### Concurrency
- [x] Every write is a single statement or inside the unit of work — unaffected by this PR (web-side version
  selection and shared-schema validation only; no SQL changed).
- [x] Version bumps only on real changes; conditional writes use the version — the web client now sends the
  *correct* captured version instead of a stale one; the server's conditional-write guard is unchanged.
- [x] New code paths covered by an invariant test if they touch shared state — D8's concurrency test alternation
  now exercises the PATCH-wins branch's stored state, not just status codes.

### Tests
- [x] Test written first (visible in the commit) and mirrors the source path — RED/GREEN evidence in the fix
  report for A, B, C, D5, D7, D8; test files mirror source 1:1.
- [x] 100% coverage without `v8 ignore` — reported 100/100/100/100; `server.ts` remains the pre-existing,
  documented coverage exclusion (verified by hand per the report, consistent with prior PRs).
- [x] Assertions check behaviour, not implementation details or timings — new assertions check mutation call
  arguments (versions sent), rendered alert text, and `toHaveFocus()`/role queries, not internals.

### Architecture
- [x] Layer rules respected (lint passes); composition only in `app.ts` — no new cross-layer imports; `TodoPage.tsx`
  remains the composition point for `fallbackFocusRef`.
- [x] No new dependency without a reason in the commit or an ADR — no new dependencies added by this PR.

### Docs
- [x] README / guides / OpenAPI still accurate (no drift) — `docs/api.md`, `docs/concurrency.md`, README
  assumption 3, and `openapi.json` all updated in step with the behaviour changes in the same commits.
- [x] New decisions recorded as ADRs — no new architectural decision; existing ADRs' Consequences formatting fixed
  (E10), consistent with ADR 0014's own house style.

### Security & operability
- [x] Inputs validated with shared schemas; no secrets or stack traces in responses — the two 500-causing gaps
  (year-0000, NUL) are now caught by the shared Zod schema before reaching Postgres.
- [x] Images non-root; no dev dependencies in runtime images — unaffected; Scarf telemetry opt-out and build-date
  defaulting are build-time only, no new runtime dependency.

**Verdict: clean.** Both the Critical finding (lost updates after a background refetch) and the two Important
findings (year-0000/NUL 500s, PATCH 415 contract gap) are correctly fixed with TDD evidence and the exact
mechanism the final review called for; all eight deferred Minor items (F-19, F-21, F-27/F-42, F-29, F-32, F-43,
F-44, F-49) are addressed. This review's own independent pass over the diff found no new Critical or Important
issues. One already-known, deliberately parked quirk (duplicate 400 messages for a doubly-invalid due date) is
recorded in the findings log as Low/Accept rather than left undocumented. Approved to merge.
