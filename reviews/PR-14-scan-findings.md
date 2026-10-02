# Review — PR #14 fix: clear two HIGH security-scan findings (F-56, F-60)

- App commit range: `47eb261..3178f14` (two commits after one fix round; merged as `de70329`, the release candidate) · PR: https://github.com/charlesmalo/FociToDo/pull/14 · Date: 2026-10-01 (pre-merge review and fix round), written up here 2026-10-02 · Reviewer: Claude Code (automated) + solution-lead triage
- Origin: not a planned PR. This repository's scan harness, run against the then release candidate `47eb261`, found
  two fixable HIGH findings (F-56: 7 HIGH CVEs in the `api` image; F-60: 2 HIGH `lodash-es` advisories). The
  solution lead ruled both app fixes (Ruling R21), so that a reviewer running Trivy or `npm audit` on the submitted
  commit sees a clean result.

## Automated review output

Scope of PR #14 as first reviewed (`47eb261..3bf9c72`: `813d784` (a pre-squash SHA, not on main; curated as
`20aef37`) drop the npm CLI from the `api` image, `3bf9c72` (a pre-squash SHA, not on main; curated as `3178f14`)
override `lodash-es`; `Dockerfile`, `e2e/todos.spec.ts`, `package.json`, plus a 6-line `package-lock.json` bump),
then the fix round (`3bf9c72..3178f14`, a range-diff of one `Dockerfile` hunk); the curated branch merged in
`de70329`. Reviewed against the scan evidence,
the fix implementer's report (Trivy re-scan, `npm ls`/`npm audit`, diagram render check, RED/GREEN e2e, gate) and
the merged tree at `de70329`.

**F-56 — `api` image ships the base image's global npm (7 HIGH CVEs)**
- In the `api` stage, before `USER node`, one `RUN rm -rf` removes `/usr/local/bin/{npm,npx,corepack,yarn,yarnpkg}`,
  `/usr/local/lib/node_modules/{npm,corepack}` and `/opt/yarn-v*`. The paths were located by inspecting the
  unmodified `node:24.21-alpine` first, not guessed.
- Safe for the runtime: `CMD ["node", "apps/api/dist/server.js"]` never calls npm, and the `migrate` stage
  (`FROM api`) runs `node_modules/.bin/node-pg-migrate` directly. The `base`/`deps`/`test`/build stages keep npm,
  which they need. Placement after the last `COPY` and before `USER node` is correct (the removal needs root).
- Evidence: Trivy on the rebuilt image went from 7 HIGH to 0, with no `node_modules/npm` scan target left.

**F-60 — `lodash-es` ≤ 4.17.23 via `mermaid` (2 HIGH advisories)**
- Root `package.json` gains `"overrides": { "lodash-es": "4.18.1" }`. `mermaid@12.0.0` (the latest) pins
  `chevrotain@~11.1.2`, which pins `lodash-es@4.17.23` exactly, so no upstream upgrade path existed;
  `npm audit fix --force` would have downgraded `mermaid`. The lockfile change is the minimal version/resolved/
  integrity bump for `node_modules/lodash-es`; `npm ls lodash-es` shows only 4.18.1; `npm audit --omit=dev
  --audit-level=high` → 0.
- Behaviour guard: a throwaway Playwright pass rendered all 19 diagrams across the portal as real SVGs (flowchart,
  sequence, state, ER). The e2e journey `the developer portal renders the docs with diagrams` was strengthened from
  `.first()` to `toHaveCount(3)` plus a visible `<svg>` in each, with a RED shown: forcing one Concurrency diagram to
  fail gave `Expected: 3, Received: 2`; reverted, GREEN 9/9.

**Review findings (pre-merge)**
- **Important** — the `rm -rf` of hard-coded paths cannot fail: if a future base-image patch moves npm, corepack or
  yarn, the layer silently removes nothing and F-56's CVEs come back with nothing failing, since CI has no Trivy
  step. Ruled a fix (Ruling R22): the same `RUN` layer now ends with
  `&& ! command -v npm && ! command -v npx && ! command -v corepack && ! command -v yarn && ! command -v yarnpkg`.
  RED: with corepack left out of the `rm` list, `docker build --target api` failed at that step
  (`/usr/local/bin/corepack`, exit 1); GREEN: full list, build exit 0; `migrate` target builds; compose stack healthy.
  Landed as a `--fixup` squashed into the first commit (now `20aef37`). Confirmed in the merged tree:
  `Dockerfile:61-62` at `de70329`. → F-61.
- **Minor** — the strengthened e2e assertion expects exactly 3 diagrams on the Concurrency tab, which couples the
  test to `docs/concurrency.md`'s current content. → F-62.
- **Minor** — the PR body says the lockfile was "regenerated through the Docker dev shell" but not that a plain
  `npm install` was a no-op and `npm update lodash-es` is what rewrote `package-lock.json` (the implementer's report
  records it as a deviation). Likewise, neither the PR body nor `20aef37`'s message mentions the build-time assertion
  added in the fix round. → F-63.

