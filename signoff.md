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

Every number below is read from the final evidence runs on `de70329` (see Evidence); each run's `summary.md` records the checked-out SHA.

- Test gate: PASS — 57 test files, 417 tests; coverage 100/100/100/100 (statements 716/716, branches 349/349, functions 246/246, lines 629/629)
- End-to-end: 9/9 journeys
- Concurrency stress: 5/5 scenarios PASS, 13/13 invariants hold (race-patch, parallel-complete, delete-storm, idempotent-replay, mixed-load); 0 failed requests out of 534,208; p95 list latency (`GET /todos` under mixed load) 10.14 ms
- Images: 0 HIGH/CRITICAL vulnerabilities in the app's own images (Trivy, `api` and `web`, `--ignore-unfixed`); 0 `npm audit --omit=dev --audit-level=high` findings. The unmodified upstream `postgres:17.11-alpine` image the app's `compose.yaml` pins has 22 Go stdlib CVEs (1 CRITICAL, 21 HIGH) in its `gosu` binary — accepted, see F-64/F-65 below. 3 Hadolint findings accepted as style-only (DL3066 non-numeric `node` user; DL3025 shell-form `HEALTHCHECK` ×2 — functionally identical to the JSON-array alternative)
- Clean-clone rebuild → healthy: 28 s (arm64; base images and npm cache warm) — local, Colima. Not a cold-machine time, and the README quick start was not run on a clean machine (the one unchecked box in the [release-readiness checklist](checklists/release-readiness-de70329.md)). CI's `images` job builds the `migrate`/`api`/`web` targets on amd64 (`ubuntu-latest`, plain `docker compose build`, no buildx/qemu/`--platform`) — https://github.com/charlesmalo/FociToDo/actions/runs/36934017792, green; no cross-arch timing was taken there. Every base image the shipped targets build from (`node:24.21-alpine`, `nginxinc/nginx-unprivileged:1.31-alpine`) is an official image published for both amd64 and arm64

Release readiness: [`checklists/release-readiness-de70329.md`](checklists/release-readiness-de70329.md) — 7 of 8 boxes checked, each with its evidence; the clean-machine box is left unchecked and explained.

## Findings

By severity (65 findings, F-1..F-65): Critical 2 · High 4 · Important 4 · Medium 2 · Minor 3 · Low 50.

By decision: Fix 20 · Accept 44 · Reject 1 (F-17, not reproducible).

