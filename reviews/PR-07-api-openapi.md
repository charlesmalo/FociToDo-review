# Review — PR #7 feat(api): OpenAPI contract and API explorer

- App commit range: `59f4d46..26eb690` · Date: 2026-10-01 · Reviewer: Claude Code (automated) + solution-lead triage

## Automated review output

Scope of PR #7 (two commits, `1870f38` + `26eb690`; confirmed via `review-59f4d46..26eb690.diff` and
`git show --stat` on each commit): generates an OpenAPI 3.1 document from the shared Zod schemas
(`apps/api/src/http/openapi.ts`, 214 lines, new), commits the generated output
(`apps/api/openapi.json`, 756 lines, new), and serves both the document and a Swagger UI explorer
(`apps/api/src/http/docsRoutes.ts`, new; wired into `createHttpApp.ts`). Adds `swagger-ui-express` (prod
dependency) and `@types/swagger-ui-express` (dev). New tests: `openapi.test.ts` (unit, 5 tests),
`openapi.int.test.ts` (integration against real HTTP+Postgres, 3 tests), `docsRoutes.test.ts` (2 tests).
Reviewed against spec §5.5 (HTTP API table, now including `GET /api/openapi.json` / `GET /api/docs`),
§5.6 ("OpenAPI generated from the shared Zod schemas with `z.toJSONSchema` ... plus hand-written route
metadata; tests assert every route is registered, responses conform, and the committed `openapi.json`
matches the generated output"), and §14 A1 (native `z.toJSONSchema` over `zod-to-openapi`, confirmed used).

**Correctness**
- `toSchema()` (`apps/api/src/http/openapi.ts:890-894`) wraps `z.toJSONSchema(schema, { io })` and strips
  `$schema`, exactly matching §5.6's prescription (input side for requests, output side for responses).
  Verified for every schema used: `CreateTodoSchema`/`UpdateTodoSchema` (input), `TodoViewSchema`/
  `ProblemSchema` (output) — cross-checked field-by-field against `packages/shared/src/todo.ts`,
  `headers.ts`, `problem.ts`, `listQuery.ts`; every constraint (title 1–200, description ≤2000 nullable,
  date-only `dueDate`, `If-Match` regex `^"[1-9]\d{0,8}"$`, `Idempotency-Key` regex, strict-object
  `additionalProperties: false`) is faithfully reproduced in the committed `openapi.json`.
- `HEALTH_SCHEMA` is the one hand-written (non-Zod-derived) schema — checked against `HealthService`'s
  `HealthReport` type (`status: 'ok'|'degraded'`, `db: 'up'|'down'`, `schemaVersion: string|null`): exact
  match, no drift.
- `openapi.test.ts`'s `'documents exactly the routes Express serves'` test walks the live Express router
  stacks (`createTodoRouter`, `createHealthRouter`) and asserts the documented path set is identical —
  this is a real route/doc parity check, not just a snapshot.
- `openapi.test.ts`'s `'matches the committed openapi.json'` test does a byte-for-byte comparison against
  the checked-in file (only writing when `UPDATE_OPENAPI=1`); independently re-ran the full gate (below)
  and confirmed this test passes against the actual committed file — no drift between generator and
  artifact.
- `openapi.int.test.ts` drives the real running app (`createRuntime` + real Postgres) through every
  operation's happy path and several error paths, asserting the observed status is in the operation's
  documented `responses` set and, for 4xx/5xx, that the body is `application/problem+json` and parses as
  `ProblemSchema`. This is a genuine conformance test, not just a schema-shape check.
- `GET /api/openapi.json` and `GET /api/docs` now match §5.5's table rows exactly (previously-amended
  spec rows); `docsRoutes.test.ts` confirms the JSON endpoint echoes the document and Swagger UI serves
  (`response.text` contains `swagger-ui`).

**Architecture**
- `openapi.ts` and `docsRoutes.ts` live in `apps/api/src/http`, the correct layer (HTTP-layer composition
  only touches `createHttpApp.ts`, consistent with the layer-dependency rule); `openapi.ts` imports only
  from `@foci/shared` and `zod`, no reach into `service`/`repository`.
- `swagger-ui-express` is a production dependency (correctly, since `/api/docs` is a live route per
  spec, not a dev-only tool) and ships in the prod image via `npm ci --omit=dev`; `@types/swagger-ui-express`
  is dev-only. Consistent with the Dockerfile's existing multi-stage/non-root pattern — not independently
  re-verified by container inspection this PR (no `src` runtime-behaviour change beyond routing), but the
  dependency placement in `package.json`/`package-lock.json` is correct.