**Verification**
- Gate (`docker compose --profile test run --rm --build test`): 57 files / 417 tests, 100 % coverage, on each commit
  and again on the rebased head. e2e 9/9 (the Dockerfile-only fix round did not touch web or e2e code).
- PR CI green on the final head `3178f14` (run [36931661664](https://github.com/charlesmalo/FociToDo/actions/runs/36931661664):
  test, e2e, images) and on the merge commit `de70329` (run [36934017792](https://github.com/charlesmalo/FociToDo/actions/runs/36934017792)).
- Re-confirmed independently by this repository's scans of `de70329`: Trivy 0 HIGH/CRITICAL on both app images,
  `npm audit` 0 (see `signoff.md` → Evidence).

## Triage

| Finding | Severity | Category | Decision | Reason |
|---|---|---|---|---|
| F-56 `api` image carried the base image's unused global npm CLI with 7 fixed HIGH CVEs | High | security | Fix | Fixed by this PR (merged `de70329`); Trivy 0 HIGH/CRITICAL on the rebuilt image |
| F-60 `lodash-es` ≤ 4.17.23 via `mermaid` → `chevrotain`, 2 HIGH advisories | High | security | Fix | Fixed by this PR (merged `de70329`); override to 4.18.1, `npm audit` 0, diagrams guarded by e2e |
| F-61 `rm -rf` of hard-coded paths silently no-ops if the base image moves npm/corepack/yarn, re-shipping the CVEs with nothing failing | Important | security | Fix | Fixed in this PR's fix round (Ruling R22): `! command -v …` build assertion in the same layer, RED/GREEN shown; merged `de70329` |
| F-62 e2e expects exactly 3 diagrams on the Concurrency tab, coupling it to `docs/concurrency.md` | Minor | tests | Accept | Deliberate: the exact count is what catches a partial render fallback that `.first()` missed. The coupling is commented at the assertion, and a doc change that adds or removes a diagram fails e2e loudly rather than passing silently |
| F-63 PR description omits that `npm update lodash-es` (not `npm install`) regenerated the lockfile, and that the fix round added a build-time assertion | Minor | docs | Accept | Description only: the committed lockfile and Dockerfile are correct and verified (single `lodash-es` 4.18.1, `npm audit` 0, assertion present at `de70329`). The PR is merged; the detail is recorded here and in the findings log rather than by editing history |

## Checklist

Copy of `checklists/milestone-review.md` with results for PR #14:

### Correctness
- [x] Behaviour matches the spec sections the PR claims (status codes, headers, validation messages) — no API
  behaviour changed; the `api` container still starts and goes healthy, `migrate` exits 0, and all portal diagrams
  still render.
- [~] Error precedence 400 → 428 → 404 → 412 preserved — N/A; no API code changed.
- [x] No silent catch-alls; unexpected errors become logged 500s — N/A for the code paths touched; the fix round
  replaced a silent no-op (`rm -rf` of a missing path) with a loud build failure.

### Concurrency
- [x] Every write is a single statement or inside the unit of work — N/A; no write path changed.
- [x] Version bumps only on real changes; conditional writes use the version — N/A; unchanged.
- [x] New code paths covered by an invariant test if they touch shared state — N/A; no shared state.

### Tests
- [x] Test written first (visible in the commit) and mirrors the source path — the strengthened e2e assertion was
  shown RED (forced diagram failure) before GREEN; the build assertion was shown RED/GREEN with `docker build`.
- [x] 100% coverage without `v8 ignore` — gate at 100/100/100/100 on every commit; no exclusion added.
- [x] Assertions check behaviour, not implementation details or timings — the e2e asserts rendered SVGs by role;
  see F-62 for the accepted coupling to the doc's diagram count.

### Architecture
- [x] Layer rules respected (lint passes); composition only in `app.ts` — unaffected; lint green.
- [x] No new dependency without a reason in the commit or an ADR — no new dependency; the override pins an existing
  transitive one to its patched release, with the reason in the commit and PR.

### Docs
- [x] README / guides / OpenAPI still accurate (no drift) — no doc describes the runtime image's npm contents or an
  override policy; the Dockerfile comment explains why npm is removed. PR-description gaps are F-63.
- [x] New decisions recorded as ADRs — none needed; a dependency pin and an image trim, not architecture.

### Security & operability
- [x] Inputs validated with shared schemas; no secrets or stack traces in responses — unaffected.
- [x] Images non-root; no dev dependencies in runtime images — strengthened: the `api`/`migrate` images now carry no
  package manager at all, still run as `node`.

**Verdict: clean after one fix round.** Both HIGH scan findings are fixed at the root and re-scanned clean; the one
Important review finding (silent no-op removal) was fixed with a build-time assertion and RED/GREEN evidence before
merge; two Minor findings are accepted with reasons. Approved to merge; merged as `de70329`, the release candidate.
