# Release readiness checklist — FociToDo @ 153d719

Filled copy of [`release-readiness.md`](release-readiness.md) for the new release candidate
`153d7193d8170d1f8658ab4a047fcc34a7b6c711` (PR #21's merge, the commit after PR #18 "UI wireframes", PR #19 "fix:
nginx re-resolves the api", PR #20 "fix: filter labels" and PR #21 "fix: pcre2 in the web image") · Date: 2026-10-03.
Every box links the evidence it rests on; every harness run below records the checked-out SHA in its `summary.md`.

- [x] `verify` passes from a clean clone of the release commit (arm64 locally; amd64 in CI) — arm64:
  [`evidence/2026-10-03T093902Z/summary.md`](../evidence/2026-10-03T093902Z/summary.md) (fresh clone at `153d719`,
  `--no-cache` rebuild → healthy in 27 s, test gate PASS, e2e PASS). amd64: the app's CI on `main` at `153d719` runs
  the same test, images, diagrams and e2e jobs on `ubuntu-latest` — green, 4/4 —
  https://github.com/charlesmalo/FociToDo/actions/runs/37113543211.
- [x] Test gate green with 100% coverage; e2e green —
  [`test-gate.log`](../evidence/2026-10-03T093902Z/test-gate.log) (59 test files, 459 tests),
  [`coverage-summary.json`](../evidence/2026-10-03T093902Z/reports/coverage/coverage-summary.json) (lines 736/736,
  statements 827/827, functions 273/273, branches 386/386 — all 100%),
  [`e2e.log`](../evidence/2026-10-03T093902Z/e2e.log) (8 passed — unchanged in scope since the `41a279a` sign-off).
- [x] All stress invariants hold; no 5xx under load — **not re-run this round**: the only change since `5c43da9` is
  PR #21's one-layer `web`-image package patch, which touches no API, service, repository or nginx-routing code and
  cannot affect concurrency behaviour. The `5c43da9` stress evidence stands:
  [`evidence/2026-10-03T090659Z/stress/summary.md`](../evidence/2026-10-03T090659Z/stress/summary.md) — 5/5
  scenarios PASS, 13/13 invariants PASS (`*.invariants.txt`). `http_req_failed` is 0.00% in every scenario's k6 log
  (545,176 requests in total: 218,981 + 410 + 620 + 800 + 324,365), and no scenario lists a 5xx as an expected
  status, so no request returned 5xx.
- [x] No critical/high vulnerabilities without an accepted, documented reason —
  [`evidence/2026-10-03T093820Z/scans/`](../evidence/2026-10-03T093820Z/scans/): Trivy **0 HIGH/CRITICAL on both
  `api` and `web`** now (PR #21 fixed F-98's `pcre2` CVE — was 1 HIGH on `web` at the `5c43da9` sign-off);
  `npm audit --omit=dev --audit-level=high` 0. One remaining accepted, documented exception, an unmodified upstream
  base image: `postgres:17.11-alpine` still has 22 (1 CRITICAL, 21 HIGH) Go stdlib CVEs in its `gosu` binary,
  unchanged since the de70329 sign-off ([F-64, F-65](../findings/log.md)).
- [x] Hadolint clean or findings accepted —
  [`hadolint-Dockerfile.txt`](../evidence/2026-10-03T093820Z/scans/hadolint-Dockerfile.txt): **5 style findings**
  (was 3) — the 3 pre-existing (DL3066 ×1 at line 69, DL3025 ×2 at lines 71 and 91, shifted by PR #21's +6 lines)
  accepted as [F-57, F-58, F-59](../findings/log.md), unchanged in substance; 2 new, both on PR #21's own
  pcre2-patch layer (DL3066 at line 84, its temporary `USER root`; DL4006 at line 85, the `apk … | grep` pipe with
  no `pipefail`), accepted as [F-99, F-100](../findings/log.md) — neither has a functional effect (the layer ends
  back on the numeric unprivileged user, and the pipe's own `grep -Eq` already fails the build on a missing match).
- [x] Traceability matrix: every requirement implemented and verified —
  [`traceability/matrix.md`](../traceability/matrix.md): 40 rows (FR-1–FR-10, DR-1–DR-8, NFR-0–NFR-10, DOC-1,
  DOC-2, D-1–D-9), unchanged in count since the `5c43da9` sign-off. FR-10 reads **Removed** (ADR 0015, PR #16) by
  deliberate design decision, not an open gap; every other row reads `Done`. NFR-8's citation now also names PR #21's
  `USER root`/`USER 101` bracket in the `web` stage. The matrix carries an **Independent acceptance** column citing
  this review's own expectation-catalogue IDs and storyboard journeys (or an explicit "not observable from outside"
  reason) for every row, alongside the unchanged app-test citation column.
- [x] Findings log: no open High findings —
  [`findings/log.md`](../findings/log.md): every Critical/High finding is either fixed and merged (carried forward:
  F-50→`a3d1af3`, F-55→`47eb261`, F-56/F-60→`de70329`/`141356a`; F-91, the BR-20 nginx stale-upstream defect, fixed
  in PR #19→`3b76cfa`; **F-98, the `web`-image `pcre2` CVE, now fixed in PR #21→`153d719`**, re-scanned 0
  HIGH/CRITICAL) or accepted with a documented reason (F-64/F-65: upstream postgres image, bump-the-pin-when-patched).
- [ ] README quick start followed verbatim on a clean machine — **not met as worded**, unchanged from earlier
  sign-offs. The quick start's build-and-run path was exercised from a fresh clone by `verify`
  (`compose build --no-cache --pull`, then `compose up -d` → healthy) on a machine whose base images and npm cache
  were already warm — see the timing label in
  [`summary.md`](../evidence/2026-10-03T093902Z/summary.md): "Clean-clone rebuild → healthy: 27 s (arm64; base
  images and npm cache warm)". Docker images and build cache were deliberately not pruned: that would wipe the
  machine owner's Docker state. The nearest clean-machine evidence is the app's CI on fresh `ubuntu-latest`
  runners, green on `153d719` (run 37113543211), though through CI's own jobs rather than the README's literal
  `docker compose up --build -d`.
