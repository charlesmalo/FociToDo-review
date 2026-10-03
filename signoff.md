# Release sign-off — FociToDo @ 153d719

**Date:** 2026-10-03 · commit `153d7193d8170d1f8658ab4a047fcc34a7b6c711` (PR #21's merge, the commit after PR #18 "UI wireframes for every screen state", PR #19 "fix: re-resolve the api so the proxy survives an api restart", PR #20 "fix: name each filter control by its label alone" and PR #21 "fix: patch pcre2 in the web image (CVE-2026-103111)")

**Recommendation:** Ready with noted risks

Noted risks:
- F-64/F-65 — the unmodified upstream `postgres:17.11-alpine` image ships `gosu` with Go-stdlib CVEs (1 CRITICAL, 21 HIGH), unchanged since the de70329 sign-off. No patched tag is published yet (the floating `postgres:17-alpine` has the same digest), and `gosu` runs once at container start to drop root. Remediation: bump the pin when a patched tag ships.

The upstream `nginx-unprivileged` `pcre2` HIGH CVE noted at the `5c43da9` sign-off (F-98) is **fixed**, not merely accepted — see "Independent acceptance and storyboard found three real app defects, all fixed" below.

This sign-off folds the `5c43da9` sign-off into this one (the only change since is a one-layer Dockerfile security patch, PR #21) rather than keeping it as a separate history section, per the controller's choice; every evidence link from the `5c43da9` sign-off is preserved below, either re-run fresh at `153d719` or, for `stress` (not re-run this round — see Quality snapshot), cited at its original `5c43da9` path. This sign-off is still the first to run the review repository's new **independent acceptance** and **storyboard** harnesses (built in the `5c43da9` cycle) against the app, in addition to the existing `verify`/`stress`/`scans`.

## Scope delivered vs requested

| Requirement | Delivered |
|---|---|
| Functional: add / list / view / update / complete / incomplete / delete a to-do, filter, sort (FR-1–FR-9) | All 9 Done — [traceability/matrix.md](traceability/matrix.md); independently re-proven black-box by this review's acceptance catalogue (BR-01..BR-21) and storyboard (11 journeys) |
| Functional: in-app developer docs (FR-10) | **Removed** by design — [ADR 0015](https://github.com/charlesmalo/FociToDo/blob/153d7193d8170d1f8658ab4a047fcc34a7b6c711/docs/decisions/0015-docs-and-diagrams-in-the-repository.md), PR #16 |
| Data rules: id, title, description, dueDate, isCompleted, createdAt, version, isOverdue (DR-1–DR-8) | All 8 Done — [traceability/matrix.md](traceability/matrix.md); independently re-proven black-box by DR-01..DR-19 |
| Non-functional: Docker-only setup, TypeScript/Node 24, Postgres persistence, ports + two adapters, concurrency guarantees, strict validation + problem details, 100% coverage, lint-enforced layers, multi-stage/non-root/prod-only images, docs + Mermaid, OpenAPI from Zod (NFR-0–NFR-10) | All 11 Done — [traceability/matrix.md](traceability/matrix.md) |
| New: every diagram has a committed, current image and a README map entry (DOC-1) | Done — PR #17; 32 diagrams total (19 + 13 UI wireframes added by PR #18) |
| New: every screen state of the single-page UI is documented as a wireframe (DOC-2) | Done — PR #18 (merged `aeaa602`); independently matched against the running app by this review's storyboard — 13/13 wireframes paired with 22 real screenshots across 11 journeys, which also found and led to the fix of a real UI accessibility defect this way (F-92, PR #20) |
| Delivery: public app repo, README (build/run/tests/design/assumptions/trade-offs), curated PR history, public review repo, CI running the README's own Docker commands (D-1–D-9) | All 9 Done — [traceability/matrix.md](traceability/matrix.md) |

40 traceability rows (FR/DR/NFR/DOC/D) read `Done`, except FR-10 which reads `Removed` by deliberate design decision; none `In progress` or `Planned`. The matrix now also carries an **Independent acceptance** column (expectation-catalogue IDs and storyboard journeys, or an explicit "not observable from outside" reason) alongside the unchanged app-test citation column, for every row.

## Quality snapshot

Every number below is read from the final evidence runs on `153d719` (see Evidence), except stress — see its own bullet. Each run's `summary.md`/`results.md` records the checked-out SHA.

- **Independent acceptance**: 99/99 PASS, 0 FAIL — [`evidence/2026-10-03T094027Z/acceptance/`](evidence/2026-10-03T094027Z/acceptance/). By section: Brief actions (BR) 21, Data rules (DR) 19, Error contract (EC) 17, Concurrency surface (CS) 7, README assumptions (RA) 14, Robustness (RB) 18, API documentation and health (AD) 3 — 99 total. By source: brief 21, spec 22, api guide 24, openapi 3, README assumption 15, robustness 14 — 99 total.
- **Storyboard**: 22 captioned frames across 11 journeys (add, list-and-view, edit, complete, filter-and-sort, validation, conflict, deleted-elsewhere, delete, reload, loading-and-error); all 13 `docs/ui.md` wireframes paired with at least one frame — [`evidence/2026-10-03T094100Z/storyboard/storyboard.md`](evidence/2026-10-03T094100Z/storyboard/storyboard.md).
- Test gate: PASS — 59 test files, 459 tests; coverage 100/100/100/100 (statements 827/827, branches 386/386, functions 273/273, lines 736/736)
- End-to-end: 8/8 journeys (unchanged in scope since the `41a279a` sign-off)
- Concurrency stress: **not re-run this round** — only change since `5c43da9` is PR #21's one-layer `web`-image package patch (`apk upgrade pcre2` plus a build-time version check), which cannot alter API/Postgres concurrency behaviour (no API, service, repository or nginx-routing code touched). The `5c43da9` stress evidence stands: 5/5 scenarios PASS, 13/13 invariants hold (race-patch, parallel-complete, delete-storm, idempotent-replay, mixed-load); 0 failed requests out of 545,176 (`http_req_failed` 0.00% in every scenario's k6 log); p95 list latency (`GET /todos` under mixed load) 9.80 ms — [`evidence/2026-10-03T090659Z/stress/`](evidence/2026-10-03T090659Z/stress/)
- Images: 0 HIGH/CRITICAL vulnerabilities on **both** `api` and `web` now (Trivy, `--ignore-unfixed` — F-98's `pcre2` CVE fixed by PR #21); 0 `npm audit --omit=dev --audit-level=high` findings. The unmodified upstream `postgres:17.11-alpine` image still has 22 Go stdlib CVEs (1 CRITICAL, 21 HIGH) in its `gosu` binary, unchanged — accepted, see F-64/F-65. Hadolint now reports 5 findings (was 3): the 3 pre-existing style findings unchanged (DL3066 ×1, DL3025 ×2), plus 2 new ones introduced by PR #21's pcre2-patch layer (DL3066 on its temporary `USER root`, DL4006 on its pipe) — both accepted as style-only, no functional impact (F-99, F-100)
- Clean-clone rebuild → healthy: 27 s (arm64; base images and npm cache warm) — local, Colima. Not a cold-machine time; the README quick start was not run on a clean machine (the one unchecked box in the [release-readiness checklist](checklists/release-readiness-153d719.md)), unchanged from earlier sign-offs. CI on `main` at `153d719` is green on fresh `ubuntu-latest` runners, all 4 jobs (test, images, diagrams, e2e) — run [37113543211](https://github.com/charlesmalo/FociToDo/actions/runs/37113543211)

Release readiness: [`checklists/release-readiness-153d719.md`](checklists/release-readiness-153d719.md) — 7 of 8 boxes checked, each with its evidence; the clean-machine box is left unchecked and explained, unchanged from earlier sign-offs.

## Independent acceptance and storyboard found three real app defects, all fixed

- **BR-20 — persistence across an api+db restart** (found by this review's acceptance harness against `41a279a`): `apps/web/nginx.conf`'s `upstream api_upstream { server api:3000; }` resolved `api` once at nginx startup; after the `api` container restarted on a new Docker-network IP, nginx kept proxying to the stale address and every `/api/*` request 502'd forever, with no self-recovery. **Fixed in PR #19** (merged `3b76cfa`): `resolver 127.0.0.11 valid=10s ipv6=off;` plus `zone api_upstream 64k;` / `server api:3000 resolve;`, keeping PR #13's keepalive pool intact. Re-confirmed by this sign-off's own acceptance run at `153d719`: 99/99 PASS including BR-20 — see F-91.
- **Filter-control accessible names** (found by this review's storyboard, Playwright driving real Chromium — not reproducible in jsdom's accessible-name library): each `<select>` in `TodoFilters.tsx` was nested inside its `<label>`, so the browser computed the control's accessible name from the label's entire text content including every option — the "Sort by" control was announced as `"Sort by Created Due date Title"`. **Fixed in PR #20** (merged `5c43da9`): `<label htmlFor={id}>`/`<select id={id}>` via `useId()`, plus a structural regression test. Re-confirmed by this sign-off's own storyboard run at `153d719`: the filter-and-sort journey's frames screenshot the fixed controls — see F-92.
- **`pcre2` HIGH CVE in the `web` base image** (found by this review's scans run against `5c43da9`): the unmodified upstream `nginxinc/nginx-unprivileged:1.31-alpine` image's Alpine base shipped `pcre2 10.48-r0`, with a fix (10.49-r0) already published by Alpine. **Fixed in PR #21** (merged `153d719`): `apk upgrade --no-cache pcre2` plus a positive, RED-proven version-floor check (`apk list -I`, not the vacuous `apk info -v` an earlier draft used) that fails the build unless pcre2 ≥ 10.49 is actually installed. Re-confirmed by this sign-off's own scans run at `153d719`: Trivy `review-scan-web` 0 HIGH/CRITICAL — see F-98.

## Findings

By severity (100 findings, F-1..F-100): Critical 2 · High 6 · Important 14 · Medium 3 · Minor 22 · Low 53.

By decision: Fix 42 · Accept 57 · Reject 1 (F-17 "not reproducible" — the only Reject; see below for why F-95 moved out of Reject).

**Open items: none.** All 21 app PRs (#1–#21) are merged to `main`; app CI is green on `main` at `153d719` (run 37113543211, 4/4 jobs). 10 new findings since the `41a279a` sign-off's F-90 (F-91..F-100):
- F-91 (High, availability) — BR-20, the nginx stale-upstream persistence defect above. Fix, PR #19 (merged `3b76cfa`).
- F-92 (Medium, accessibility) — the storyboard filter-label defect above. Fix, PR #20 (merged `5c43da9`).
- F-93, F-94 (Minor, contract) — RB-11's catalogue wording corrected to describe the actual, safe behaviour of two odd-id probes (nginx's own SPA-fallback normalisation; nginx's own request-line rejection of a raw NUL) instead of a blanket 4xx. Accept, Rulings R46/R48, this repository's commit `f921d31`.
- F-95 (Minor, contract) — AD-03's catalogue wording corrected from an unconditional 200 to "(following redirects)", matching Swagger UI's standard trailing-slash redirect. **Accept** (Ruling R51, this fix round — changed from the earlier Reject for consistency with F-93/F-94: app behaviour correct, catalogue expectation corrected; Reject stays reserved for findings that don't reproduce, e.g. F-17), Ruling R47 (the original correction), this repository's commit `f921d31`.
- F-96 (Important, tests) — `scripts/acceptance.sh` now tears down a stale `review-acceptance` stack before starting. Fix, this repository's commit `8a70e4b`.
- F-97 (Important, docs) — the design spec's §2 and the plan's Global Constraints section, reconciled to name the identical allowed-sources list. Fix, PR #18 (merged `aeaa602`), Ruling R44.
- F-98 (High, security) — the `web`-image upstream `pcre2` CVE above. **Fix this fix round** (Ruling R50: fixable, so fixed in the app) — PR #21 (merged `153d719`); was Accept at the `5c43da9` sign-off.
- F-99, F-100 (Low, security) — two new Hadolint style findings on PR #21's own pcre2-patch layer (`USER root`; a pipe without `pipefail`). Accept, no functional impact, this fix round.

Every `Accept`/`Reject` row records where it was decided and its reason is in the row or in that PR's triage table under [`reviews/`](reviews/), including [`reviews/PR-18-ui-wireframes.md`](reviews/PR-18-ui-wireframes.md), [`reviews/PR-19-nginx-reresolve-api.md`](reviews/PR-19-nginx-reresolve-api.md), [`reviews/PR-20-filter-labels.md`](reviews/PR-20-filter-labels.md) and the new [`reviews/PR-21-web-pcre2.md`](reviews/PR-21-web-pcre2.md). All findings carried forward from the `41a279a` sign-off (F-1..F-90) are unchanged; see the earlier sign-off below for their detail.

## Accepted risks and trade-offs

- The pinned upstream `postgres:17.11-alpine` image ships `gosu` built with Go 1.24.6, flagged with 1 CRITICAL and 21 HIGH Go stdlib CVEs (F-64/F-65), unchanged since the de70329 sign-off. Accepted: the image is the unmodified official one, no patched `postgres:17` Alpine tag exists yet, and `gosu` only runs once at container start to drop root — it handles no TLS, network, URL or XML input, and `db` publishes no port. Remediation: bump the pin when a patched tag ships.
- Two odd-id robustness probes (RB-11) don't return a uniform problem-details 4xx — one is nginx's own safe SPA-fallback normalisation (200, serving `index.html`, outside `/api`), the other is nginx's own request-line rejection of a raw NUL (its stock HTML error page, the request never reaching the app) — both accepted as safe, documented behaviour rather than app defects (F-93/F-94, Rulings R46/R48).
- `GET /api/docs` 301-redirects to `/api/docs/` before the 200 HTML response (AD-03) — standard Swagger UI static-directory behaviour, not an app defect; the original catalogue expectation (an unconditional 200) was itself wrong and has been corrected (F-95, Accept per Ruling R51).
- Two Hadolint style findings on PR #21's pcre2-patch layer (F-99, F-100) — a temporary `USER root` and a pipe without `pipefail`, both intentional/harmless as explained above.
- All risks and trade-offs carried forward from the `41a279a` sign-off (the `/dev` portal removal, the spec's cross-arch diagram contingency, delete-on-404 dialog behaviour, the scoped create-idempotency key, the wasted background delete fetch, the duplicated `0000-13-01` validation message, the `e2e` stage's `npm install`, 3 Hadolint style findings, no clean-machine timing run, and the architectural trade-off ADRs) are unchanged — see the earlier sign-off below.

## Evidence

Final runs on `153d719` (`docker compose run --rm --build -e APP_REF=153d7193d8170d1f8658ab4a047fcc34a7b6c711 acceptance|storyboard|verify|scans`; `stress` not re-run, see Quality snapshot):

- Independent acceptance (black-box curl checks): [`evidence/2026-10-03T094027Z/acceptance/`](evidence/2026-10-03T094027Z/acceptance/) — 99/99 PASS
- Storyboard (captioned screenshots beside wireframes): [`evidence/2026-10-03T094100Z/storyboard/`](evidence/2026-10-03T094100Z/storyboard/) — 22 frames, 11 journeys, 13/13 wireframes paired
- Verify (clean clone → `--no-cache` rebuild → test gate → e2e): [`evidence/2026-10-03T093902Z/`](evidence/2026-10-03T093902Z/)
- Scans (Trivy on `api`, `web` and `postgres:17.11-alpine`; Hadolint; npm audit): [`evidence/2026-10-03T093820Z/scans/`](evidence/2026-10-03T093820Z/scans/)
- Stress (k6 scenarios + invariant checks, from the `5c43da9` cycle — still valid, see Quality snapshot): [`evidence/2026-10-03T090659Z/stress/`](evidence/2026-10-03T090659Z/stress/)
- Release readiness: [`checklists/release-readiness-153d719.md`](checklists/release-readiness-153d719.md)
- App CI run on `153d719` (test, images, diagrams, e2e — all four jobs green): https://github.com/charlesmalo/FociToDo/actions/runs/37113543211
- Review notes: [`reviews/PR-18-ui-wireframes.md`](reviews/PR-18-ui-wireframes.md), [`reviews/PR-19-nginx-reresolve-api.md`](reviews/PR-19-nginx-reresolve-api.md), [`reviews/PR-20-filter-labels.md`](reviews/PR-20-filter-labels.md), [`reviews/PR-21-web-pcre2.md`](reviews/PR-21-web-pcre2.md)
- Full traceability: [`traceability/matrix.md`](traceability/matrix.md)
- Full findings log: [`findings/log.md`](findings/log.md)

The `5c43da9` sign-off's own acceptance/storyboard/verify/scans evidence (`evidence/2026-10-03T090410Z/acceptance/`, `evidence/2026-10-03T090448Z/storyboard/`, `evidence/2026-10-03T090528Z/`, `evidence/2026-10-03T091041Z/scans/`) stays committed as history, superseded by the `153d719` runs above for every number except stress (unchanged, cited directly above). Earlier evidence directories (41a279a, de70329 and before) also stay committed as history.

---

# Earlier sign-off — FociToDo @ 41a279a

Kept as history. At the time this was written, `41a279a` was the release candidate (PR #17's merge); `main` subsequently gained PR #18 (UI wireframes), PR #19 (fix: nginx re-resolves the api), PR #20 (fix: filter labels) and PR #21 (fix: pcre2 in the web image) — see the `153d719` sign-off above (which folds in the intermediate `5c43da9` sign-off), superseding the recommendation below.

**Recommendation:** Ready with noted risks

Noted risks: F-64/F-65 — the unmodified upstream `postgres:17.11-alpine` image ships `gosu` with Go-stdlib CVEs (1 CRITICAL, 21 HIGH), unchanged since the de70329 sign-off. No patched tag is published yet (the floating `postgres:17-alpine` has the same digest), and `gosu` runs once at container start to drop root. Remediation: bump the pin when a patched tag ships.

## Scope delivered vs requested

| Requirement | Delivered |
|---|---|
| Functional: add / list / view / update / complete / incomplete / delete a to-do, filter, sort (FR-1–FR-9) | All 9 Done — [traceability/matrix.md](traceability/matrix.md) |
| Functional: in-app developer docs (FR-10) | **Removed** by design — [ADR 0015](https://github.com/charlesmalo/FociToDo/blob/41a279aeb13ed7aa677fa8248db7b33f9bcf98c7/docs/decisions/0015-docs-and-diagrams-in-the-repository.md), PR #16 (merged `141356a`); GitHub already renders the same Markdown and Mermaid, and the portal shipped development material in the production image |
| Data rules: id, title, description, dueDate, isCompleted, createdAt, version, isOverdue (DR-1–DR-8) | All 8 Done — [traceability/matrix.md](traceability/matrix.md) |
| Non-functional: Docker-only setup, TypeScript/Node 24, Postgres persistence, ports + two adapters, concurrency guarantees, strict validation + problem details, 100% coverage, lint-enforced layers, multi-stage/non-root/prod-only images, docs + Mermaid, OpenAPI from Zod (NFR-0–NFR-10) | All 11 Done — NFR-9 re-pointed to the diagram gate and CI job — [traceability/matrix.md](traceability/matrix.md) |
| New: every diagram has a committed, current image and a README map entry (DOC-1) | Done — PR #17 (merged `41a279a`) — [traceability/matrix.md](traceability/matrix.md) |
| Delivery: public app repo, README (build/run/tests/design/assumptions/trade-offs), curated PR history, public review repo, CI running the README's own Docker commands (D-1–D-9) | All 9 Done — [traceability/matrix.md](traceability/matrix.md) |

39 traceability rows (FR/DR/NFR/DOC/D) read `Done`, except FR-10 which reads `Removed` by deliberate design decision (ADR 0015); none `In progress` or `Planned`.

## Quality snapshot

Every number below is read from the final evidence runs on `41a279a` (see Evidence); each run's `summary.md` records the checked-out SHA.

- Test gate: PASS — 59 test files, 455 tests; coverage 100/100/100/100 (statements 824/824, branches 386/386, functions 273/273, lines 733/733)
- End-to-end: **8/8** journeys — down from 9/9 because the `/dev`-portal journey was removed together with the portal itself (PR #16); diagram validity, previously that journey's job, is now proven by the test gate (`packages/diagrams`'s `checkRepository`, run as part of `docker compose --profile test run --rm --build test`) and the CI `diagrams` job (see below), not an e2e journey — see `traceability/matrix.md`'s NFR-9 and DOC-1 rows
- Concurrency stress: 5/5 scenarios PASS, 13/13 invariants hold (race-patch, parallel-complete, delete-storm, idempotent-replay, mixed-load); 0 failed requests out of 509,411; p95 list latency (`GET /todos` under mixed load) 10.96 ms
- Images: 0 HIGH/CRITICAL vulnerabilities in the app's own images (Trivy, `api` and `web`, `--ignore-unfixed`); 0 `npm audit --omit=dev --audit-level=high` findings — this now confirms `lodash-es`, `mermaid`, `react-markdown` and `remark-gfm` are gone from the dependency tree entirely (PR #16), not merely overridden (PR #14's F-60 fix). The unmodified upstream `postgres:17.11-alpine` image the app's `compose.yaml` pins still has 22 Go stdlib CVEs (1 CRITICAL, 21 HIGH) in its `gosu` binary, unchanged from the de70329 sign-off — accepted, see F-64/F-65 below. 3 Hadolint findings accepted as style-only (DL3066 non-numeric `node` user; DL3025 shell-form `HEALTHCHECK` ×2)
- Diagrams: the CI `diagrams` job reproduces every one of the 19 committed images byte-for-byte on amd64 (`ubuntu-latest`, plain `docker compose`, no buildx/qemu/`--platform`) from the same Mermaid sources rendered locally on arm64 — run [36994896549](https://github.com/charlesmalo/FociToDo/actions/runs/36994896549), PR #17's final commit `a1f79e3`; confirmed again on `main` at `41a279a` — run [36995141552](https://github.com/charlesmalo/FociToDo/actions/runs/36995141552)
- Clean-clone rebuild → healthy: 28 s (arm64; base images and npm cache warm) — local, Colima. Not a cold-machine time, and the README quick start was not run on a clean machine (the one unchecked box in the [release-readiness checklist](checklists/release-readiness-41a279a.md)). Every base image the shipped targets build from (`node:24.21-alpine`, `nginxinc/nginx-unprivileged:1.31-alpine`) is an official image published for both amd64 and arm64

Release readiness: [`checklists/release-readiness-41a279a.md`](checklists/release-readiness-41a279a.md) — 7 of 8 boxes checked, each with its evidence; the clean-machine box is left unchecked and explained, unchanged from the de70329 sign-off.

## Findings

By severity (90 findings, F-1..F-90): Critical 2 · High 4 · Important 12 · Medium 2 · Minor 19 · Low 51.

By decision: Fix 37 · Accept 52 · Reject 1 (F-17, not reproducible).

**Open items: none.** All 17 app PRs (#1–#17) are merged to `main` (confirmed: `git log --merges main` shows 17 `Merge pull request` commits, #1 through #17, the last being `41a279a`). In `findings/log.md`, every row names what raised it — an app PR's review, or a run of this repository's harness (`stress @ a3d1af3`, `scans @ 47eb261`, `scans @ de70329`) — and every Fix row names the PR and merge commit that fixed it. All Fix-decision findings from this cycle were independently confirmed present in the `41a279a` source tree or re-verified by this sign-off's own evidence:
- F-68, F-69 (PR #16, merged `141356a`) — confirmed in source: the spec's "Amended 2026-10-02" banner and ADR 0011's "(superseded by 0015)" summary line; `docs(decisions)` scope on the corrected commit.
- F-71, F-72, F-73 (PR #16, merged `141356a`) — spec §2.3's example fenced; commit message reworded; the web test suite's URL restore moved into `afterEach`.
- F-76, F-77 (PR #17, merged `41a279a`, Ruling R37/R38) — confirmed in source: `packages/diagrams/src/layout.ts` enforces exact line positions; `packages/diagrams/src/check.ts:36-41` reports a corrupt manifest as a problem instead of throwing.
- F-80, F-82, F-83 (PR #17, merged `41a279a`) — confirmed in source: `.github/workflows/ci.yml:74-82` uploads the regenerated images on failure; indented/annotated Mermaid fences now fail loudly; `useMaxWidth: false` with fixed sizes in the Mermaid config.
- F-84..F-89 (PR #17, merged `41a279a`) — stale package descriptions, the `CLAUDE.md` diagram rule, spec §2.6 wording, the layout indentation/blank-line rule, the digest-pinned Mermaid CLI image, and the Linux root-owned `docs/diagrams` note, all confirmed present at `41a279a`.
- F-60 (High, `lodash-es` via `mermaid`, fixed in PR #14) — its root cause removed entirely by PR #16 (merged `141356a`): `mermaid`, `react-markdown`, `remark-gfm` and the `lodash-es` override are no longer dependencies, re-confirmed by this sign-off's scan (`evidence/2026-10-02T103040Z/scans/npm-audit.txt` → `found 0 vulnerabilities`); Decision and prior history unchanged.
- All findings carried forward from the de70329 sign-off (F-1..F-67) are unchanged; see the earlier sign-off below for their detail.

Every `Accept` row records where it was accepted — the PR and its merge commit, or, for the harness findings that needed no app change (F-57..F-59, F-64, F-65), the harness run — and its reason is in the row or in that PR's triage table under [`reviews/`](reviews/), including [`reviews/PR-16-remove-dev-portal.md`](reviews/PR-16-remove-dev-portal.md) and [`reviews/PR-17-diagram-images.md`](reviews/PR-17-diagram-images.md). Notably, F-81 (the spec's cross-arch rendering contingency) is parked with direct evidence rather than further spec changes: the CI `diagrams` job's amd64 reproduction of the arm64-committed SVG bytes (above). None represents outstanding work.

## Accepted risks and trade-offs

- The pinned upstream `postgres:17.11-alpine` image ships `gosu` built with Go 1.24.6, flagged with 1 CRITICAL and 21 HIGH Go stdlib CVEs (F-64/F-65), unchanged since the de70329 sign-off. Accepted: the image is the unmodified official one, no patched `postgres:17` Alpine tag exists yet, and `gosu` only runs once at container start to drop root — it handles no TLS, network, URL or XML input, and `db` publishes no port. Remediation: bump the pin when a patched tag ships.
- The `/dev` portal (FR-10) is removed rather than fixed or hidden — ADR 0015: GitHub already renders the same Markdown and Mermaid the portal duplicated, and the portal shipped development material (`mermaid`, `react-markdown`, `remark-gfm`, a `lodash-es` security override) in the production image. Consequence, documented in the ADR: diagram images are now generated files that must be regenerated when a diagram changes — enforced by the test gate and CI, not by the app at runtime.
- The spec's cross-arch contingency for the `diagrams` CI job was incoherent as written (F-81) — parked rather than further specified, with direct evidence instead: CI on amd64 reproduces the arm64-committed SVG bytes exactly.
- `readmeMap`'s row detection and a `path.join`/`path.posix.relative` style inconsistency in `repo.ts` (F-78), and `headingText` keeping Markdown formatting characters in an exotic heading (F-90, Ruling R42) — both parked: no current content triggers either, and neither affects the shipped README map.
- Carried forward unchanged from the de70329 sign-off: delete-on-404 keeps the details dialog open rather than closing it (F-30); the create idempotency key is scoped to the submitted payload (F-31); one wasted background fetch after a successful delete (F-35); a duplicated 400 message for `dueDate: '0000-13-01'` (F-54); the `e2e` Docker stage's `npm install` rather than `npm ci` (F-40); 3 Hadolint style findings (F-57/F-58/F-59); no timing or quick-start run on a clean machine.
- Architectural trade-offs, each with its own consequences documented in an ADR: Postgres with plain SQL ([0002](https://github.com/charlesmalo/FociToDo/blob/41a279aeb13ed7aa677fa8248db7b33f9bcf98c7/docs/decisions/0002-postgres-with-plain-sql.md)); optimistic locking via ETag/If-Match ([0004](https://github.com/charlesmalo/FociToDo/blob/41a279aeb13ed7aa677fa8248db7b33f9bcf98c7/docs/decisions/0004-optimistic-locking-with-etags.md)); idempotent status actions and Idempotency-Key on create ([0005](https://github.com/charlesmalo/FociToDo/blob/41a279aeb13ed7aa677fa8248db7b33f9bcf98c7/docs/decisions/0005-idempotent-status-and-create.md)); server-side UTC overdue computation ([0008](https://github.com/charlesmalo/FociToDo/blob/41a279aeb13ed7aa677fa8248db7b33f9bcf98c7/docs/decisions/0008-server-side-utc-overdue.md)); single-page UI with a Radix dialog ([0010](https://github.com/charlesmalo/FociToDo/blob/41a279aeb13ed7aa677fa8248db7b33f9bcf98c7/docs/decisions/0010-single-page-ui-with-dialog.md)); one multi-stage Dockerfile / Docker-only setup ([0012](https://github.com/charlesmalo/FociToDo/blob/41a279aeb13ed7aa677fa8248db7b33f9bcf98c7/docs/decisions/0012-docker-only-setup.md)); docs and diagrams live in the repository, not an in-app portal ([0015](https://github.com/charlesmalo/FociToDo/blob/41a279aeb13ed7aa677fa8248db7b33f9bcf98c7/docs/decisions/0015-docs-and-diagrams-in-the-repository.md)).

## Evidence

Final runs on `41a279a`, all with the current harness (`docker compose run --rm --build -e APP_REF=41a279aeb13ed7aa677fa8248db7b33f9bcf98c7 verify|stress|scans`):

- Verify (clean clone → `--no-cache` rebuild → test gate → e2e): [`evidence/2026-10-02T102541Z/`](evidence/2026-10-02T102541Z/)
- Stress (k6 scenarios + invariant checks): [`evidence/2026-10-02T102716Z/stress/`](evidence/2026-10-02T102716Z/stress/)
- Scans (Trivy on `api`, `web` and `postgres:17.11-alpine`; Hadolint; npm audit): [`evidence/2026-10-02T103040Z/scans/`](evidence/2026-10-02T103040Z/scans/)
- Release readiness: [`checklists/release-readiness-41a279a.md`](checklists/release-readiness-41a279a.md)
- App CI run on `41a279a` (test, e2e, images, diagrams — all four jobs green): https://github.com/charlesmalo/FociToDo/actions/runs/36995141552
- CI `diagrams` job byte-for-byte amd64 reproduction, PR #17's final commit `a1f79e3`: https://github.com/charlesmalo/FociToDo/actions/runs/36994896549
- Review notes: [`reviews/PR-16-remove-dev-portal.md`](reviews/PR-16-remove-dev-portal.md), [`reviews/PR-17-diagram-images.md`](reviews/PR-17-diagram-images.md)
- Full traceability: [`traceability/matrix.md`](traceability/matrix.md)
- Full findings log: [`findings/log.md`](findings/log.md)

Earlier evidence directories stay committed as history (pre-fix harness runs and the de70329/c39af72 evidence below); this sign-off cites only the three evidence directories above for the `41a279a` numbers.

---

# Earlier sign-off — FociToDo @ de70329

Kept as history. At the time this was written, `de70329` was the release candidate (PR #14's merge); `main` subsequently gained PR #15 (docs-only, see its own Post-sign-off note below), then PR #16 (removed the `/dev` portal) and PR #17 (diagram images) — see the `41a279a` sign-off above, which supersedes the recommendation below.

**Recommendation:** Ready with noted risks

Noted risks: F-64/F-65 — the unmodified upstream `postgres:17.11-alpine` image ships `gosu` with Go-stdlib CVEs (1 CRITICAL, 21 HIGH). No patched tag is published yet (the floating `postgres:17-alpine` has the same digest), and `gosu` runs once at container start to drop root. Remediation: bump the pin when a patched tag ships.

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

By severity (67 findings, F-1..F-67): Critical 2 · High 4 · Important 4 · Medium 2 · Minor 4 · Low 51.

By decision: Fix 21 · Accept 45 · Reject 1 (F-17, not reproducible).

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

## Post-sign-off

`main` is now `c39af72` (PR #15, merged after this sign-off was written). It differs from the signed-off `de70329` only in `README.md` and `AGENTS.md` — a docs-only change (`git diff --stat de70329 c39af72`: 2 files changed, no code, Dockerfile, compose or test file touched).

- CI on `c39af72` (test, e2e, images — all three jobs): green — https://github.com/charlesmalo/FociToDo/actions/runs/36980193267
- The rewritten README's boot/verify/smoke/test commands were re-verified by two independent fresh-clone walkthroughs, each following the README literally: the implementer's walkthrough found and fixed one pre-merge bug (the teardown snippet's `status` variable name collided with zsh's read-only `$status`, renamed to `rc`; F-66); an independent reviewer's cold-read of only the README in a second fresh clone confirmed boot, readiness, smoke test (`ETag` `"1"`→`"2"`→`"3"`, stale `If-Match` → 412) and teardown all exit 0 under both zsh and sh. Details: [`reviews/PR-15-boot-and-test.md`](reviews/PR-15-boot-and-test.md).

Recommendation at the time: **Ready with noted risks** (F-64/F-65, unmodified upstream `postgres:17.11-alpine` `gosu` CVEs) — carried forward unchanged to the `41a279a` sign-off above.
