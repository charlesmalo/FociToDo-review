# Release sign-off — FociToDo @ de70329

**Recommendation:** Ready to submit

## Scope delivered vs requested

| Requirement | Delivered |
|---|---|
| Functional: add / list / view / update / complete / incomplete / delete a to-do, filter, sort, in-app developer docs (FR-1–FR-10) | All 10 Done — [traceability/matrix.md](traceability/matrix.md) |
| Data rules: id, title, description, dueDate, isCompleted, createdAt, version, isOverdue (DR-1–DR-8) | All 8 Done — [traceability/matrix.md](traceability/matrix.md) |
| Non-functional: Docker-only setup, TypeScript/Node 24, Postgres persistence, ports + two adapters, concurrency guarantees, strict validation + problem details, 100% coverage, lint-enforced layers, multi-stage/non-root/prod-only images, docs + Mermaid, OpenAPI from Zod (NFR-0–NFR-10) | All 11 Done — [traceability/matrix.md](traceability/matrix.md) |
| Delivery: public app repo, README (build/run/tests/design/assumptions/trade-offs), curated PR history, public review repo, CI running the README's own Docker commands (D-1–D-9) | All 9 Done — [traceability/matrix.md](traceability/matrix.md) |

All 38 traceability rows (FR/DR/NFR/D) read `Done`; none `In progress` or `Planned`.

## Quality snapshot

- Test gate: PASS, coverage 100/100/100/100 (statements/branches/functions/lines)
- End-to-end: 9/9 journeys
- Concurrency stress: 7/7 invariants hold across 5 scenarios (race-patch, parallel-complete, delete-storm, idempotent-replay, mixed-load); p95 list latency (`GET /todos` under mixed load) 10.48 ms
- Images: 0 HIGH/CRITICAL vulnerabilities (Trivy, both `api` and `web` images, `--ignore-unfixed`); 0 `npm audit --omit=dev --audit-level=high` findings. 3 Hadolint findings accepted as style-only (DL3066 non-numeric `node` user; DL3025 shell-form `HEALTHCHECK` ×2 — functionally identical to the JSON-array alternative)
- Cold start (clean clone → healthy): 29 s arm64 (local, Colima); amd64 via the app's own CI run on this commit — https://github.com/charlesmalo/FociToDo/actions/runs/36934017792 (`images` job, multi-arch build, green)

## Findings

By severity (60 findings, F-1..F-60): Critical 1 · High 3 · Important 3 · Medium 1 · Minor 1 · Low 50 · unrated 1 (F-38, a correctness fix with no severity tag in the log).

By decision: Fix 12 · Accept 48.

