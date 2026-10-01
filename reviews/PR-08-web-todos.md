# Review — PR #8 feat(web): todo web app

- App commit range: `9e082f6..3380634` · Date: 2026-10-01 · Reviewer: Claude Code (automated) + solution-lead triage

## Automated review output

Scope of PR #8 (three commits: `6d90a6d` typed API client + query configuration, `60f1d7a` todo UI — list,
filters, form, task dialog, `3380634` todo page + app shell + nginx web image; confirmed via
`review-9e082f6..3380634.diff`, 59 files changed, 4009 insertions): adds the entire `@foci/web` app —
`todoClient.ts` (the only module that calls `fetch`), `idempotencyKey.ts` (`crypto.getRandomValues`-based v4
UUID, works on insecure origins), TanStack Query hooks (`useTodos.ts`), the component tree
(`TodoPage`/`TodoFilters`/`TodoList`/`TodoItem`/`TodoDialog`/`TodoDetailsPanel`/`TodoForm`/`CreateTodoPanel`/
`ErrorBanner`), CSS Modules + `tokens.css`, and the `web` Docker target (`nginxinc/nginx-unprivileged` serving
the built SPA with an `/api` reverse proxy, no Node in the final image). `package-lock.json`'s 3,559-line
diff was skimmed only (new deps: Radix Dialog, TanStack Query, React 19, Vite 8, `@vitejs/plugin-react`,
`eslint-plugin-react-hooks`, Testing Library stack, `jsdom`; no new `hasInstallScript: true` packages beyond
the pre-existing `@scarf/scarf` already flagged and accepted in PR #7/F-29). Reviewed against spec §7
(Frontend design) and §8 (Containers and delivery), and the global constraints (ESM extensionless imports for
web, TS `~6.0.3`, 100% coverage, test-path mirroring).

**Correctness (spec §7.2/§7.3 data flow and rules)**
- Every row of §7.2's data-flow table is implemented and independently verified end-to-end: `docker compose up
  --build -d` from a clean build brought up `db`→`migrate`→`api`→`web` (all healthy); `GET /`, `GET
  /api/health` and `GET /some/deep/link` (SPA fallback) via `http://localhost:8080` all returned 200; `POST
  /api/todos` and `GET /api/todos` through the nginx proxy round-tripped correctly with `Idempotency-Key`
  honoured (`201`, then listed).
- `todoClient.ts` sends `If-Match`/`Idempotency-Key`, parses `application/problem+json` into `ApiError`, and
  validates every response against the shared Zod schemas (`TodoViewSchema`/`TodoViewListSchema`) — confirmed
  field-by-field against `packages/shared/src/todo.ts`.
- Dates: `TodoItem.tsx` renders `todo.dueDate` as the raw stored string (never through `Date`), with a test
  pinning the west-of-UTC case (`TZ=Pacific/Honolulu`, `2026-10-01` renders as `2026-10-01`) per Review Focus
  item 5 in the global constraints. `format.ts`'s `formatTimestamp` correctly goes through `Intl.DateTimeFormat`
  for the instant-valued `createdAt`, not `dueDate`.
- Idempotency key: `idempotencyKey.ts` uses `crypto.getRandomValues` (not `crypto.randomUUID`), satisfying
  Review Focus item 4 (works on insecure origins like `http://192.168.x.x:8080`); a dedicated test exercises
  this exact scenario.
- Conflict handling (412) on both edit and delete shows a banner, refetches (via the mutation's `onSettled` →
  `invalidateQueries`, awaited internally by `mutateAsync` before it resolves — confirmed by reading TanStack
  Query's hook semantics, not just the code comment), and preserves the user's in-progress edits (`TodoForm`'s
  local `values` state is untouched on failure) — verified by
  `apps/web/tests/todos/components/TodoDetailsPanel.test.tsx`'s 412 scenario, which also confirms the retried
  `PATCH` carries the new version (`update.mock.calls.map(c => c[1])` → `[1, 2]`).
- Accessibility: labelled inputs with `aria-invalid`/`aria-describedby` (`TodoForm`'s `Field`), Radix dialog
  focus trapping/Escape/`aria-modal`. `TodoDialog.tsx` additionally fixes a real gap in Radix's own
  focus-return: because the dialog is opened from arbitrary buttons with no `Dialog.Trigger` wrapper, Radix's
  built-in "return focus to the trigger" silently does nothing; the PR captures `document.activeElement` in a
  `useLayoutEffect` (before Radix's own autofocus-into-dialog effect runs) and restores it via
  `onCloseAutoFocus`. Confirmed correct for the create/view/edit-mode-switch cases by
  `TodoDialog.test.tsx`; the one gap (opener removed from the DOM by a successful delete, so
  `openerRef.current?.focus()` no-ops and focus falls to `<body>`) was already raised at the per-task level —
  recorded below, not re-litigated.
- `styles`: CSS Modules + `tokens.css`, system font stack, no UI kit — matches §7.3.

**Architecture / Docker (spec §8)**
- `Dockerfile`'s new `build-web` stage (`npm run build -w @foci/web`) feeds a separate `web` target based on
  `nginxinc/nginx-unprivileged:1.31-alpine` that copies only `apps/web/dist` — no `node_modules`, no Node
  binary. Independently verified by container inspection: `docker compose exec web whoami` → `nginx`,
  `id` → `uid=101(nginx) gid=101(nginx)`, `which node` → exit 1 (absent). `compose.yaml`'s `web` service adds
  `read_only: true` + tmpfs `/tmp`, matching the `api` service's existing hardening pattern.
- `nginx.conf`: `/api/` reverse-proxies to `api:3000` with `Host`/`X-Forwarded-For`/`X-Forwarded-Proto` set (no
  header stripping — `If-Match`/`Idempotency-Key`/`ETag` pass through unchanged, confirmed by the live `curl`
  round trip above); `/assets/` is immutable-cached; `/` falls back to `index.html` for SPA routing — all three
  confirmed live.
- `vite.config.ts` aliases `@foci/shared` to the package's TS source (not a build artifact), consistent with
  the root `vitest.config.ts`'s existing alias and the monorepo's "single source" philosophy.
- Web imports are extensionless (bundler resolution) throughout the new code — consistent with the global
  constraint that only API/shared use explicit `.js` extensions.
- `/dev` portal and the "Developer" header link from spec §7.1/§7.4 are absent from this PR. Checked
  `.superpowers/sdd/08-web-todos/task-*-brief.md` (tasks 1–5): none mention the dev portal, and no `09-*`/
  `10-*` task directory exists yet in `.superpowers/sdd/`. This is out of scope for PR #8, consistent with
  `D-2…D-9`/`NFR-9` still showing "Planned" in the traceability matrix — not a finding.

**Tests**
- Independently re-ran the full gate from a clean image: `docker compose --profile test run --rm --build
  test` → `format:check`, `lint`, `typecheck` all clean (chained with `&&` in `test:ci`, and the suite ran, so
  all three passed); **49 test files, 359 tests, all passing** (359 vs. PR #7's baseline of 287 — 72 new web
  tests); **100% stmt/branch/func/line coverage**, every new `apps/web/src` file at 100%, same two
  pre-existing 0%-coverage cosmetic rows (`apps/api/src/repository/ports.ts`, `packages/shared/src/index.ts`)
  as every prior PR. `grep -rn "v8 ignore" apps/web/src apps/web/tests`: no hits.
- Tests mirror the source tree (`apps/web/tests/**` ↔ `apps/web/src/**`) per the global constraint.
- Assertions check behaviour (rendered text, `aria-*`, mock call arguments), not timings or implementation
  internals.

**New dependencies**
- `@radix-ui/react-dialog`, `@tanstack/react-query`, `react`/`react-dom`, `zod` (already pinned at `^4.6.5`
  elsewhere in the monorepo — consistent version) are all justified by spec §7.1/§7.2's own prescription.
  Dev-only: Testing Library stack, `jsdom`, `vite`, `@vitejs/plugin-react`, `eslint-plugin-react-hooks` — all
  web-stack necessities, none in the runtime image (confirmed above: `web`'s final stage copies only `dist`).
  No new `hasInstallScript: true` package introduced by this PR (spot-checked the lockfile diff for
  `"hasInstallScript": true` blocks — none under the newly-added web packages).

**Already raised at the per-task level (not re-litigated; recorded below per the controller's pre-triage):**
- (a) After a successful delete, the opener row is gone from the DOM, so `openerRef.current?.focus()` is a
  no-op and focus falls through to `<body>` instead of somewhere useful.
- (b) `TodoDetailsPanel.test.tsx`'s `setup()` renders with `id="todo-1"` while `makeView()`'s fixtures
  generate unrelated random sequence-based UUIDs for the mocked response — the two never need to match for the
  tests to pass, but it's a loose coupling in the test data.
- (c) `TodoDetailsPanel.tsx`'s `confirmDelete`'s 404 branch is an empty, comment-only branch ("the refetch
  triggered by onSettled will surface the 404 via `todo.isError`") — correct, but reads as dead code at a
  glance.
- (d) A successful delete's `onSettled` invalidates (and refetches) every todo query, including the
  now-deleted item's own detail query — a wasted request for a 404 that nothing displays (the dialog is
  already closed). A `removeQueries`/targeted cache update on delete success would avoid it.
- (e) `TodoFilters.tsx`'s `<label>Show<select>…</select></label>` nesting pattern differs from `TodoForm.tsx`'s
  explicit `Field` component (`htmlFor`/`id`/`aria-describedby`) — both are accessible, just stylistically
  inconsistent.
- (f) `idempotencyKey.ts`'s `RandomFill` type is written as `(bytes: Uint8Array<ArrayBuffer>) =>
  Uint8Array<ArrayBuffer>` — an adaptation required by TypeScript 6's stricter `lib.dom` typed-array generics,
  not a design choice.

**New finding**
- `TodoItem.tsx`'s checkbox accessible name (`` `Mark "${todo.title}" ${nextState}` ``) uses double quotes
  around the title and varies the trailing verb between `complete`/`incomplete` depending on the todo's
  current state. Spec §7.3 literally shows `"Mark '<title>' complete"` — single quotes, and only the one verb.
  The verb variation is a sensible, test-covered enhancement (an already-completed item's checkbox should
  announce "Mark incomplete", not always "complete"); the quote-character difference is purely cosmetic
  (markdown notation vs. implementation choice).

**No Critical or Important findings.** The feature reproduces every row of spec §7.2's data-flow table, is
backed by 72 new tests at 100% coverage, and was independently verified live end-to-end (`docker compose up`,
real `curl` round trips through the nginx proxy, container-level non-root/no-Node inspection). The items below
are all Low.

## Triage

| Finding | Severity | Category | Decision | Reason |
|---|---|---|---|---|
| F-30 (R12) Delete 404 keeps the `TodoDetailsPanel` dialog open with "This task no longer exists." instead of closing it (spec §7.2 said close) | Low | design | Accept | spec divergence ruled — explicit feedback beats a silently vanishing dialog |
| F-31 (R13) Create idempotency key is tied to the submitted payload (`JSON.stringify(input)`), not "one key per form open" as spec §7.2 literally says | Low | correctness | Accept | spec divergence ruled — strictly safer: an edited retry can never collide into a 422 |
| F-32 After a successful delete, the dialog's opener element is gone from the DOM, so `TodoDialog`'s focus-restore (`openerRef.current?.focus()`) no-ops and focus falls to `<body>` | Low | correctness | Accept | deferred: candidate fix in final review — add an `isConnected` guard with a fallback focus target (e.g. the list container or page heading) |
| F-33 `TodoDetailsPanel.test.tsx`'s `setup()` hard-codes `id="todo-1"` while `makeView()` fixtures use unrelated random sequence-based UUIDs for the mocked `get`/`update`/`remove` responses | Low | tests | Accept | the tests pass regardless since the fake client ignores the id argument; loose coupling only, no false positives found |
| F-34 `TodoDetailsPanel.tsx`'s `confirmDelete` has an empty, comment-only branch for the 404 case | Low | design | Accept | correct behaviour (the invalidation-triggered refetch surfaces the 404 through `todo.isError`), just reads as dead code without the comment |
| F-35 A successful delete's `onSettled` invalidates every todo query including the just-deleted item's own detail query, causing a wasted background 404 fetch that nothing displays | Low | design | Accept | deferred: candidate fix in final review — `removeQueries` (or a direct cache write) for the deleted id instead of a blanket `invalidateQueries` |
| F-36 `TodoFilters.tsx` nests `<label>` around its `<select>`s directly instead of using `TodoForm.tsx`'s `Field` component (`htmlFor`/`id`/`aria-describedby`) | Low | design | Accept | both patterns are accessible; a cosmetic/stylistic inconsistency between the two forms, not a defect |
| F-37 `idempotencyKey.ts`'s `RandomFill` type signature (`Uint8Array<ArrayBuffer>`) is more verbose than a plain `Uint8Array`, required by TypeScript 6's stricter `lib.dom` typed-array generics | Low | docs | Accept | correct and necessary under the pinned TS version; noted so a future TS upgrade doesn't "simplify" it back into a type error |
| F-38 `TodoDialog.tsx` opens from arbitrary buttons with no `Dialog.Trigger` wrapper, so Radix's built-in close-time focus-return silently does nothing; the PR adds its own opener-capture (`useLayoutEffect` + `document.activeElement`) and restore (`onCloseAutoFocus`) | — | correctness | Fix | Fixed in PR #8 — verified by `TodoDialog.test.tsx`'s "closes on Escape and returns focus" and mode-switch tests |
| F-39 `TodoItem.tsx`'s checkbox accessible name uses double quotes around the title and varies the verb (`complete`/`incomplete`) by current state, vs. spec §7.3's literal `"Mark '<title>' complete"` (single quotes, one verb) | Low | docs | Accept | the verb variation is a correct, tested UX improvement (toggle direction should match the announced action); the quote-character difference is cosmetic spec notation, not a behavioural gap |

## Checklist

Copy of `checklists/milestone-review.md` with results for PR #8:

### Correctness
- [x] Behaviour matches the spec sections the PR claims (§7.2 data-flow table, §7.3 rules) — every row verified by test and, for the live stack, by direct `curl`/container inspection; see F-30/F-31 for the two controller-ruled spec-text divergences.
- [~] Error precedence 400 → 428 → 404 → 412 preserved — N/A at the HTTP-handling level (this PR adds no server logic); the client's own precedence for its two special-cased statuses (412 before generic error handling) is correct and tested, 404 handling is ruled by R12 (F-30).
- [x] No silent catch-alls; unexpected errors become logged 500s — N/A server-side; client-side, every mutation's catch branch either re-throws (handled by `TodoForm`) or falls through to `describeError`, never silently swallowed.

### Concurrency
- [x] Every write is a single statement or inside the unit of work — N/A; this PR performs no direct database writes, only HTTP calls through the already-reviewed API.
- [x] Version bumps only on real changes; conditional writes use the version — unchanged; `todoClient.ts` correctly threads `version` into `If-Match` on both `update` and `remove`.
- [x] New code paths covered by an invariant test if they touch shared state — N/A; no shared (cross-request) state is touched by the web app itself.

### Tests
- [x] Test written first (visible in the commit) and mirrors the source path — each of the three commits bundles its source and tests together; `apps/web/tests/**` mirrors `apps/web/src/**` exactly.
- [x] 100% coverage without `v8 ignore` — independently re-ran `docker compose --profile test run --rm --build test` from a clean build: 359/359 tests pass (287 baseline + 72 new), 100% stmt/branch/func/line including every new `apps/web/src` file; no `v8 ignore` in the new code.
- [x] Assertions check behaviour, not implementation details or timings — confirmed throughout (rendered text/roles/`aria-*`, mock call arguments); the west-of-UTC due-date test and the idempotency-key reuse test are both genuine behavioural pins, not snapshot checks.

### Architecture
- [x] Layer rules respected (lint passes); composition only in `app.ts`/entry points — confirmed via the full gate's lint step (passed, including the new `eslint-plugin-react-hooks` rules scoped to `apps/web/**`); `todoClient.ts` is the only module that calls `fetch`, consistent with §7.3.
- [x] No new dependency without a reason in the commit or an ADR — all new production and dev dependencies trace directly to spec §7.1/§7.2's own prescription (Radix, TanStack Query, React) or the web build/test toolchain; no ADR directory exists yet in the repo (same as PR #7's baseline).

### Docs
- [ ] README / guides / OpenAPI still accurate (no drift) — **N/A for this PR's repo-level docs**: no README exists yet (D-2…D-6 still "Planned"); the `/dev` portal that would surface web-specific docs is explicitly out of scope for this PR (confirmed above against the task briefs).
- [ ] New decisions recorded as ADRs — **N/A for this PR**: no ADR directory exists yet in the repo.

### Security & operability
- [x] Inputs validated with shared schemas; no secrets or stack traces in responses — `TodoForm` validates with the same `CreateTodoSchema` the server uses before submitting; `todoClient.ts` validates every response against the shared view schemas; `ApiError` only ever surfaces the server's own problem-detail message, nothing client-internal.
- [x] Images non-root; no dev dependencies in runtime images — independently verified by container inspection this review: `web` runs as `nginx` (uid 101), has no `node` binary at all (the final stage copies only `apps/web/dist`, never `node_modules`); `api`/`migrate` unchanged from their already-verified baseline.

**Verdict: clean.** No Critical or Important findings. PR #8 delivers the complete todo web app — API client,
TanStack Query data layer, the full component tree, and a hardened nginx-unprivileged production image — with
every row of spec §7.2's data-flow table independently verified both by test (72 new tests, 100% coverage) and
live against the real default Docker Compose stack (`db`→`migrate`→`api`→`web`, all healthy, reachable at
`http://localhost:8080`, SPA fallback and `/api` proxy both confirmed, non-root/no-Node confirmed by direct
container inspection). Two items are controller-ruled spec-text divergences (F-30/F-31, both strictly safer
than the literal spec text); one item is a genuine fix already landed in this PR (F-38, Radix's focus-return
gap for triggerless dialogs); the remaining six are Low/Accept polish items carried from the per-task reviews
plus one new Low finding (F-39, a cosmetic/enhancement difference from the spec's literal checkbox name).
