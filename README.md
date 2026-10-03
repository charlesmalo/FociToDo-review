# FociToDo — Review & Assurance

Independent quality assurance for [FociToDo](https://github.com/charlesmalo/FociToDo): traceability, milestone reviews, reproducible verification, concurrency stress tests, security and portability checks, and a release sign-off. **Docker is the only prerequisite.**

| Folder | Contents |
|---|---|
| `traceability/` | Every requirement → implementing code → verifying tests → status |
| `reviews/` | One review per app PR (#1–#21): automated review output + solution-lead triage |
| `findings/log.md` | Every finding with severity, decision and the commit that resolved it |
| `checklists/` | Milestone-review and release-readiness checklists, plus filled release-readiness copies (latest: `153d719`) |
| `evidence/<date>/` | Raw outputs: test and coverage summaries, e2e report, k6 results, scans, acceptance results, storyboard frames, timings |
| `signoff.md` | One-page release recommendation |

## Release sign-off

**[signoff.md](signoff.md)** — FociToDo @ `153d719`, recommendation: Ready with noted risks (upstream `postgres:17.11-alpine` `gosu` CVEs, F-64/F-65 — the only remaining noted risk; the earlier `nginx-unprivileged` `pcre2` CVE, F-98, is now fixed).

Latest evidence (release candidate `153d7193d8170d1f8658ab4a047fcc34a7b6c711`, the commit after PR #18 "UI wireframes", PR #19 "fix: nginx re-resolves the api", PR #20 "fix: filter labels" and PR #21 "fix: pcre2 in the web image"; each `summary.md`/`results.md` records the SHA it ran against):
- Independent acceptance (black-box curl checks against every expectation): [`evidence/2026-10-03T094027Z/acceptance/`](evidence/2026-10-03T094027Z/acceptance/) — 99/99 PASS
- Storyboard (every UI journey as captioned screenshots beside its wireframe): [`evidence/2026-10-03T094100Z/storyboard/`](evidence/2026-10-03T094100Z/storyboard/) — 22 frames, 11 journeys, 13/13 wireframes paired
- Verify: [`evidence/2026-10-03T093902Z/`](evidence/2026-10-03T093902Z/)
- Scans: [`evidence/2026-10-03T093820Z/scans/`](evidence/2026-10-03T093820Z/scans/) — 0 HIGH/CRITICAL on both `api` and `web`
- Stress (unchanged since `5c43da9`, not re-run — a web-image-only patch can't affect concurrency behaviour): [`evidence/2026-10-03T090659Z/stress/`](evidence/2026-10-03T090659Z/stress/)
- Release readiness: [`checklists/release-readiness-153d719.md`](checklists/release-readiness-153d719.md)

Older `evidence/` directories are kept as history, including the 5c43da9, 41a279a and de70329 release-candidate evidence superseded by the above.

`main` is now `153d719`. PR #18 added UI wireframes (`docs/ui.md`, 13 screen states) plus the spec and plans for two new harnesses this review repository built that cycle. Those harnesses — **independent acceptance** (black-box HTTP checks of every documented expectation) and **storyboard** (every UI journey as captioned screenshots beside its wireframe) — then found three real app defects, each fixed through its own PR and re-verified: PR #19 fixed a persistence/availability bug (nginx cached a stale upstream IP for `api` after a restart, so the proxy 502'd forever — found by acceptance's `BR-20`); PR #20 fixed a filter-control accessibility bug (each `<select>`'s accessible name included every one of its options, a real-browser-only defect jsdom's own tests couldn't reproduce — found by the storyboard's Playwright/Chromium run); PR #21 fixed a HIGH `pcre2` CVE in the unmodified upstream `web` base image (found by this repository's own `scans`). See [`signoff.md`](signoff.md) for the full picture and [`reviews/PR-18-ui-wireframes.md`](reviews/PR-18-ui-wireframes.md) / [`reviews/PR-19-nginx-reresolve-api.md`](reviews/PR-19-nginx-reresolve-api.md) / [`reviews/PR-20-filter-labels.md`](reviews/PR-20-filter-labels.md) / [`reviews/PR-21-web-pcre2.md`](reviews/PR-21-web-pcre2.md) for the per-PR review notes. The 5c43da9 sign-off is folded into the `153d719` section above (rather than kept separately, since the only change between them is PR #21's one-layer patch); the 41a279a and de70329 sign-offs are kept as history in [`signoff.md`](signoff.md#earlier-sign-off--focitodo--41a279a).

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