**Open items: none.** All 14 app PRs (#1–#14) are merged to `main` (confirmed: `git log --merges main` shows 14 `Merge pull request` commits, #1 through #14, the last being `de70329`). Every `Fix`-decision finding was independently confirmed present in the `de70329` source tree or re-verified by this sign-off's own evidence:
- F-3, F-4 (PR #2), F-21 (PR #12), F-38 (PR #8) — folded into their merged branches.
- F-19 (PR #12, shutdown re-entrancy guard) — merged.
- F-50 (Critical, stale-version overwrite on Save/Delete), F-51/F-52 (Important, year-0000 date and NUL-byte validation), F-53 (Minor, PATCH 415 doc) — all four read "(pending merge)" in `findings/log.md`, but PR #12 merged as `a3d1af3` well before `de70329`; directly confirmed in source: `editBase`/`deleteBase` capture in `apps/web/src/todos/components/TodoDetailsPanel.tsx`, `hasNoNul`/the `0000`-prefix refinement in `packages/shared/src/todo.ts`, and the PATCH `415` entry in `apps/api/src/http/openapi.ts`. The "(pending merge)" text is stale triage wording, not an open item.
- F-55 (High, nginx keepalive) — Fixed in PR #13 (merged `47eb261`); re-confirmed by this sign-off's own stress re-run (`http_req_failed` rate 0 across all 5 scenarios, 410–316,670 requests per scenario, see Evidence).
- F-56, F-60 (High, Trivy npm-CLI CVEs / lodash-es advisories) — Fixed in PR #14 (merged `de70329`, this release candidate); re-confirmed by this sign-off's own scan re-run (0 HIGH/CRITICAL, 0 audit findings, see Evidence).

Many `Accept`-decision Low-severity rows also still read "pending PR #N merge" — the same stale pre-merge wording; none represent outstanding work, since every numbered PR has since merged.

## Accepted risks and trade-offs

- Delete on a 404 keeps the details dialog open with an explicit "no longer exists" message rather than silently closing it (F-30, controller ruling R12) — judged safer than a vanishing dialog; diverges from spec §7.2's literal text.
- The create idempotency key is scoped to the submitted payload rather than "one key per form open" (F-31, ruling R13) — strictly safer: an edited retry can never collide into a false 422.
- A successful delete still fires one wasted background 404 fetch for the deleted item's own detail query (F-35) — cosmetic, no user-visible effect; a candidate `removeQueries`/targeted-cache-update fix was considered during PR #12's final review but not taken.
- `dueDate: '0000-13-01'` (invalid month *and* the newly-rejected year 0000) returns two identical 400 validation messages for the same field (F-54, ruling R17: parked) — cosmetic duplication, not a regression.
- The `e2e` Docker stage uses `npm install` rather than `npm ci` (F-40) — plan-mandated (spec A5, no host `node_modules`); mitigated by an exact `--save-exact` version pin plus `scripts/check-playwright-pin.mjs`, a drift check.
- 3 Hadolint findings accepted as style-only, not functional (F-57/F-58/F-59): non-numeric `USER node` (DL3066) and shell-form `HEALTHCHECK` ×2 (DL3025).
- Architectural trade-offs, each with its own consequences documented in an ADR at this commit: Postgres with plain SQL ([0002](https://github.com/charlesmalo/FociToDo/blob/de70329bc74e7be8172821d2cc9da887dbfdbcca/docs/decisions/0002-postgres-with-plain-sql.md)); optimistic locking via ETag/If-Match ([0004](https://github.com/charlesmalo/FociToDo/blob/de70329bc74e7be8172821d2cc9da887dbfdbcca/docs/decisions/0004-optimistic-locking-with-etags.md)); idempotent status actions and Idempotency-Key on create ([0005](https://github.com/charlesmalo/FociToDo/blob/de70329bc74e7be8172821d2cc9da887dbfdbcca/docs/decisions/0005-idempotent-status-and-create.md)); server-side UTC overdue computation ([0008](https://github.com/charlesmalo/FociToDo/blob/de70329bc74e7be8172821d2cc9da887dbfdbcca/docs/decisions/0008-server-side-utc-overdue.md)); single-page UI with a Radix dialog ([0010](https://github.com/charlesmalo/FociToDo/blob/de70329bc74e7be8172821d2cc9da887dbfdbcca/docs/decisions/0010-single-page-ui-with-dialog.md)); one multi-stage Dockerfile / Docker-only setup ([0012](https://github.com/charlesmalo/FociToDo/blob/de70329bc74e7be8172821d2cc9da887dbfdbcca/docs/decisions/0012-docker-only-setup.md)).

## Evidence

- Verify (clean clone → cold build → test gate → e2e, de70329): [`evidence/2026-10-02T035235Z/`](evidence/2026-10-02T035235Z/)
- Stress (k6 scenarios + invariant checks, de70329): [`evidence/2026-10-02T035425Z/stress/`](evidence/2026-10-02T035425Z/stress/)
- Scans (Trivy, Hadolint, npm audit, de70329): [`evidence/2026-10-02T034745Z/scans/`](evidence/2026-10-02T034745Z/scans/)
- App CI run on de70329 (test, e2e, images — multi-arch amd64+arm64 build, green): https://github.com/charlesmalo/FociToDo/actions/runs/36934017792
- Full traceability: [`traceability/matrix.md`](traceability/matrix.md)
- Full findings log: [`findings/log.md`](findings/log.md)