**Open items: none.** All 14 app PRs (#1–#14) are merged to `main` (confirmed: `git log --merges main` shows 14 `Merge pull request` commits, #1 through #14, the last being `de70329`). In `findings/log.md`, every row names what raised it — an app PR's review, or a run of this repository's harness (`stress @ a3d1af3`, `scans @ 47eb261`, `scans @ de70329`) — and every Fix row names the PR and merge commit that fixed it. All 20 `Fix`-decision findings were independently confirmed present in the `de70329` source tree or re-verified by this sign-off's own evidence:
- F-3, F-4 (PR #2, merged `a698697`), F-38 (PR #8, merged `18c6664`) — folded into their branches before merge; confirmed in source (`structuredClone` copies in the in-memory adapter, no `ports.ts` coverage exclusion, `onCloseAutoFocus` opener restore in `TodoDialog.tsx`).
- F-19, F-21, F-27, F-29, F-32, F-42, F-43, F-44, F-49 (PR #12, merged `a3d1af3`) — confirmed in source: `shuttingDown` guard in `server.ts`; the delete-vs-patch test's `{ title: 'Edited', version: 2 }` assertion; PATCH `415` in `openapi.ts`/`openapi.json`; `ENV SCARF_ANALYTICS=false`; `fallbackFocusRef`; `<DocView key={page.path}>`; the `BUILD_DATE` shell default; `APP_VERSION` in `compose.yaml`'s web build args.
- F-50 (Critical, stale-version overwrite on Save/Delete), F-51/F-52 (Important, year-0000 date and NUL-byte validation), F-53 (Minor, PATCH 415 doc) — Fixed in PR #12, merged `a3d1af3`; confirmed in source: `editBase`/`deleteBase` capture in `apps/web/src/todos/components/TodoDetailsPanel.tsx`, `hasNoNul`/the `0000`-prefix refinement in `packages/shared/src/todo.ts`, and the PATCH `415` entry in `apps/api/src/http/openapi.ts`.
- F-55 (High, nginx keepalive) — Fixed in PR #13 (merged `47eb261`); re-confirmed by this sign-off's stress run (0 failed requests in all 5 scenarios, 410–318,005 requests per scenario).
- F-56, F-60 (High, Trivy npm-CLI CVEs / lodash-es advisories) and F-61 (Important, the build assertion that keeps F-56 fixed) — Fixed in PR #14 (merged `de70329`, this release candidate); re-confirmed by this sign-off's scan run (0 HIGH/CRITICAL on `api`/`web`, 0 audit findings) and in source (`! command -v …` at `Dockerfile:61-62`).

Every `Accept` row records where it was accepted — the PR and its merge commit, or, for the five harness findings that needed no app change (F-57..F-59, F-64, F-65), the harness run — and its reason is in the row or in that PR's triage table under [`reviews/`](reviews/). None represents outstanding work.

## Accepted risks and trade-offs

- Delete on a 404 keeps the details dialog open with an explicit "no longer exists" message rather than silently closing it (F-30, controller ruling R12) — judged safer than a vanishing dialog; diverges from spec §7.2's literal text.
- The create idempotency key is scoped to the submitted payload rather than "one key per form open" (F-31, ruling R13) — strictly safer: an edited retry can never collide into a false 422.
- A successful delete still fires one wasted background 404 fetch for the deleted item's own detail query (F-35) — cosmetic, no user-visible effect; a candidate `removeQueries`/targeted-cache-update fix was considered during PR #12's final review but not taken.
- `dueDate: '0000-13-01'` (invalid month *and* the newly-rejected year 0000) returns two identical 400 validation messages for the same field (F-54, ruling R17: parked) — cosmetic duplication, not a regression.
- The `e2e` Docker stage uses `npm install` rather than `npm ci` (F-40) — plan-mandated (spec A5, no host `node_modules`); mitigated by an exact `--save-exact` version pin plus `scripts/check-playwright-pin.mjs`, a drift check.
- 3 Hadolint findings accepted as style-only, not functional (F-57/F-58/F-59): non-numeric `USER node` (DL3066) and shell-form `HEALTHCHECK` ×2 (DL3025).
- The pinned upstream `postgres:17.11-alpine` image ships `gosu` built with Go 1.24.6, flagged with 1 CRITICAL and 21 HIGH Go stdlib CVEs (F-64/F-65). Accepted: the image is the unmodified official one, no patched `postgres:17` Alpine tag exists yet (the floating `postgres:17-alpine` has the same digest), and `gosu` only runs once at container start to drop root to the `postgres` user — it handles no TLS, network, URL or XML input, and `db` publishes no port. Remediation: bump the pin when a patched tag ships.
- No timing or quick-start run on a clean machine: the 28 s figure is a clean-clone rebuild with warm base images and npm cache, and Docker state was deliberately not pruned. The app's CI builds and runs the full stack on fresh amd64 runners (green on `de70329`).
- Architectural trade-offs, each with its own consequences documented in an ADR at this commit: Postgres with plain SQL ([0002](https://github.com/charlesmalo/FociToDo/blob/de70329bc74e7be8172821d2cc9da887dbfdbcca/docs/decisions/0002-postgres-with-plain-sql.md)); optimistic locking via ETag/If-Match ([0004](https://github.com/charlesmalo/FociToDo/blob/de70329bc74e7be8172821d2cc9da887dbfdbcca/docs/decisions/0004-optimistic-locking-with-etags.md)); idempotent status actions and Idempotency-Key on create ([0005](https://github.com/charlesmalo/FociToDo/blob/de70329bc74e7be8172821d2cc9da887dbfdbcca/docs/decisions/0005-idempotent-status-and-create.md)); server-side UTC overdue computation ([0008](https://github.com/charlesmalo/FociToDo/blob/de70329bc74e7be8172821d2cc9da887dbfdbcca/docs/decisions/0008-server-side-utc-overdue.md)); single-page UI with a Radix dialog ([0010](https://github.com/charlesmalo/FociToDo/blob/de70329bc74e7be8172821d2cc9da887dbfdbcca/docs/decisions/0010-single-page-ui-with-dialog.md)); one multi-stage Dockerfile / Docker-only setup ([0012](https://github.com/charlesmalo/FociToDo/blob/de70329bc74e7be8172821d2cc9da887dbfdbcca/docs/decisions/0012-docker-only-setup.md)).

## Evidence

Final runs on `de70329`, all with the current harness (`docker compose run --rm --build -e APP_REF=de70329bc74e7be8172821d2cc9da887dbfdbcca verify|stress|scans`):

- Verify (clean clone → `--no-cache` rebuild → test gate → e2e): [`evidence/2026-10-02T043210Z/`](evidence/2026-10-02T043210Z/)
- Stress (k6 scenarios + invariant checks): [`evidence/2026-10-02T043341Z/stress/`](evidence/2026-10-02T043341Z/stress/)
- Scans (Trivy on `api`, `web` and `postgres:17.11-alpine`; Hadolint; npm audit): [`evidence/2026-10-02T043626Z/scans/`](evidence/2026-10-02T043626Z/scans/)
- Release readiness: [`checklists/release-readiness-de70329.md`](checklists/release-readiness-de70329.md)
- App CI run on de70329 (test, e2e, images — `images` builds `migrate`/`api`/`web` on amd64, green): https://github.com/charlesmalo/FociToDo/actions/runs/36934017792
- Full traceability: [`traceability/matrix.md`](traceability/matrix.md)
- Full findings log: [`findings/log.md`](findings/log.md)

Earlier evidence directories stay committed as history (pre-fix harness runs and the runs that found F-55..F-60); this sign-off cites only the three above.
