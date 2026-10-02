# FociToDo — Review & Assurance

Independent quality assurance for [FociToDo](https://github.com/charlesmalo/FociToDo): traceability, milestone reviews, reproducible verification, concurrency stress tests, security and portability checks, and a release sign-off. **Docker is the only prerequisite.**

| Folder | Contents |
|---|---|
| `traceability/` | Every requirement → implementing code → verifying tests → status |
| `reviews/` | One review per app PR (#1–#14): automated review output + solution-lead triage |
| `findings/log.md` | Every finding with severity, decision and the commit that resolved it |
| `checklists/` | Milestone-review and release-readiness checklists, plus the filled release-readiness copy for `de70329` |
| `evidence/<date>/` | Raw outputs: test and coverage summaries, e2e report, k6 results, scans, timings |
| `signoff.md` | One-page release recommendation |

## Release sign-off

**[signoff.md](signoff.md)** — FociToDo @ `de70329`, recommendation: Ready with noted risks (upstream `postgres:17.11-alpine` `gosu` CVEs, F-64/F-65).

Latest evidence (release candidate `de70329bc74e7be8172821d2cc9da887dbfdbcca`; each `summary.md` records the SHA it ran against):
- Verify: [`evidence/2026-10-02T043210Z/`](evidence/2026-10-02T043210Z/)
- Stress: [`evidence/2026-10-02T043341Z/stress/`](evidence/2026-10-02T043341Z/stress/)
- Scans: [`evidence/2026-10-02T043626Z/scans/`](evidence/2026-10-02T043626Z/scans/)
- Release readiness: [`checklists/release-readiness-de70329.md`](checklists/release-readiness-de70329.md)

Older `evidence/` directories are kept as history.

## Running the checks

```bash
cp .env.example .env            # APP_REF is pinned to the signed-off release candidate; change it to verify another ref
docker compose run --rm verify  # clean clone → --no-cache rebuild → tests → e2e → evidence
docker compose run --rm stress  # k6 scenarios against a fresh stack + invariant checks
docker compose run --rm scans   # Trivy (app images + pinned postgres image), Hadolint, npm audit
```

- Stop anything on host port 8080 first (for example a running FociToDo): `verify` and `stress` start the app, which publishes `${WEB_PORT:-8080}`. Or pick another port with `-e WEB_PORT=18080`. A failed step names the log to read, and `verify` and `stress` tear their stacks down on any exit.
- `-e APP_REF=<sha|tag|branch>` overrides `.env` for one run. Every script clones the app afresh and records the checked-out SHA in its evidence `summary.md`.
- `scans` collects evidence and exits 0 when findings exist; it fails only when a scanner itself fails. Triage lives in [`findings/log.md`](findings/log.md).
- `verify` keeps only `reports/coverage/coverage-summary.json` and the Playwright `reports/e2e/index.html` in its evidence; the full reports stay in `work/app/reports/` (git-ignored) until the next run re-clones `work/app`.
- The verify timing is a clean-clone rebuild (`--no-cache`), not a cold-machine time: base images and the npm build cache already on the machine stay warm.

`verify`, `stress` and `scans` drive Docker through the host socket. They mount this folder at the **same absolute path** as on the host so the app's relative bind mounts keep working; this is acceptable for local review tooling and is not used by the app itself.

References in this repository to `.superpowers/…` files, task reports, or "controller ruling Rn" point to the author's unpublished working notes; the decision itself is stated where it is cited.
