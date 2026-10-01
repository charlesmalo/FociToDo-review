# Review — PR #10 docs: README, guides and decision records

- App commit range: `7a1583d..e6dbf16` · Date: 2026-10-01 · Reviewer: Claude Code (automated) + solution-lead triage

## Automated review output

Scope of PR #10 (three commits: `1c07751` architecture/API/concurrency/testing guides, `1e94578` 14 ADRs + index,
`e6dbf16` the README; confirmed via `review-7a1583d..e6dbf16.diff`, 21 files changed, 855 insertions, 0 deletions):
adds `README.md`, `docs/architecture.md`, `docs/api.md`, `docs/concurrency.md`, `docs/testing.md`,
`docs/decisions/0001`–`0014` plus `docs/decisions/README.md`, and `docs/images/screenshot.png`. No `apps/*/src`,
`packages/*/src` or CI files are touched — purely additive documentation. Reviewed against spec §10
(Documentation table and ADR list) and the take-home brief's README requirement (build/run, tests, design
rationale, assumptions, trade-offs).

**Correctness of the documentation itself (spot-checked against real source, not trusted on the implementer's
word)**
- `docs/api.md`'s endpoint table, error-precedence (`400 → 428 → 404 → 412`) and conventions match
  `apps/api/src/http/todoRoutes.ts` verbatim, including its own in-code comment ("Parsing happens before the
  service call... ahead of 428... 404 and 412"); `TodoService.ts:93`/`:108` confirm `PreconditionRequiredError`
  (428) is thrown before the repository's conditional write can produce 404/412.
- `docs/architecture.md`'s claims verified line-for-line against source: `createHttpApp.ts`'s JSON parser runs
  before routing (confirms R15's premise below); `eslint.config.js` layer zones match the "May import / Must not
  import" table; `compose.yaml:43,57` (`read_only: true` on `api`/`migrate`) confirms "API container is
  read-only"; `PgTodoRepository.ts:16` (`lower(title) COLLATE "C"`) and `compose.yaml:6`
  (`--builtin-locale=C.UTF-8`) confirm `docs/testing.md`'s "Known edges" sort note.
- `docs/concurrency.md`'s mechanism column cross-checked against `TodoService.ts:20`
  (`IDEMPOTENCY_TTL_MS = 24h`) and `PgIdempotencyStore.ts` (claim-first transaction) — matches.
- 14 ADRs (`docs/decisions/0001`–`0014`) match `docs/decisions/README.md`'s index exactly; every ADR's
  "Decision" paragraph matches the corresponding actual implementation already reviewed in PRs #1–#9 (e.g. 0004
  ETag/If-Match matches `apps/api/src/http/todoRoutes.ts`'s `parseIfMatch`, 0009 OpenAPI-from-Zod matches
  `apps/api/src/http/openapi.ts`'s `z.toJSONSchema` usage).
- `docs/images/screenshot.png` is a valid 1100×700 PNG (not a placeholder or corrupt file); every internal
  README/doc link (`docs/architecture.md`, `docs/api.md`, `docs/concurrency.md`, `docs/testing.md`,
  `docs/decisions/README.md`, `CLAUDE.md`, the screenshot) resolves to a real file.
- README's "Assumptions" (10 items) and "Trade-offs" (5 items) are consistent with spec §3 and with the
  matching ADRs' own "Consequences"/"Alternatives considered" sections — no contradictions found.
- Mermaid diagrams are present in every new file as spec §10 requires (context, deployment, layers, domain
  state, ER, frontend-flow, one sequence diagram per `docs/api.md` endpoint, three race-scenario diagrams in
  `docs/concurrency.md`, one test-topology diagram); most sit near the spec's "about 15 lines" guideline, a
  handful of the `docs/api.md` sequence diagrams run slightly longer (up to 21 lines) to show both the happy and
  error branches per spec §10's own instruction ("happy and error branches") — reasonable, not a finding.

**Already raised at the per-task level (not re-litigated, recorded below per the controller's pre-triage):**
- (R15) `docs/api.md`'s problem-types table lists `/problems/bad-request` (4xx) with "Other client errors from
  the JSON parser (e.g. 415 charset)" and the endpoint table lists 415 as a possible PATCH error; confirmed
  `apps/api/openapi.json` currently documents 415 only on `POST /api/todos`, not on `PATCH /api/todos/{id}` —
  true runtime behaviour is 415-capable on both (the JSON body parser in `createHttpApp.ts` runs before
  routing), so `docs/api.md` is accurate and `openapi.json` is the one behind; the contract fix (`openapi.ts` +
  regenerate + a PATCH charset test) is scheduled in the final fix wave.
- (R14, amended) No 304/If-None-Match row appears in `docs/api.md`'s conventions or problem tables — correct per
  the amended ruling that the API verifiably returns 200 for a matching `If-None-Match`, so there is nothing to
  document; not a gap.

**No new findings beyond R15 (recorded, not re-litigated).**

## Triage

| Finding | Severity | Category | Decision | Reason |
|---|---|---|---|---|
| F-42 `docs/api.md` documents 415 on PATCH (true behaviour: the JSON parser runs before routing) while `apps/api/openapi.json` does not yet | Low | docs | Accept | docs/contract drift, deferred to final fix wave (openapi.ts fix + regenerate + PATCH charset test); already ruled R15, not re-litigated |

## Checklist

Copy of `checklists/milestone-review.md` with results for PR #10:

### Correctness
- [x] Behaviour matches the spec sections the PR claims (status codes, headers, validation messages) — every
  claim in `docs/api.md`/`docs/architecture.md`/`docs/concurrency.md` independently cross-checked against the
  actual source (`todoRoutes.ts`, `TodoService.ts`, `createHttpApp.ts`, `PgTodoRepository.ts`, `compose.yaml`);
  all matched except the pre-ruled R15 openapi.json gap (F-42).
- [~] Error precedence 400 → 428 → 404 → 412 preserved — N/A for behaviour (no server code changed); the new
  `docs/api.md` documents the precedence correctly and matches `todoRoutes.ts`'s own in-code comment.
- [x] No silent catch-alls; unexpected errors become logged 500s — N/A; no new server code, only docs; the
  `/problems/internal` row in `docs/api.md` correctly states details are "logged, never returned."

### Concurrency
- [x] Every write is a single statement or inside the unit of work — N/A; no write-path code changed.
- [x] Version bumps only on real changes; conditional writes use the version — unchanged; `docs/concurrency.md`
  accurately documents the existing guarantees, cross-checked against `TodoService.ts`/`PgTodoRepository.ts`.
- [x] New code paths covered by an invariant test if they touch shared state — N/A; no shared-state code added.

### Tests
- [~] Test written first (visible in the commit) and mirrors the source path — N/A; this PR adds no test code
  (pure documentation), consistent with its scope.
- [x] 100% coverage without `v8 ignore` — unaffected (no `apps/*/src` changes); the coverage gate is unaffected
  by a docs-only PR.
- [x] Assertions check behaviour, not implementation details or timings — N/A; no new test assertions.

### Architecture
- [x] Layer rules respected (lint passes); composition only in `app.ts` — N/A; no app composition code touched;
  `docs/architecture.md`'s layer-rule table matches `eslint.config.js`'s actual `no-restricted-paths` zones.
- [x] No new dependency without a reason in the commit or an ADR — no new dependency in this PR; it is itself
  the source of 14 ADRs documenting prior decisions.

### Docs
- [x] README / guides / OpenAPI still accurate (no drift) — README, architecture, api, concurrency and testing
  guides all independently verified accurate against the real source (see spot-checks above); the one
  documented drift (openapi.json missing 415 on PATCH) is the already-ruled R15, tracked as F-42, deferred to
  the final fix wave.
- [x] New decisions recorded as ADRs — all 14 ADRs present, indexed in `docs/decisions/README.md`, each
  matching its already-implemented decision from PRs #1–#9; ADR 0011 (in-app `/dev` portal) correctly records a
  decision not yet built — `apps/web/src` has no `/dev` route and no `react-markdown`/`mermaid` dependency yet,
  and the traceability matrix's FR-10 is correctly left "Planned," so this is not a doc-accuracy gap.

### Security & operability
- [x] Inputs validated with shared schemas; no secrets or stack traces in responses — N/A; no new
  input-handling code, only documentation of existing behaviour.
- [x] Images non-root; no dev dependencies in runtime images — unaffected; no Dockerfile/compose changes in
  this PR.

**Verdict: clean.** PR #10 adds the full documentation set required by spec §10 and the take-home brief
(README with build/run, test instructions, design rationale for both backend architecture and testing strategy,
assumptions, and trade-offs; `docs/architecture.md`, `docs/api.md`, `docs/concurrency.md`, `docs/testing.md`;
14 ADRs). Every factual claim, file reference, code snippet and diagram was independently cross-checked against
the real source rather than trusted on the implementer's word, and all matched. The single recorded item
(F-42 / R15, docs/api.md vs. openapi.json 415-on-PATCH drift) was already ruled at the controller level and is
deferred to the final fix wave — no new Critical or Important findings.
