# Review — PR #9 test: end-to-end journeys and full CI

- App commit range: `18c6664..b1ee031` · Date: 2026-10-01 · Reviewer: Claude Code (automated) + solution-lead triage

## Automated review output

Scope of PR #9 (two commits: `8c716dd` Playwright e2e project + isolated Compose overlay, `b1ee031` CI wiring
for the e2e job and a runtime-image build job; confirmed via `review-18c6664..b1ee031.diff`, 11 files changed,
292 insertions/2 deletions): adds the `e2e` Dockerfile target (official `mcr.microsoft.com/playwright:v1.63.0-noble`
image + pinned `@playwright/test@1.63.0`), `compose.e2e.yaml` (isolated `foci-e2e` project overlay, `web`'s host
port reset to none, `e2e` service depending on `web` healthy), two spec files (`e2e/todos.spec.ts`,
`e2e/api.spec.ts`, 8 journeys total), `scripts/check-playwright-pin.mjs` (fails the gate on any
package.json/image/install-string version drift), `e2e/playwright.config.ts`/`tsconfig.json`/`support.ts`, and
three new/updated `.github/workflows/ci.yml` jobs (`test`, `e2e` needs `test`, `images`). No `apps/*/src` files
are touched by this PR. Reviewed against spec §8.1–8.4 (Dockerfile `e2e` target, Compose overlay, reviewer
commands, CI), §9.1 (end-to-end test layer), and §14 A9/A11 (override-file e2e invocation, Compose v2.24+
prerequisite for `!reset`).

**Correctness / infra (spec §8.1–8.4, A9/A11)**
- `Dockerfile`'s `e2e` target matches spec §8.1's table exactly: built from the Playwright image, only
  `@playwright/test@1.63.0` installed plus `e2e/` copied in, no app source. `compose.e2e.yaml` matches §8.2's
  `e2e` row verbatim (`overlay compose.e2e.yaml`; target `e2e`; `BASE_URL=http://web:8080`; bind mount
  `./reports`; removes `web`'s host port) and A9/A11 (`ports: !reset []`, the Compose v2.24+ `!reset` merge
  operator, `docker compose run` rather than `up --exit-code-from`).