**Tests**
- Independently re-ran the full gate from a clean image: `docker compose --profile test run --rm --build
  test` → `format:check`, `lint`, `typecheck` all clean; **32 test files, 287 tests, all passing** (277
  from PR #6's baseline + 10 new: 5 `openapi.test.ts` + 3 `openapi.int.test.ts` + 2 `docsRoutes.test.ts`);
  **100% stmt/branch/func/line coverage**, including the two new source files (`openapi.ts`,
  `docsRoutes.ts`) at 100%, same two pre-existing 0%-coverage cosmetic rows (`repository/ports.ts`,
  `shared/index.ts`) as every prior PR. `grep -rn "v8 ignore"` across the new files: no hits.
- `package-lock.json`'s 44-line diff spot-checked: adds `swagger-ui-express@5.0.1`, its transitive
  `swagger-ui-dist@5.33.0`, `@types/swagger-ui-express@4.1.8`, and `swagger-ui-dist`'s own dependency
  `@scarf/scarf@1.4.0` — flagged below (F-29).
- `apps/api/openapi.json`'s 756-line diff spot-checked against `openapi.ts`'s `buildOpenApiDocument()`
  (structurally identical path-by-path, component-by-component) and confirmed programmatically identical
  by the independently-re-run `'matches the committed openapi.json'` test.

**Already raised at the per-task level (not re-litigated; recorded below from pre-merge triage):**
- (a) `PATCH /todos/:id` can return 415 via the global JSON body parser (unsupported charset) but neither
  spec §5.5 nor `openapi.json` documents 415 for PATCH — only for POST (which this PR newly added 415 to).
  Same underlying gap as POST had before this PR; PATCH's is unaddressed.
- (b) `openapi.int.test.ts`'s error-path test exercises only 400 and 404 across both operations tested;
  it doesn't drive 412 (stale If-Match), 413 (oversized body), 415 (bad charset), 422 (idempotency-key
  reuse), 428 (missing If-Match), or the health 503 path, even though all are documented responses.

**New finding**
- `swagger-ui-dist` (transitively pulled in by `swagger-ui-express`, now a production dependency) itself
  depends on `@scarf/scarf@1.4.0`, which carries `hasInstallScript: true` — Scarf's postinstall pings
  `scarf.sh` for install analytics. The Dockerfile's `npm ci` steps do not pass `--ignore-scripts`, so
  this script runs during every image build, including the prod `api`/`migrate` stages. Scarf is
  widely-used, opt-out-able (`SCARF_ANALYTICS=false`/npm config), and is designed not to fail the install
  on network failure — but it is a new, unreviewed outbound network call introduced by a transitive
  dependency, with no ADR, which could be relevant in a firewalled CI/build environment.

**No Critical or Important findings.** The feature is a pure, additive generation + serving layer with no
changes to existing request/response behaviour; the generated contract was checked field-by-field against
the shared Zod schemas and matches the real routes and real HTTP responses by direct, independently-re-run
test evidence. The three items below are Low.

## Triage

| Finding | Severity | Category | Decision | Reason |
|---|---|---|---|---|
| F-27 PATCH can return 415 via the global JSON parser but neither spec §5.5 nor `openapi.json` documents it on PATCH (POST gained a 415 doc entry this PR; PATCH did not) | Low | docs | Accept | deferred: candidate fix in final review (document 415 on PATCH) |
| F-28 `openapi.int.test.ts`'s error-path conformance test doesn't exercise every documented status (412/413/415/422/428, health 503) — only 400/404 | Low | tests | Accept | Coverage gap in the conformance suite, not a behavioural defect; the individual status codes are each independently proven correct by `todoRoutes.int.test.ts` and `todoRoutes.concurrency.test.ts` from earlier PRs — this suite's value is the cross-check against the documented contract, which it does perform for the statuses it hits. |
| F-29 `swagger-ui-dist` (new transitive prod dependency via `swagger-ui-express`) depends on `@scarf/scarf`, which runs a network-calling postinstall script (`hasInstallScript: true`) during every `npm ci`, including the Docker build, with no `--ignore-scripts` and no ADR | Low | security | Accept | Scarf is a well-known, widely-shipped install-analytics package that fails open (does not block installs without network access); the independently re-run `docker compose --profile test run --rm --build test` completed cleanly. Worth a one-line note in a future ADR or Dockerfile `--ignore-scripts` hardening pass, not a blocker for this PR. |

