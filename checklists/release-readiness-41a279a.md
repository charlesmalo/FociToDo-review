# Release readiness checklist — FociToDo @ 41a279a

Filled copy of [`release-readiness.md`](release-readiness.md) for the new release candidate
`41a279aeb13ed7aa677fa8248db7b33f9bcf98c7` (PR #17's merge commit, the commit after PR #16 and PR #17) · Date:
2026-10-02. Every box links the evidence it rests on; every harness run below records the checked-out SHA in its
`summary.md`.

- [x] `verify` passes from a clean clone of the release commit (arm64 locally; amd64 in CI) — arm64:
  [`evidence/2026-10-02T102541Z/summary.md`](../evidence/2026-10-02T102541Z/summary.md) (fresh clone at `41a279a`,
  `--no-cache` rebuild, test gate PASS, e2e PASS). amd64: the app's CI runs the same test-profile, e2e, image-build
  and (new) `diagrams` jobs on `ubuntu-latest` — green on `41a279a`:
  https://github.com/charlesmalo/FociToDo/actions/runs/36995141552.
- [x] Test gate green with 100% coverage; e2e green —
  [`test-gate.log`](../evidence/2026-10-02T102541Z/test-gate.log) (59 test files, 455 tests),
  [`coverage-summary.json`](../evidence/2026-10-02T102541Z/reports/coverage/coverage-summary.json) (lines 733/733,
  statements 824/824, functions 273/273, branches 386/386 — all 100%),
  [`e2e.log`](../evidence/2026-10-02T102541Z/e2e.log) (8 passed — down from 9 because the `/dev`-portal journey was
  removed with the portal itself in PR #16; diagram validity is now proven by the test gate and CI's `diagrams` job,
  not an e2e journey — see [`findings/log.md`](../findings/log.md) and `traceability/matrix.md`'s NFR-9/DOC-1 rows).
- [x] All stress invariants hold; no 5xx under load —
  [`evidence/2026-10-02T102716Z/stress/summary.md`](../evidence/2026-10-02T102716Z/stress/summary.md): 5/5 scenarios
  PASS, 13/13 invariants PASS (`*.invariants.txt`). `http_req_failed` is 0 in every scenario's k6 summary (`*.json`;
  509,411 requests in total), and no scenario lists a 5xx as an expected status, so no request returned 5xx.
- [x] No critical/high vulnerabilities without an accepted, documented reason —
  [`evidence/2026-10-02T103040Z/scans/`](../evidence/2026-10-02T103040Z/scans/): Trivy 0 HIGH/CRITICAL on the `api`
  and `web` images; `npm audit --omit=dev --audit-level=high` 0 (confirms `lodash-es`/`mermaid` are gone entirely,
  not just overridden — PR #16). The unmodified upstream `postgres:17.11-alpine` image still has 22 (1 CRITICAL, 21
  HIGH) Go stdlib CVEs in its `gosu` binary, unchanged from the de70329 sign-off and accepted with reason and
  remediation as [F-64 and F-65](../findings/log.md).
- [x] Hadolint clean or findings accepted —
  [`hadolint-Dockerfile.txt`](../evidence/2026-10-02T103040Z/scans/hadolint-Dockerfile.txt): 3 style findings
  (DL3066 ×1 at line 69, DL3025 ×2 at lines 71 and 85 — line numbers shifted from the de70329 Dockerfile but the
  same rule set), accepted as [F-57, F-58, F-59](../findings/log.md).
- [x] Traceability matrix: every requirement implemented and verified —
  [`traceability/matrix.md`](../traceability/matrix.md): 39 rows (FR-1–FR-9, FR-10, DR-1–DR-8, NFR-0–NFR-10, DOC-1,
  D-1–D-9). FR-10 reads **Removed** (ADR 0015, PR #16) by deliberate design decision, not an open gap; every other
  row reads `Done`, including the re-pointed NFR-9 and the new DOC-1 row, each citing its implementing code and
  verifying tests at `41a279a`.
- [x] Findings log: no open High findings — [`findings/log.md`](../findings/log.md): every Critical/High finding is
  either fixed and merged (F-50 in PR #12 → `a3d1af3`; F-55 in PR #13 → `47eb261`; F-56, F-60 in PR #14 → `de70329`,
  F-60's root cause then removed entirely by PR #16 → `141356a`) or accepted with a documented reason (F-64, F-65:
  upstream postgres image, bump the pin when a patched tag ships).
- [ ] README quick start followed verbatim on a clean machine — **not met as worded**, unchanged from the de70329
  sign-off. The quick start's build-and-run path was exercised from a fresh clone by `verify`
  (`compose build --no-cache --pull`, then `compose up -d` → healthy) on a machine whose base images and npm cache
  were already warm — see the timing label in
  [`summary.md`](../evidence/2026-10-02T102541Z/summary.md): "clean-clone rebuild → healthy: 28 s (arm64; base
  images and npm cache warm)". Docker images and build cache were deliberately not pruned: that would wipe the
  machine owner's Docker state. The nearest clean-machine evidence is the app's CI on fresh `ubuntu-latest` runners,
  where the `e2e` job builds and starts the full `db` → `migrate` → `api` → `web` stack from scratch — green on
  `41a279a` (run 36995141552) — though through the e2e overlay rather than the README's literal
  `docker compose up --build -d`.