- `.github/workflows/ci.yml`'s three jobs (`test`, `e2e` with `needs: test`, `images`) match spec §8.4's
  pipeline description exactly, including uploading `reports/e2e`/`reports/e2e-results` as an artifact and
  tearing the isolated project down with `-v` in an `if: always()` step (confirmed this leaves no residue: the
  job's own teardown step ran and succeeded in the real CI run below).
- Independently re-ran PR #9's actual CI run on GitHub Actions (not just the implementer's local run):
  `gh pr checks 9` → all three jobs green (`Lint, typecheck and tests (100% coverage)` 1m2s, `Build runtime
  images` 26s, `End-to-end (Playwright)` 1m25s, confirmed via `gh run watch 36858794834`). This is real,
  independent confirmation that the e2e suite passes against a stack built fresh by GitHub's own runner, not
  just the implementer's machine.
- Spot-checked every string the new e2e specs assert against the actual source they exercise, rather than
  trusting the implementer's report: `TodoDialog.tsx`'s `TITLES` map (`'New task'`/`'Task details'`/`'Edit
  task'`), `TodoDetailsPanel.tsx:54`/`:69`'s exact conflict-banner copy (`'...changed elsewhere and has been
  reloaded...'`), `TodoItem.tsx`'s `Mark "${todo.title}" ${nextState}` checkbox label, `TodoPage.tsx`'s `+ New
  task` button text, `packages/shared/src/todo.ts`'s `'Title is required'` message, and
  `createHttpApp.ts`'s route mounting (`app.use('/api', createDocsRouter(...))` on a router registered at
  `/docs` — confirming `e2e/api.spec.ts`'s `GET /api/docs/` assertion is correctly derived, not guessed). All
  matched exactly.
- The pin-check script (`scripts/check-playwright-pin.mjs`) correctly cross-references three independent
  sources of the Playwright version (root `package.json`, the Dockerfile's base-image tag, the Dockerfile's
  `npm install` version string) and fails loudly on drift; confirmed its regex extraction against the actual
  `Dockerfile` text — correct for the current single-line `FROM .../playwright:v1.63.0-noble AS e2e` and
  `@playwright/test@1.63.0` install line.
- `e2e/todos.spec.ts`'s concurrent-edit journey (`a concurrent edit shows a conflict notice and keeps my
  edits`) drives a real 412 end-to-end: it opens the edit dialog in the browser, then races a direct
  `request.patch` with a stale `If-Match: "1"` against the just-created todo, confirming the UI's conflict
  banner and edit-preservation behaviour (already unit/component-tested in PR #8) also holds through the real
  nginx→API→Postgres stack — this is new, genuine end-to-end coverage of FR-4's 412 path, not a restatement of
  PR #8's component tests.
- Fail-proof evidence (task-1-report.md, Step 6) is real and convincing: a one-line change to the conflict
  banner's copy in `apps/web/src` was reverted after reproducing exactly one targeted journey failure (with a
  trace/video artifact produced) while the other seven stayed green, then the revert was confirmed by an empty
  `git diff apps/web/src` — demonstrates the suite is neither vacuous nor coupled across journeys.
- Lockfile diff reviewed in full (46 lines): only `@playwright/test@1.63.0`, `playwright@1.63.0`, and
  `playwright-core@1.63.0` added, all exact pins, no new `hasInstallScript: true` package (the three existing
  `hasInstallScript` entries in the full lockfile — `@scarf/scarf`, `fsevents`, `unrs-resolver` — all predate
  this PR and are already covered by F-29).

**Tests**
- No `apps/*/src` or `apps/*/tests` files are touched — this PR is additive-only (new e2e layer + CI), so the
  existing 100% coverage gate and 359-test baseline are unaffected and were independently reconfirmed green by
  the real CI `test` job above.
- `grep -rn "v8 ignore" e2e scripts`: no hits. Coverage policy correctly excludes Playwright from the vitest
  coverage gate per spec §9.3 ("Playwright is not counted") — nothing in this PR works around that.
- Assertions throughout both spec files check behaviour (status codes, header values, role/text/aria content),
  never timing or implementation internals; no arbitrary `page.waitForTimeout`-style sleeps anywhere in the new
  files.

**Architecture / CI**
- `images` job builds `migrate`, `api`, `web` with no `needs: test` (runs in parallel with `test`, confirmed by
  the real run: `images` finished in 26s while `test` took 1m2s) — spec §8.4 lists it as step 3 but only states
  `e2e` explicitly needs `test`; running `images` in parallel is a reasonable, non-conflicting reading and
  shortens the pipeline, not a finding.
- `e2e/tsconfig.json` extends the root `tsconfig.base.json` and is wired into `typecheck` via a separate `tsc
  -p e2e/tsconfig.json` invocation (not a workspace), matching the brief; confirmed it is reachable inside the
  `test` Docker image because `source` (`COPY . .`) includes `e2e/` (not `.dockerignore`d) before `test` is
  built `FROM source`.
- No app runtime image (`api`/`migrate`/`web`) is touched by this PR; the new `e2e` target is explicitly a
  test-only tool per spec §8.1, so NFR-8's non-root/no-dev-deps constraint (scoped to production runtime
  images) does not apply to it — consistent with the matrix's existing treatment of the `e2e` image.

**Already raised at the per-task level (not re-litigated, recorded below per the controller's pre-triage):**
- (a) The `e2e` Docker stage installs `@playwright/test` with `npm install` rather than `npm ci` from a
  lockfile (plan-mandated per spec A5 — "no host `node_modules`" — since the `e2e` target has no workspace
  lockfile of its own); mitigated by the exact `--save-exact` pin plus `check-playwright-pin.mjs` catching any
  drift between the pinned version, the base image tag and the installed version.
- (b) Two of the four `e2e/todos.spec.ts` journeys (`a concurrent edit...`, `tasks persist across a reload`)
  scope their `Title`/`Save` locators to the relevant dialog (`editDialog`/`dialog`) to resolve a genuine
  Playwright strict-mode ambiguity: the "Sort by" `<select>`'s browser-computed accessible name concatenates
  its option text, which happens to contain the substring `"Title"`, so an unscoped page-level
  `getByLabel('Title')` matches two elements. This is correct, spec-compliant UI accessibility behaviour, not a
  defect — confirmed against `TodoFilters.tsx`'s source.

**No new findings beyond the two above.** No Critical or Important issues found.

## Triage

| Finding | Severity | Category | Decision | Reason |
|---|---|---|---|---|
| F-40 The `e2e` Docker stage installs `@playwright/test` with `npm install` instead of `npm ci` from a lockfile | Low | design | Accept | plan-mandated (spec A5, no host `node_modules`); exact pin + `check-playwright-pin.mjs` drift check mitigate |
| F-41 Two journeys (`a concurrent edit...`, `tasks persist across a reload`) scope `Title`/`Save` locators to the dialog to resolve a Playwright strict-mode ambiguity with the "Sort by" select's accessible name | Low | tests | Accept | documented adaptation; root-caused against `TodoFilters.tsx`, correct accessible-name behaviour, no app code changed to fit the test |

## Checklist

Copy of `checklists/milestone-review.md` with results for PR #9:

### Correctness
- [x] Behaviour matches the spec sections the PR claims (§8.1–8.4 Dockerfile/Compose/CI, A9/A11) — every row
  independently verified against source and against a real GitHub Actions run of PR #9's own CI (`test` 1m2s,
  `images` 26s, `e2e` 1m25s, all green).
- [~] Error precedence 400 → 428 → 404 → 412 preserved — N/A at the server level (no HTTP handler changes);
  the new concurrent-edit e2e journey newly proves the 412 path end-to-end through the real stack (genuine new
  coverage, not a restatement).
- [x] No silent catch-alls; unexpected errors become logged 500s — N/A; no new server or client error-handling
  code, only a test harness and CI config.

### Concurrency
- [x] Every write is a single statement or inside the unit of work — N/A; no write-path code changed.
- [x] Version bumps only on real changes; conditional writes use the version — unchanged; exercised, not
  modified, by the new concurrent-edit journey.
- [x] New code paths covered by an invariant test if they touch shared state — N/A; no shared-state code
  added.

### Tests
- [~] Test written first (visible in the commit) and mirrors the source path — N/A in the usual vitest-TDD
  sense (this is Playwright e2e against the full running stack); the equivalent discipline is present and
  verified: a RED run (`task-1-report.md`) showing genuine pre-fix selector failures, a GREEN run after the
  fix, and a dedicated fail-proof step (Step 6) that broke one source line, watched exactly one journey fail
  with a trace/video artifact, and confirmed a clean revert.
- [x] 100% coverage without `v8 ignore` — unaffected (no `apps/*/src` changes); independently reconfirmed via
  the real CI `test` job; Playwright is correctly excluded from the coverage gate per spec §9.3; `grep -rn "v8
  ignore" e2e scripts` — no hits.
- [x] Assertions check behaviour, not implementation details or timings — confirmed throughout both spec
  files (status codes, header values, role/text/aria content); no sleeps or timing-based waits.

### Architecture
- [x] Layer rules respected (lint passes); composition only in `app.ts` — confirmed via the real CI `test`
  job's lint step (passed); no app composition code touched.
- [x] No new dependency without a reason in the commit or an ADR — `@playwright/test@1.63.0` is justified by
  spec §8.1/§9.1's own prescription and the commit message; no new production dependency.

### Docs
- [ ] README / guides / OpenAPI still accurate (no drift) — **N/A for this PR**: no README exists yet
  (D-2…D-6 still "Planned"); CI now runs all three Docker commands spec §8.3 will document in the README
  (`test`, `e2e`, `images`), ahead of the README itself being written.
- [ ] New decisions recorded as ADRs — **N/A for this PR**: no ADR directory exists yet in the repo (same as
  every prior PR's baseline).

### Security & operability
- [x] Inputs validated with shared schemas; no secrets or stack traces in responses — N/A; no new
  input-handling code, only test specs calling the already-validated API.
- [x] Images non-root; no dev dependencies in runtime images — unaffected: `api`/`migrate`/`web` are unchanged
  by this PR (confirmed by the diff: only the Dockerfile's new `e2e` target was added); `e2e` is explicitly a
  test-only tool per spec §8.1, not a production runtime image, so the non-root/no-dev-deps constraint does not
  apply to it (consistent with the matrix's prior treatment of this image).

**Verdict: clean.** No Critical or Important findings. PR #9 adds the full end-to-end layer (8 Playwright
journeys covering the complete lifecycle, validation, 412 conflict handling, idempotency replay, and proxy
header passthrough) and wires all three CI jobs (`test`, `e2e`, `images`) exactly as spec §8.4 describes,
independently reconfirmed by re-running PR #9's actual GitHub Actions CI to green rather than trusting the
implementer's local run alone. The two items below are pre-existing, already-ruled per-task adaptations
(exact-pin `npm install` in the `e2e` image per plan; two dialog-scoped locators to resolve a genuine Playwright
strict-mode/accessible-name ambiguity), carried forward as Low/Accept, not re-litigated.
