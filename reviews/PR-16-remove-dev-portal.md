# Review — PR #16: remove the `/dev` developer portal

- App commit range: `c39af72..141356a` (four commits: `c154594` docs(spec), `6af5d2a` docs(plan), `4af86bd` refactor(web), `dc0ae17` docs(decisions)) · PR: https://github.com/charlesmalo/FociToDo/pull/16 · Date: 2026-10-02 · Reviewer: Claude Code (automated) + solution-lead triage
- Origin: spec [`2026-10-02-docs-diagrams-design.md`](https://github.com/charlesmalo/FociToDo/blob/41a279aeb13ed7aa677fa8248db7b33f9bcf98c7/docs/superpowers/specs/2026-10-02-docs-diagrams-design.md) §3 (ADR 0015: the `/dev` portal duplicates what GitHub already renders, and ships development material — `mermaid`, `react-markdown`, `remark-gfm`, a `lodash-es` override — in the production web image).

## What changed

`4af86bd` deletes `apps/web/src/dev/` and its tests (24 files, 767 lines), removes the lazy-loaded `/dev` route and path check from `App.tsx` (no more client-side path routing — the web app renders only the to-do page), drops the header "Developer" link from `TodoPage.tsx`, removes `mermaid`/`react-markdown`/`remark-gfm` from `apps/web/package.json` and the root `lodash-es` override (212 now-unused transitive lockfile packages removed), removes the build-info plumbing used only by the portal (`vite.config.ts`'s `__APP_VERSION__`/`__GIT_SHA__`/`__BUILD_DATE__` `define`s and `vite-env.d.ts` declarations), and removes the ESLint `web/todos` ⇄ `web/dev` import-boundary zone from `eslint.config.js`. The e2e journey `'the developer portal renders the docs with diagrams'` is removed (8 journeys remain; diagram validity moves to PR #17's gate check and CI job). `README.md` drops the `/dev` row from the URL table. `dc0ae17` adds ADR 0015 and marks ADR 0011 "Superseded by 0015".

## Automated review output

**Task 1 (`4af86bd` refactor(web))** — gate 371/371, 100% coverage; e2e 8/8; `npm ls lodash-es mermaid react-markdown remark-gfm` → empty; `npm audit` → 0; `curl /dev` → 200 (SPA fallback, no special route — the path is no longer intercepted, so the to-do app renders instead of the removed portal, not a 404). Spec match confirmed against the actual diff (`eslint.config.js`'s two `web/dev` zone entries gone, `App.tsx`'s `isDevPath`/lazy import gone, `vite.config.ts`'s build-info `define` gone). **Review: Approved, no findings.**

**Task 2 (`dc0ae17` docs(decisions))** — review **Needs fixes**:
- The original 2026-09-30 design spec's body still presented the `/dev` portal as current, even after ADR 0015 decided its removal.
- The commit lacked a Conventional Commits scope (a defect in the plan template, not the implementer).
- Minor, deferred: the pre-existing 2026-09-30 plan files still describe `/dev` in present/building tense — left as historical record of the plan as originally written.

**Final whole-branch review (opus)** — no Critical/Important findings. Minors: spec §2.3's example table had live broken links (fenced instead); a commit body overstated the extent of the screenshot change (reworded); the web test suite's URL restore ran outside `afterEach` (moved in); one intermediate (pre-squash) commit shows the README's `/dev` row present for one commit in the branch history (no action — the squashed, merged history is correct); a single-child `.actions` wrapper element left behind by the cleanup is unnecessary markup (no action, cosmetic).

## Findings

| Finding | Severity | Category | Decision | Reason |
|---|---|---|---|---|
| F-68 Original 2026-09-30 spec body still presented the `/dev` portal as current after ADR 0015 decided its removal | Important | docs | Fix | Fixed by this PR (merged `141356a`) — Ruling R34: "Amended 2026-10-02" banner, §7.4 heading marked removed, ADR 0011 marked "(superseded by 0015)" on its summary line; original body kept as history |
| F-69 Commit `dc0ae17`'s original message lacked a Conventional Commits scope (a plan-template defect) | Important | docs | Fix | Fixed by this PR (merged `141356a`) — Ruling R35: reworded to `docs(decisions)`; plan subjects corrected to match |
| F-70 The pre-existing 2026-09-30 plan files still describe the `/dev` portal in present/building tense | Minor | docs | Accept | Accepted in this PR (merged `141356a`) — deliberately left as the historical record of the plan as written at the time |
| F-71 Spec §2.3's example table contained live broken links | Minor | docs | Fix | Fixed by this PR (merged `141356a`) — example fenced instead of rendered live |
| F-72 A commit body overstated the extent of the screenshot change | Minor | docs | Fix | Fixed by this PR (merged `141356a`) — commit message reworded to match the actual diff |
| F-73 The web test suite restored the mocked location/test URL outside an `afterEach`, risking leakage into a later test if an earlier one failed | Minor | tests | Fix | Fixed by this PR (merged `141356a`) — restore moved into `afterEach` |
| F-74 One intermediate (pre-squash) commit shows the README's `/dev` row still present for one commit in the branch history | Minor | docs | Accept | Accepted in this PR (merged `141356a`) — Ruling R36: no action; the squashed, merged history on `main` is correct, and intermediate commits are not the shipped artifact |
| F-75 A single-child `.actions` wrapper element left over from the portal-link removal is unnecessary markup | Minor | design | Accept | Accepted in this PR (merged `141356a`) — cosmetic, no behavioural effect |

## CI

- PR CI (run [36987783809](https://github.com/charlesmalo/FociToDo/actions/runs/36987783809)): green, 3/3 jobs — test, e2e, images (the `diagrams` job does not exist yet; it is added by PR #17).
- Main CI on the merge commit `141356a` (run [36988031776](https://github.com/charlesmalo/FociToDo/actions/runs/36988031776)): green, 3/3 jobs.

## Checklist

Copy of `checklists/milestone-review.md` with results for PR #16:

### Correctness
- [x] Behaviour matches the spec sections the PR claims (status codes, headers, validation messages) — no API behaviour changed; the web app now renders only the to-do page, confirmed by `curl /dev` → 200 (SPA fallback, no special route).
- [~] Error precedence 400 → 428 → 404 → 412 preserved — N/A; no API code changed.
- [x] No silent catch-alls; unexpected errors become logged 500s — N/A; no code path changed that could swallow an error.

### Concurrency
- [x] Every write is a single statement or inside the unit of work — N/A; no write path changed.
- [x] Version bumps only on real changes; conditional writes use the version — N/A; unchanged.
- [x] New code paths covered by an invariant test if they touch shared state — N/A; no shared state touched (pure deletion plus one route/link removal).

### Tests
- [x] Test written first (visible in the commit) and mirrors the source path — deletions mirror: every `apps/web/src/dev/*` file's test under `apps/web/tests/dev/` was removed in the same commit; `App.test.tsx`/`TodoPage.test.tsx` updated to match.
- [x] 100% coverage without `v8 ignore` — gate 371/371, 100/100/100/100, no new exclusion.
- [x] Assertions check behaviour, not implementation details or timings — e2e 8/8 unchanged in shape, one journey removed because its subject was removed.

### Architecture
- [x] Layer rules respected (lint passes); composition only in `app.ts` — the `web/todos` ⇄ `web/dev` zone is removed from `eslint.config.js` along with the code it guarded; lint green.
- [x] No new dependency without a reason in the commit or an ADR — three dependencies and one override *removed*, with the reason in ADR 0015.

### Docs
- [x] README / guides / OpenAPI still accurate (no drift) — the `/dev` row dropped from the README's URL table; `docs/images/screenshot.png` retaken without the "Developer" link.
- [x] New decisions recorded as ADRs — ADR 0015 added; ADR 0011 marked superseded.

### Security & operability
- [x] Inputs validated with shared schemas; no secrets or stack traces in responses — unaffected.
- [x] Images non-root; no dev dependencies in runtime images — the web image's dependency tree shrinks (three runtime packages and the `lodash-es` override gone; 212 transitive lockfile packages removed, `npm audit` 0).

**Verdict: clean after one fix round.** The two Important findings (stale spec content, a scopeless commit message) were both fixed before merge; six Minors are either fixed or explicitly accepted with a reason. Approved to merge; merged as `141356a`. Note: `findings/log.md`'s F-60 (`lodash-es` via `mermaid`, fixed in PR #14) has its root cause — the `mermaid`/`lodash-es` dependency itself — removed entirely by this PR; its Decision and history are unchanged, a note is added to the row.
