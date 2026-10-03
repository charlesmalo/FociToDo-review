# Review — PR #21: fix(web): patch pcre2 in the web image (CVE-2026-103111)

- App commit range: `5c43da9..153d719` (one commit, `397d3fd`; merged as `153d7193d8170d1f8658ab4a047fcc34a7b6c711`) · PR: https://github.com/charlesmalo/FociToDo/pull/21 · Date: 2026-10-03 · Reviewer: Claude Code (automated) + solution-lead triage
- Origin: not a planned PR. This review repository's **scans** run against `5c43da9` found Trivy reporting `pcre2 10.48-r0` (CVE-2026-103111, HIGH) in the unmodified upstream `nginxinc/nginx-unprivileged:1.31-alpine` base image — a freshly pulled copy of the same floating tag still shipped the unpatched package while Alpine's own repo already had the fix (`10.49-r0`). Recorded as **F-98** (Controller ruling R50: fixable, so fixed in the app rather than only accepted as a risk).

## Automated review output

Scope of PR #21 (one commit, `397d3fd`; `Dockerfile`'s `web` stage only, 6 insertions).

**The change** (`Dockerfile`, `web` stage, between `FROM nginxinc/nginx-unprivileged:1.31-alpine AS web` and the existing `COPY`s):
```
USER root
RUN apk upgrade --no-cache pcre2 \
  && apk list -I pcre2 | grep -Eq '^pcre2-10\.(49|[5-9][0-9])-'
USER 101
```
- `apk upgrade --no-cache pcre2` pulls Alpine's own patched package rather than vendoring a fix or switching base images.
- The `grep -Eq` check makes the build fail if the installed version isn't actually ≥ 10.49 — not merely that `apk upgrade` exited 0 (which it would even if no newer package existed to upgrade to). This closes exactly the kind of silent-no-op gap already on record for the `api` stage's npm-removal self-check (F-61, PR #14): a future repin of the base image that already carries a fixed `pcre2` would still pass (nothing to upgrade, check still true), while a base image that regresses to an *older* unpatched version would fail loudly.
- `USER root` / `USER 101` bracket only the `apk` layer; the image still ends on the base image's unprivileged numeric user (`101`, the same user Task 4's NFR-8 citation confirmed via `whoami`/`id` before this PR).

