# Review — PR #11 feat(web): in-app developer portal

- App commit range: `e1de68a..dfd3835` · Date: 2026-10-01 · Reviewer: Claude Code (automated) + solution-lead triage

## Automated review output

Scope of PR #11 (two commits: `6dab2af` document library/routing, `dfd3835` Markdown+Mermaid rendering, the
portal page and app routing; confirmed via `review-e1de68a..dfd3835.diff`, 31 non-lockfile files changed —
`package-lock.json` skimmed only). Reviewed against spec §7.4 (`/dev` portal), §14 A7 (Overview renders the
whole README), FR-10, and the implementer's task-2 report (gate/e2e/headless-SVG evidence).

**Correctness of the implementation itself (independently verified against the real source, not trusted on the
implementer's word)**
- `apps/web/src/dev/routes.ts`/`links.ts`/`docs.ts` (Task 1) match the brief's interfaces exactly;
  `routeFromHash`'s malformed-percent-encoding catch branch and decision-record regex are both exercised by
  `apps/web/tests/dev/routes.test.ts`.
- `DevPortal.tsx` renders all six tabs from `TABS`, the build-info line, the back-to-app link, the API-explorer
  callout gated on `route.tab === 'api'`, the "← All decisions" link gated on
  `route.tab === 'decisions' && route.path !== DECISIONS_INDEX`, and a "Document not found." alert for an
  unmapped hash — all match `apps/web/tests/dev/DevPortal.test.tsx`'s five cases.
- `DocView.tsx` wires `react-markdown` + `remark-gfm`, rewrites `a`/`img` through `linkTarget`/`library.assetUrl`,
  and routes ` ```mermaid ` fences to `MermaidBlock` — matches spec §7.4's rendering line.
- `MermaidBlock.tsx` has a correct unmount guard (`active` flag checked before both `setSvg`/`setFailed`),
  verified by its own "ignores results that arrive after unmount" test; `renderMermaid` (`mermaid.ts`) is a
  dynamic `import('mermaid')` (confirmed separate-chunk claim) with `securityLevel: 'strict'` (sanitised SVG).
- `App.tsx`'s `isDevPath`/lazy `DevPortal`/`Suspense` wiring is correct; `apps/web/nginx.conf`'s SPA fallback
  (`try_files $uri /index.html`) serves `/dev` — matches the implementer's own `curl` 200 evidence and this
  review's reading of the config (not re-run, since the report's evidence is itself verifiable against the
  config as committed).
- Build info: `vite.config.ts`'s `define` block reads `process.env.{APP_VERSION,GIT_SHA,BUILD_DATE}`;
  `Dockerfile`'s `build-web` stage declares the matching `ARG`s/`ENV`s; `compose.yaml`'s `web.build.args` passes
  `GIT_SHA`/`BUILD_DATE` (not `APP_VERSION`, which keeps the Dockerfile's `1.0.0` default — consistent, no drift
  found). `README.md`'s Quick-start table gained the `/dev` row.
- A7 re-verified directly: `README.md` has a "How this was built" `##` section (line 99) that the bundled
  Overview tab renders in full, per `TABS[0] = { path: 'README.md' }` — not a partial/curated excerpt.
- `eslint.config.js`'s pre-existing `import-x/no-restricted-paths` zones (`apps/web/src/todos` ↔
  `apps/web/src/dev`, both directions) were already in place before this PR and are not violated by any new
  import in `dev/*` or `TodoPage.tsx`.
- Coverage: no new `coverage.exclude` entries added for `apps/web/src/dev/*` (`vitest.config.ts`'s exclude list
  is unchanged: `apps/api/src/server.ts`, `apps/web/src/main.tsx`, `**/*.d.ts`); `vite-env.d.ts` (the only new
  `.d.ts`) is already covered by the existing `**/*.d.ts` exclusion, so the reported 100% figure is not inflated
  by a new carve-out.
- `e2e/todos.spec.ts`'s new "the developer portal renders the docs with diagrams" test matches the implementer's
  report verbatim, including the documented nav-scoping deviation (below).

