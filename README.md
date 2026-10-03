# FociToDo — Review & Assurance

Independent quality assurance for [FociToDo](https://github.com/charlesmalo/FociToDo): traceability, milestone reviews, reproducible verification, concurrency stress tests, security and portability checks, and a release sign-off. **Docker is the only prerequisite.**

| Folder | Contents |
|---|---|
| `traceability/` | Every requirement → implementing code → verifying tests → status |
| `reviews/` | One review per app PR (#1–#17): automated review output + solution-lead triage |
| `findings/log.md` | Every finding with severity, decision and the commit that resolved it |
| `checklists/` | Milestone-review and release-readiness checklists, plus filled release-readiness copies (latest: `41a279a`) |
| `evidence/<date>/` | Raw outputs: test and coverage summaries, e2e report, k6 results, scans, timings |
| `signoff.md` | One-page release recommendation |

## Release sign-off

**[signoff.md](signoff.md)** — FociToDo @ `41a279a`, recommendation: Ready with noted risks (upstream `postgres:17.11-alpine` `gosu` CVEs, F-64/F-65).

Latest evidence (release candidate `41a279aeb13ed7aa677fa8248db7b33f9bcf98c7`, the commit after PR #16 "remove the `/dev` developer portal" and PR #17 "diagram images and README diagram map"; each `summary.md` records the SHA it ran against):
- Verify: [`evidence/2026-10-02T102541Z/`](evidence/2026-10-02T102541Z/)
- Stress: [`evidence/2026-10-02T102716Z/stress/`](evidence/2026-10-02T102716Z/stress/)
- Scans: [`evidence/2026-10-02T103040Z/scans/`](evidence/2026-10-02T103040Z/scans/)
- Release readiness: [`checklists/release-readiness-41a279a.md`](checklists/release-readiness-41a279a.md)

Older `evidence/` directories are kept as history, including the de70329 release-candidate evidence superseded by the above.

`main` is now `41a279a`: PR #16 removed the in-app `/dev` developer portal (ADR 0015 — GitHub already renders the same Markdown and Mermaid), and PR #17 added generated, gate- and CI-verified diagram images with a README map. The e2e suite drops to 8/8 because the portal's own journey was removed with it; diagram validity is now proven by the test gate (`packages/diagrams`) and the CI `diagrams` job instead. See [`signoff.md`](signoff.md) for the full picture and [`reviews/PR-16-remove-dev-portal.md`](reviews/PR-16-remove-dev-portal.md) / [`reviews/PR-17-diagram-images.md`](reviews/PR-17-diagram-images.md) for the per-PR review notes. The de70329 sign-off (and PR #15's post-sign-off note) are kept as history in [`signoff.md`](signoff.md#earlier-sign-off--focitodo--de70329).

## Running the checks

```bash
cp .env.example .env            # APP_REF is pinned to the signed-off release candidate; change it to verify another ref
docker compose run --rm verify  # clean clone → --no-cache rebuild → tests → e2e → evidence
docker compose run --rm stress  # k6 scenarios against a fresh stack + invariant checks
docker compose run --rm scans   # Trivy (app images + pinned postgres image), Hadolint, npm audit
docker compose run --rm acceptance   # black-box curl checks of every expectation (catalogue: acceptance/expectations.md)
docker compose run --rm storyboard   # every UI journey as captioned screenshots beside its wireframe
```

- `acceptance` starts its own app stack with no host port (so it runs even while a FociToDo stack already holds 8080), and writes `evidence/<timestamp>/acceptance/` (a results table plus a request/response transcript per expectation) independently of the app's own tests.
- `storyboard` starts its own app stack with no host port and drives it with Playwright, writing `evidence/<timestamp>/storyboard/` (`frames/*.png`, the app's `docs/diagrams/ui/*.svg` wireframes, and `storyboard.md` pairing each captioned frame with the wireframe of the screen state it should match) independently of the app's own e2e suite.
- Stop anything on host port 8080 first (for example a running FociToDo): `verify` and `stress` start the app, which publishes `${WEB_PORT:-8080}`. Or pick another port with `-e WEB_PORT=18080`. A failed step names the log to read, and `verify` and `stress` tear their stacks down on any exit.
- `-e APP_REF=<sha|tag|branch>` overrides `.env` for one run. Every script clones the app afresh and records the checked-out SHA in its evidence `summary.md`.
- `scans` collects evidence and exits 0 when findings exist; it fails only when a scanner itself fails. Triage lives in [`findings/log.md`](findings/log.md).
- `verify` keeps only `reports/coverage/coverage-summary.json` and the Playwright `reports/e2e/index.html` in its evidence; the full reports stay in `work/app/reports/` (git-ignored) until the next run re-clones `work/app`.
- The verify timing is a clean-clone rebuild (`--no-cache`), not a cold-machine time: base images and the npm build cache already on the machine stay warm.

`verify`, `stress` and `scans` drive Docker through the host socket. They mount this folder at the **same absolute path** as on the host so the app's relative bind mounts keep working; this is acceptable for local review tooling and is not used by the app itself.

References in this repository to `.superpowers/…` files, task reports, or "controller ruling Rn" point to the author's unpublished working notes; the decision itself is stated where it is cited.
