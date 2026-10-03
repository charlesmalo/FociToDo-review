# Release readiness checklist — FociToDo @ 3dbb2eb

Filled copy of [`release-readiness.md`](release-readiness.md) for the new release candidate
`3dbb2ebc374e2e783f1164e35b1104224cdd6033` (PR #23's merge, the commit after PR #22 "API docs as a local artifact, not
an endpoint" and PR #23 "deadlines as UTC instants with a due-soon flag") · Date: 2026-10-03.
Every box links the evidence it rests on; every harness run below records the checked-out SHA in its `summary.md`.

- [x] `verify` passes from a clean clone of the release commit (arm64 locally; amd64 in CI) — arm64:
  [`evidence/2026-10-03T215759Z/summary.md`](../evidence/2026-10-03T215759Z/summary.md) (fresh clone at `3dbb2eb`,
  `--no-cache` rebuild → healthy in 26 s, test gate PASS, e2e PASS). amd64: the app's CI on `main` at `3dbb2eb` runs
  the same test, images, diagrams and e2e jobs on `ubuntu-latest` — green, 4/4 —
  https://github.com/charlesmalo/FociToDo/actions/runs/37156200771.
- [x] Test gate green with 100% coverage; e2e green —
  [`test-gate.log`](../evidence/2026-10-03T215759Z/test-gate.log) (62 test files, 546 tests),
  [`coverage-summary.json`](../evidence/2026-10-03T215759Z/reports/coverage/coverage-summary.json) (lines 789/789,
  statements 893/893, functions 292/292, branches 452/452 — all 100%),
  [`e2e.log`](../evidence/2026-10-03T215759Z/e2e.log) (10 passed).
- [x] All stress invariants hold; no 5xx under load — re-run at `3dbb2eb` (the schema, the `dueAt` contract and the API's
  dependency tree changed):
  [`evidence/2026-10-03T215927Z/stress/summary.md`](../evidence/2026-10-03T215927Z/stress/summary.md) — 5/5
  scenarios PASS, 13/13 invariants PASS (`*.invariants.txt`). `http_req_failed` is 0.00% in every scenario's k6 log
  (516,769 requests in total: 211,469 + 410 + 620 + 800 + 303,470), and no scenario lists a 5xx as an expected
  status, so no request returned 5xx. The `mixed-load` scenario now sends `sort=dueAt` and a `dueAt` instant, so the
  load mix exercises the real contract; its p95 `GET /todos` latency is 10.35 ms against a threshold of 250 ms
  ([`mixed-load.json`](../evidence/2026-10-03T215927Z/stress/mixed-load.json)).
- [x] No critical/high vulnerabilities without an accepted, documented reason —
  [`evidence/2026-10-03T220217Z/scans/`](../evidence/2026-10-03T220217Z/scans/): Trivy **0 HIGH/CRITICAL on both
  `api` and `web`**; `npm audit --omit=dev --audit-level=high` 0. One remaining accepted, documented exception, an
  unmodified upstream base image: `postgres:17.11-alpine` still has 22 (1 CRITICAL, 21 HIGH) Go stdlib CVEs in its
  `gosu` binary, the same CVE set as at `153d719` ([F-64, F-65](../findings/log.md)).
- [x] Hadolint clean or findings accepted —
  [`hadolint-Dockerfile.txt`](../evidence/2026-10-03T220217Z/scans/hadolint-Dockerfile.txt): **5 style findings**,
  the same five as at `153d719` (DL3066 at lines 71 and 86, DL3025 at lines 73 and 93, DL4006 at line 87), with
  line numbers shifted by +2 and no new rule or new location in the Dockerfile; accepted as
  [F-57, F-58, F-59, F-99, F-100](../findings/log.md).
- [x] Traceability matrix: every requirement implemented and verified —
  [`traceability/matrix.md`](../traceability/matrix.md): 40 rows (FR-1–FR-10, DR-1–DR-8, NFR-0–NFR-10, DOC-1,
  DOC-2, D-1–D-9), unchanged in count. FR-10 reads **Removed** (ADR 0015, PR #16) by deliberate design decision, not
  an open gap; every other row reads `Done`. DR-4 and DR-8 are re-pointed to the `dueAt` / `isDueSoon` code and tests
  at `3dbb2eb`; NFR-10 reads "served: no; local artifact `docs/api/index.html`" with AD-02 and AD-03 (both 404) as
  independent evidence; the **Independent acceptance** column carries the new IDs (DS-01..DS-04, DR-20). Independent runs at `3dbb2eb`: acceptance 104/104 PASS ([`evidence/2026-10-03T222058Z/acceptance/`](../evidence/2026-10-03T222058Z/acceptance/)); storyboard 30 frames, 12 journeys, 13/13 wireframes paired ([`evidence/2026-10-03T222326Z/storyboard/storyboard.md`](../evidence/2026-10-03T222326Z/storyboard/storyboard.md)).
- [x] Findings log: no open High findings —
  [`findings/log.md`](../findings/log.md): every Critical/High finding is either fixed and merged (carried forward:
  F-50→`a3d1af3`, F-55→`47eb261`, F-56/F-60→`de70329`/`141356a`, F-91→`3b76cfa`, F-98→`153d719`) or accepted with a
  documented reason (F-64/F-65: upstream postgres image, bump-the-pin-when-patched). F-101..F-113 (the review notes
  of PR #22 and PR #23) are Important at most, all Fix except F-105 and F-113 (Accept, Low).
- [ ] README quick start followed verbatim on a clean machine — **not met as worded**, unchanged from earlier
  sign-offs. The quick start's build-and-run path was exercised from a fresh clone by `verify`
  (`compose build --no-cache --pull`, then `compose up -d` → healthy) on a machine whose base images and npm cache
  were already warm — see the timing label in
  [`summary.md`](../evidence/2026-10-03T215759Z/summary.md): "Clean-clone rebuild → healthy: 26 s (arm64; base
  images and npm cache warm)". Docker images and build cache were deliberately not pruned: that would wipe the
  machine owner's Docker state. The nearest clean-machine evidence is the app's CI on fresh `ubuntu-latest`
  runners, green on `3dbb2eb` (run 37156200771), though through CI's own jobs rather than the README's literal
  `docker compose up --build -d`.
