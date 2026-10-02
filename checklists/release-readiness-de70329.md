# Release readiness checklist — FociToDo @ de70329

Filled copy of [`release-readiness.md`](release-readiness.md) for the release candidate
`de70329bc74e7be8172821d2cc9da887dbfdbcca` (PR #14's merge commit) · Date: 2026-10-02.
Every box links the evidence it rests on; every harness run below records the checked-out SHA in its `summary.md`.

- [x] `verify` passes from a clean clone of the release commit (arm64 locally; amd64 in CI) — arm64:
  [`evidence/2026-10-02T043210Z/summary.md`](../evidence/2026-10-02T043210Z/summary.md) (fresh clone at `de70329`,
  `--no-cache` rebuild, test gate PASS, e2e PASS). amd64: `verify.sh` itself was not run there; the app's CI runs the
  same test-profile, e2e and image builds on `ubuntu-latest`, green on `de70329` —
  https://github.com/charlesmalo/FociToDo/actions/runs/36934017792.
- [x] Test gate green with 100% coverage; e2e green —
  [`test-gate.log`](../evidence/2026-10-02T043210Z/test-gate.log) (57 files, 417 tests),
  [`coverage-summary.json`](../evidence/2026-10-02T043210Z/reports/coverage/coverage-summary.json) (lines 629/629,
  statements 716/716, functions 246/246, branches 349/349),
  [`e2e.log`](../evidence/2026-10-02T043210Z/e2e.log) (9 passed).
- [x] All stress invariants hold; no 5xx under load —
  [`evidence/2026-10-02T043341Z/stress/summary.md`](../evidence/2026-10-02T043341Z/stress/summary.md): 5/5 scenarios
  PASS, 13/13 invariants PASS (`*.invariants.txt`). `http_req_failed` is 0 in every scenario's k6 summary
  (`*.json`; 534,208 requests in total), and no scenario lists a 5xx as an expected status, so no request returned 5xx.
- [x] No critical/high vulnerabilities without an accepted, documented reason —
  [`evidence/2026-10-02T043626Z/scans/`](../evidence/2026-10-02T043626Z/scans/): Trivy 0 HIGH/CRITICAL on the `api`
  and `web` images; `npm audit --omit=dev --audit-level=high` 0. The unmodified upstream `postgres:17.11-alpine`
  image has 22 (1 CRITICAL, 21 HIGH) Go stdlib CVEs in its `gosu` binary, accepted with reason and remediation as
  [F-64 and F-65](../findings/log.md).
- [x] Hadolint clean or findings accepted —
  [`hadolint-Dockerfile.txt`](../evidence/2026-10-02T043626Z/scans/hadolint-Dockerfile.txt): 3 style findings
  (DL3066 ×1, DL3025 ×2), accepted as [F-57, F-58, F-59](../findings/log.md).
- [x] Traceability matrix: every requirement implemented and verified —
  [`traceability/matrix.md`](../traceability/matrix.md): 38/38 rows (FR-1–FR-10, DR-1–DR-8, NFR-0–NFR-10, D-1–D-9)
  `Done`, each citing its implementing code and verifying tests.
- [x] Findings log: no open High findings — [`findings/log.md`](../findings/log.md): every Critical/High finding is
  either fixed and merged (F-50 in PR #12 → `a3d1af3`; F-55 in PR #13 → `47eb261`; F-56, F-60 in PR #14 → `de70329`)
  or accepted with a documented reason (F-64, F-65: upstream postgres image, bump the pin when a patched tag ships).
- [ ] README quick start followed verbatim on a clean machine — **not met as worded.** The quick start's build-and-run
  path was exercised from a fresh clone by `verify` (`compose build --no-cache --pull`, then `compose up -d` → healthy)
  on a machine whose base images and npm cache were already warm — see the timing label in
  [`summary.md`](../evidence/2026-10-02T043210Z/summary.md): "clean-clone rebuild → healthy: 28 s (arm64; base images
  and npm cache warm)". Docker images and build cache were deliberately not pruned: that would wipe the machine
  owner's Docker state. The nearest clean-machine evidence is the app's CI on fresh `ubuntu-latest` runners, where the `e2e`
  job builds and starts the full `db` → `migrate` → `api` → `web` stack from scratch — green on `de70329`
  (run 36934017792) — though through the e2e overlay rather than the README's literal `docker compose up --build -d`.