## Checklist

Copy of `checklists/milestone-review.md` with results for PR #7:

### Correctness
- [x] Behaviour matches the spec sections the PR claims (status codes, headers, validation messages) — `openapi.json` checked field-by-field against `packages/shared` schemas and the real routes; `openapi.int.test.ts` independently confirms real responses conform to the documented contract.
- [x] Error precedence 400 → 428 → 404 → 412 preserved — unchanged; no request-handling logic touched by this PR (pure documentation/serving addition).
- [x] No silent catch-alls; unexpected errors become logged 500s — unchanged; no new error paths.

### Concurrency
- [x] Every write is a single statement or inside the unit of work — N/A; this PR performs no writes.
- [x] Version bumps only on real changes; conditional writes use the version — unchanged.
- [x] New code paths covered by an invariant test if they touch shared state — N/A; `openapi.ts`/`docsRoutes.ts` touch no shared state (pure, stateless document generation and static serving).

### Tests
- [~] Test written first (visible in the commit) and mirrors the source path — each of the two commits bundles its source and tests together (`1870f38`: `openapi.ts` + `openapi.json` + `openapi.test.ts`; `26eb690`: `docsRoutes.ts` + `docsRoutes.test.ts` + `openapi.int.test.ts`), consistent with this repo's established per-PR granularity (not strict red/green, as in prior PRs).
- [x] 100% coverage without `v8 ignore` — independently re-ran `docker compose --profile test run --rm --build test` from a clean build: 287/287 tests pass (277 baseline + 10 new), 100% stmt/branch/func/line including both new files, same two pre-existing cosmetic 0% rows as every prior PR; no `v8 ignore` in the new files.
- [~] Assertions check behaviour, not implementation details or timings — true overall; F-28 (above) notes the error-path conformance test's coverage of documented statuses is partial (400/404 only), not that any assertion is a false positive.

### Architecture
- [x] Layer rules respected (lint passes); composition only in `app.ts`/`createHttpApp.ts` — confirmed via the full gate's lint step (passed); new files live in `apps/api/src/http`, wired only from `createHttpApp.ts`.
- [~] No new dependency without a reason in the commit or an ADR — `swagger-ui-express` is justified by the PR's own purpose (API explorer) and commit message; its transitive `@scarf/scarf` install-script dependency (F-29) was not called out, though it's a sub-dependency of a sub-dependency, not a direct choice.

### Docs
- [ ] README / guides / OpenAPI still accurate (no drift) — **N/A for this PR's repo-level docs**: no README or `docs/api.md` exist yet (D-2…D-6, NFR-9 are still "Planned" per the traceability matrix) — this PR *is* the OpenAPI/API-explorer feature itself, and its own self-consistency is verified above (generated vs. committed `openapi.json`, and vs. real routes/responses).
- [ ] New decisions recorded as ADRs — **N/A for this PR**: no ADR directory exists yet in the repo; A1 (native `z.toJSONSchema` over `zod-to-openapi`) was already recorded in the spec's own §14 amendments table before this PR.

### Security & operability
- [~] Inputs validated with shared schemas; no secrets or stack traces in responses — unchanged; the explorer only reads the already-generated document, no new input surface. F-29 (above) flags a new transitive install-time network call, Low/Accept.
- [x] Images non-root; no dev dependencies in runtime images — `swagger-ui-express` correctly placed in `dependencies` (ships in the prod image, since `/api/docs` is a live production route per spec), `@types/swagger-ui-express` correctly in `devDependencies` only; not independently re-verified by container inspection this PR (no non-root/image-layering change was made — unchanged from PR #5's verified baseline).

**Verdict: clean.** No Critical or Important findings. This PR adds a self-consistent, test-verified OpenAPI
3.1 contract generated from the same Zod schemas the API validates with, plus a Swagger UI explorer, exactly
per spec §5.5/§5.6/§14 A1. Three Low items are accepted: two carried forward from the per-task review (PATCH's
undocumented 415, and the error-path conformance test's partial status coverage), and one new item (a
transitive install-script dependency pulled in by `swagger-ui-dist`, low-risk and fails open). Full gate
independently re-run from a clean Docker build: 287/287 tests passing, 100% coverage including both new
source files, lint/typecheck/format clean.