**Verification (independently re-read, not trusted on the report's word)**:
- **RED**: the version check (`apk list -I pcre2 | grep -Eq '^pcre2-10\.(49|[5-9][0-9])-'`) exits 1 against the unpatched base (`pcre2-10.48-r0`) — a real negative-path proof, not an assumption. This matters because an early draft of this same check used `apk info -v pcre2`, which prints **no output** for an installed package on this Alpine base (it's the wrong subcommand for a single installed package's version), so a naive `grep` against that output would silently pass whether or not the upgrade did anything — a vacuous assertion. The final version uses `apk list -I pcre2` (which does print the installed version line) and was proven RED against the unpatched image before being trusted as the gate.
- **GREEN**: with the fix, `apk list -I pcre2` reports `pcre2-10.49-r0`; Trivy **0** HIGH/CRITICAL on the web image (was 1); image user still `101`; the built stack is healthy (`/` and `/api/health` both 200).
- Full gate: 459 tests, 100% coverage; e2e 8/8 — unchanged in count (an image-layer fix, no test-affecting source change).
- **Independent re-confirmation by this review's own scans run on the merged commit `153d719`** (this fix round): Trivy `review-scan-web` 0 HIGH/CRITICAL — [`evidence/2026-10-03T093820Z/scans/trivy-review-scan-web.txt`](../evidence/2026-10-03T093820Z/scans/trivy-review-scan-web.txt); re-ran the full acceptance (99/99 PASS, `evidence/2026-10-03T094027Z/acceptance/`), storyboard (22 frames/11 journeys/13 wireframes, `evidence/2026-10-03T094100Z/storyboard/`) and verify (`evidence/2026-10-03T093902Z/`) suite too, all green.

**No new findings beyond F-98's resolution.** The fix is minimal, targets the actual unpatched package rather than a broader base-image swap, and — notably — its own review process caught and corrected a vacuous-assertion draft before merge, which is exactly the discipline this review repository's own findings log has flagged missing elsewhere (e.g. F-61).

## Findings

| Finding | Severity | Category | Decision | Reason |
|---|---|---|---|---|
| F-98 Trivy found `pcre2@10.48-r0` (CVE-2026-103111, HIGH) in the unmodified upstream `nginxinc/nginx-unprivileged:1.31-alpine` web base image | High | security | Fix | Fixed by this PR (merged `153d7193d8170d1f8658ab4a047fcc34a7b6c711`) — `apk upgrade --no-cache pcre2` plus a positive, RED-proven version-floor check (`apk list -I`, not the vacuous `apk info -v`) that fails the build unless pcre2 ≥ 10.49 is actually installed; `USER root`/`USER 101` brackets only that layer. RED 1 HIGH → GREEN 0 HIGH/CRITICAL; re-confirmed by this review's own scans run at `153d719` |

## CI

- PR CI, head commit `397d3fd` (run [37113387792](https://github.com/charlesmalo/FociToDo/actions/runs/37113387792)): green, 4/4 jobs — test, images, diagrams, e2e.
- Main CI on the merge commit `153d719` (run [37113543211](https://github.com/charlesmalo/FociToDo/actions/runs/37113543211)): green, 4/4 jobs.

## Checklist

Copy of `checklists/milestone-review.md` with results for PR #21:

### Correctness
- [x] Behaviour matches the spec sections the PR claims (status codes, headers, validation messages) — N/A, a base-image package patch; no API/web HTTP behaviour changed, confirmed by this review's own acceptance (99/99) and storyboard (22/11/13) re-runs at `153d719`.
- [~] Error precedence 400 → 428 → 404 → 412 preserved — N/A; no API code changed.
- [x] No silent catch-alls; unexpected errors become logged 500s — the build-time version-floor check is itself the point: it fails loudly (non-zero exit) rather than silently accepting a no-op `apk upgrade`, and was proven to actually fail (RED) before being trusted.

### Concurrency
- [x] Every write is a single statement or inside the unit of work — N/A; no shared mutable state, no write path touched.
- [x] Version bumps only on real changes; conditional writes use the version — N/A.
- [x] New code paths covered by an invariant test if they touch shared state — N/A; no shared state. This review's stress evidence from `5c43da9` stands unchanged (a web-image-only package patch cannot affect API/Postgres concurrency behaviour) — see `signoff.md`.

### Tests
- [~] Test written first (visible in the commit) and mirrors the source path — N/A for a Dockerfile layer (no unit-test layer); the RED/GREEN build-time check is the equivalent evidence, and the PR's own review caught a vacuous first draft (`apk info -v`, no output) before accepting the final, RED-proven `apk list -I` check.
- [x] 100% coverage without `v8 ignore` — gate re-run at 100% (459 tests); no source or exclusion changed.
- [x] Assertions check behaviour, not implementation details or timings — the check asserts the actual installed version string, not that a command merely ran.

### Architecture
- [x] Layer rules respected (lint passes); composition only in `app.ts` — unaffected; lint green.
- [x] No new dependency without a reason in the commit or an ADR — no new dependency; upgrades an existing transitive OS package already present in the base image, with the CVE as the documented reason.

### Docs
- [x] README / guides / OpenAPI still accurate (no drift) — N/A; no documented behaviour changed.
- [x] New decisions recorded as ADRs — none needed; a security patch, not an architectural decision.

### Security & operability
- [x] Inputs validated with shared schemas; no secrets or stack traces in responses — unaffected.
- [x] Images non-root; no dev dependencies in runtime images — preserved: the `USER root`/`USER 101` bracket is scoped to one `RUN` layer only, and the final image still runs as the base image's unprivileged numeric user `101`.

**Verdict: clean.** A correctly targeted, RED/GREEN-proven fix for a real upstream CVE that this review's own scans found, with the review process itself catching and fixing a vacuous first-draft assertion before merge — and independently re-confirmed by this review's own scans run on the final merged commit.