**Already raised at the per-task level (not re-litigated, recorded below per the controller's pre-triage):**
- MermaidBlock keeps stale `svg`/`failed` state when reused across tab switches — confirmed in code:
  `DevPortal.tsx` renders `<DocView page={page} library={library} />` with no `key` prop, so React reuses the
  same `MermaidBlock` instances across a hash change that keeps the same component position; the `useEffect`
  dependency is `[code, render]`, not `page.path`, so a page with no mermaid fences (or fewer than before) can
  leave a previous diagram's resolved `svg`/`failed` state briefly visible. Deferred: final fix — key `DocView`
  by `page.path`.
- CI `images` job lacks `BUILD_DATE`: confirmed in `.github/workflows/ci.yml` — the `images` job's new `env:`
  block sets `GIT_SHA` but not `BUILD_DATE`, so `docker compose build migrate api web` in CI falls back to the
  Dockerfile's `BUILD_DATE=unknown` default and the header would show "built unknown" in that build. Deferred:
  final fix.
- In-page `#anchors` would route to Overview (latent, none present today) — confirmed: `linkTarget` treats any
  `href` starting with `#` as `isExternalOrAppLink` and returns it unchanged; `routeFromHash` falls back to
  `TABS[0]` (Overview) for any hash it doesn't recognise as a tab id or `decisions/<id>`. No in-page anchor
  exists in the current docs set, so this is latent. Low/Accept.
- A directory link becomes a GitHub blob URL (redirects) — confirmed: `linkTarget` falls through to
  `${REPO_URL}${path}` with `REPO_URL = '.../blob/main/'`, which for a directory path lands on a `blob/main/dir`
  URL that GitHub 302-redirects to its `tree` view. Low/Accept.
- `<nav>` wraps the "+ New task" button — confirmed in `TodoPage.tsx`: `<nav className={styles.actions}>` now
  wraps both the create button and the new "Developer" link, so a non-navigational action sits inside a `<nav>`
  landmark. Low/Accept.
- The e2e "Concurrency" link was scoped to the Documentation nav — confirmed necessary and correctly scoped:
  the rendered README's own "More: … [concurrency](docs/concurrency.md) …" inline link and the portal's nav tab
  both resolve to an accessible name "Concurrency" with `href="#concurrency"`; Playwright's case-insensitive
  accessible-name match hit both. `getByRole('navigation', { name: 'Documentation' })` scoping is a legitimate,
  behavior-preserving fix for a real two-match ambiguity introduced by PR #10's content, not a weakening of the
  assertion. Low/Accept (legitimate).

**No new Critical or Important findings from this review's own pass.** One new Low observation, not previously
recorded:
- `compose.yaml`'s `web.build.args` passes `GIT_SHA`/`BUILD_DATE` but not `APP_VERSION`, so a local
  `docker compose up --build` always shows `v1.0.0` (the Dockerfile default) regardless of the checked-out
  `package.json` version. Not a functional defect (no version-skew risk today — nothing reads `package.json`'s
  version for this), but worth folding into the same final-fix pass as the two other build-info items above if
  `APP_VERSION` is ever meant to track the package version.

## Triage

| Finding | Severity | Category | Decision | Reason |
|---|---|---|---|---|
| F-43 `DevPortal` renders `DocView` without keying it by `page.path`, so `MermaidBlock` can show a stale previous diagram/fallback briefly after a tab switch | Low | correctness | Accept | Deferred to final fix wave (key `DocView` by `page.path`); already raised at the per-task level |
| F-44 CI `images` job's `env:` sets `GIT_SHA` but not `BUILD_DATE`, so images built by that job show "built unknown" | Low | operability | Accept | Deferred to final fix wave; already raised at the per-task level |
| F-45 In-page `#anchor` Markdown links route to the Overview tab instead of scrolling within the current doc (no such anchor exists in the current doc set) | Low | correctness | Accept | Latent, no current impact; already raised at the per-task level |
| F-46 A Markdown link to a repository directory resolves to a GitHub `blob/main/<dir>` URL, which GitHub redirects to its tree view | Low | design | Accept | Cosmetic (one redirect hop); already raised at the per-task level |
| F-47 `TodoPage.tsx`'s `<nav>` wraps the non-navigational "+ New task" button alongside the new "Developer" link | Low | design | Accept | Minor landmark-semantics nit; already raised at the per-task level |
| F-48 `e2e/todos.spec.ts`'s Concurrency link locator is scoped to `getByRole('navigation', { name: 'Documentation' })` to resolve a strict-mode ambiguity against the README's own inline "concurrency" link | Low | tests | Accept | Legitimate, behavior-preserving fix for real PR #10 content; not a weakened assertion |
| F-49 `compose.yaml`'s `web.build.args` omits `APP_VERSION`, so local builds always show the Dockerfile's `1.0.0` default regardless of `package.json`'s version | Low | operability | Accept | No functional impact today; fold into the same final build-info fix pass as F-44 if `APP_VERSION` is ever meant to track the package version |

## Checklist

Copy of `checklists/milestone-review.md` with results for PR #11:

### Correctness
- [x] Behaviour matches the spec sections the PR claims (status codes, headers, validation messages) — §7.4's
  tabs, Markdown+Mermaid rendering, API-explorer link, hash-based tab state, link rewriting and build-info header
  are all present and match source; A7 (Overview = whole README) independently re-verified.
- [~] Error precedence 400 → 428 → 404 → 412 preserved — N/A; no API/server code changed by this PR.
- [x] No silent catch-alls; unexpected errors become logged 500s — N/A for new code; `MermaidBlock`'s render
  failure path is a deliberate, tested fallback-to-source (not a silent catch), not an API error path.

### Concurrency
- [x] Every write is a single statement or inside the unit of work — N/A; no write-path/shared-state code.
- [x] Version bumps only on real changes; conditional writes use the version — N/A; unchanged.
- [x] New code paths covered by an invariant test if they touch shared state — N/A; `MermaidBlock`'s only
  "shared" surface is the module-level `sequence` counter used purely for unique DOM ids, not shared mutable
  state with invariants to test.

### Tests
- [x] Test written first (visible in the commit) and mirrors the source path — TDD evidence in the task-2 report
  shows RED (4 + 6 failing files for the expected import/behaviour reasons) then GREEN; test files mirror
  `apps/web/src/dev/*` 1:1 under `apps/web/tests/dev/*`.
- [x] 100% coverage without `v8 ignore` — reported 405/405 tests, 100/100/100/100 "All files"; independently
  confirmed no new `coverage.exclude` entries were added for the new `dev/*` source (only the pre-existing,
  blanket `**/*.d.ts` exclusion applies to the one new `.d.ts` file); no `v8 ignore` comments found in the diff.
- [x] Assertions check behaviour, not implementation details or timings — `MermaidBlock.test.tsx` and
  `DevPortal.test.tsx` assert on rendered roles/text/attributes, not internal state or timers.

### Architecture
- [x] Layer rules respected (lint passes); composition only in `app.ts` — the pre-existing
  `apps/web/src/todos` ↔ `apps/web/src/dev` `no-restricted-paths` zones are not violated by any new import; no
  new composition-root-equivalent file was needed (`App.tsx`'s lazy-load branch is the existing composition
  point).
- [x] No new dependency without a reason in the commit or an ADR — `react-markdown`, `remark-gfm`, `mermaid` are
  exactly the three dependencies ADR 0011 (already recorded in PR #10) names for the `/dev` portal.

### Docs
- [x] README / guides / OpenAPI still accurate (no drift) — `README.md`'s Quick-start table now lists `/dev`;
  no OpenAPI surface touched by this PR.
- [x] New decisions recorded as ADRs — none needed; this PR builds the portal ADR 0011 already recorded, with no
  further undocumented decisions.

### Security & operability
- [x] Inputs validated with shared schemas; no secrets or stack traces in responses — N/A for this PR's surface;
  Mermaid SVG is rendered with `securityLevel: 'strict'` (sanitised) before `dangerouslySetInnerHTML`, and the
  only Markdown rendered is the repository's own committed docs, not user input.
- [x] Images non-root; no dev dependencies in runtime images — unaffected; `build-web`'s new `ARG`/`ENV` lines
  add no dependencies, and the final `web` image (built from `build-web`'s `dist/` output) is unchanged in this
  respect.

**Verdict: clean (findings, all Low/Accept, none new-Critical/Important).** PR #11 implements the `/dev` portal
exactly as spec'd in §7.4, correctly honours A7 (whole-README Overview), reuses ADR 0011's already-approved
dependency set, and ships with TDD evidence (RED/GREEN), a 100%-coverage full gate run, and a passing e2e journey
with a headless-SVG diagram-rendering check. All six items already raised at the per-task level were
independently reconfirmed against the actual diff/source; one additional Low observation (F-49, `APP_VERSION`
not passed through `compose.yaml`) was found and folded into the same deferred final-fix wave as the other two
build-info items (F-43, F-44). No Critical or Important findings.
