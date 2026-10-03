# Release readiness checklist — FociToDo @ 5c43da9

Filled copy of [`release-readiness.md`](release-readiness.md) for the new release candidate
`5c43da9c1490a28e17daf8842e0e01958b737ad1` (PR #20's merge, the commit after PR #18 "UI wireframes", PR #19 "fix:
nginx re-resolves the api" and PR #20 "fix: filter labels") · Date: 2026-10-03. Every box links the evidence it
rests on; every harness run below records the checked-out SHA in its `summary.md`.

- [x] `verify` passes from a clean clone of the release commit (arm64 locally; amd64 in CI) — arm64:
  [`evidence/2026-10-03T090528Z/summary.md`](../evidence/2026-10-03T090528Z/summary.md) (fresh clone at `5c43da9`,
  `--no-cache` rebuild → healthy in 26 s, test gate PASS, e2e PASS). amd64: the app's CI on `main` at `5c43da9` runs
  the same test, images, diagrams and e2e jobs on `ubuntu-latest` — green, 4/4 —
  https://github.com/charlesmalo/FociToDo/actions/runs/37111402420.
- [x] Test gate green with 100% coverage; e2e green —
  [`test-gate.log`](../evidence/2026-10-03T090528Z/test-gate.log) (59 test files, 459 tests),
  [`coverage-summary.json`](../evidence/2026-10-03T090528Z/reports/coverage/coverage-summary.json) (lines 736/736,
  statements 827/827, functions 273/273, branches 386/386 — all 100%),
  [`e2e.log`](../evidence/2026-10-03T090528Z/e2e.log) (8 passed — unchanged in scope from the `41a279a` sign-off).
- [x] All stress invariants hold; no 5xx under load —
  [`evidence/2026-10-03T090659Z/stress/summary.md`](../evidence/2026-10-03T090659Z/stress/summary.md): 5/5 scenarios
  PASS, 13/13 invariants PASS (`*.invariants.txt`). `http_req_failed` is 0.00% in every scenario's k6 log
  (`*.log`; 545,176 requests in total: 218,981 + 410 + 620 + 800 + 324,365), and no scenario lists a 5xx as an
  expected status, so no request returned 5xx.
- [x] No critical/high vulnerabilities without an accepted, documented reason —
  [`evidence/2026-10-03T091041Z/scans/`](../evidence/2026-10-03T091041Z/scans/): Trivy 0 HIGH/CRITICAL on `api`;
  `npm audit --omit=dev --audit-level=high` 0. Two accepted, documented exceptions, both unmodified upstream base
  images: `postgres:17.11-alpine` still has 22 (1 CRITICAL, 21 HIGH) Go stdlib CVEs in its `gosu` binary, unchanged
  since the de70329 sign-off ([F-64, F-65](../findings/log.md)); `nginxinc/nginx-unprivileged:1.31-alpine`'s Alpine
  base now carries one new HIGH `pcre2` CVE (CVE-2026-103111), not present at the `41a279a` sign-off — accepted as
  [F-98](../findings/log.md) (the app's own `nginx.conf` defines no regex `location` blocks, so this app does not
  exercise PCRE on untrusted input).
- [x] Hadolint clean or findings accepted —
  [`hadolint-Dockerfile.txt`](../evidence/2026-10-03T091041Z/scans/hadolint-Dockerfile.txt): 3 style findings
  (DL3066 ×1 at line 69, DL3025 ×2 at lines 71 and 85 — unchanged from the `41a279a` sign-off, the Dockerfile was
  not touched by PR #18–#20), accepted as [F-57, F-58, F-59](../findings/log.md).
- [x] Traceability matrix: every requirement implemented and verified —
  [`traceability/matrix.md`](../traceability/matrix.md): 40 rows (FR-1–FR-10, DR-1–DR-8, NFR-0–NFR-10, DOC-1,
  DOC-2, D-1–D-9) — one new row, DOC-2 (every UI screen state has a wireframe, PR #18), since the `41a279a`
  sign-off. FR-10 reads **Removed** (ADR 0015, PR #16) by deliberate design decision, not an open gap; every other
  row reads `Done`. The matrix now also carries an **Independent acceptance** column citing this review's own
  expectation-catalogue IDs and storyboard journeys (or an explicit "not observable from outside" reason) for every
  row, alongside the unchanged app-test citation column.
- [x] Findings log: no open High findings —
  [`findings/log.md`](../findings/log.md): every Critical/High finding is either fixed and merged (carried forward:
  F-50→`a3d1af3`, F-55→`47eb261`, F-56/F-60→`de70329`/`141356a`; new this cycle: F-91, the BR-20 nginx
  stale-upstream defect independently found by this review's acceptance harness, fixed in PR #19→`3b76cfa`) or
  accepted with a documented reason (F-64/F-65: upstream postgres image; F-98: upstream nginx-unprivileged image,
  new this cycle — both bump-the-pin-when-patched).
- [ ] README quick start followed verbatim on a clean machine — **not met as worded**, unchanged from the `41a279a`
  sign-off. The quick start's build-and-run path was exercised from a fresh clone by `verify`
  (`compose build --no-cache --pull`, then `compose up -d` → healthy) on a machine whose base images and npm cache
  were already warm — see the timing label in
  [`summary.md`](../evidence/2026-10-03T090528Z/summary.md): "Clean-clone rebuild → healthy: 26 s (arm64; base
  images and npm cache warm)". Docker images and build cache were deliberately not pruned: that would wipe the
  machine owner's Docker state. The nearest clean-machine evidence is the app's CI on fresh `ubuntu-latest`
  runners, green on `5c43da9` (run 37111402420), though through CI's own jobs rather than the README's literal
  `docker compose up --build -d`.
