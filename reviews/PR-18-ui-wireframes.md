# Review — PR #18: docs: UI wireframes for every screen state

- App commit range: `41a279a..aeaa602` (four commits: `ce68857` docs(spec), `66eb781` docs(plan), `6804cec` feat(diagrams), `b03cc7c` docs(ui); merged as `aeaa6020471392f2a1a970bc4b1c23175babd87d`) · PR: https://github.com/charlesmalo/FociToDo/pull/18 · Date: 2026-10-03 · Reviewer: Claude Code (automated) + solution-lead triage
- Origin: spec [`2026-10-02-acceptance-storyboard-design.md`](https://github.com/charlesmalo/FociToDo/blob/aeaa6020471392f2a1a970bc4b1c23175babd87d/docs/superpowers/specs/2026-10-02-acceptance-storyboard-design.md) §3 (every screen state of the single-page UI gets a wireframe, ready for the review repository's storyboard to pair each one with a screenshot of the running app).

## What changed

- **Spec and plans** for the whole acceptance/storyboard initiative: `docs/superpowers/specs/2026-10-02-acceptance-storyboard-design.md` and `docs/superpowers/plans/2026-10-02-acceptance-storyboard/{00-index,01-ui-wireframes,02-review-acceptance}.md`. The executable harness and its evidence live only in the companion `FociToDo-review` repository (spec §2, binding).
- **`docs/ui.md`**: 13 Mermaid `block-beta` wireframes, one per screen state of the single-page UI (task list — loading/empty/with tasks/no match/load error; filters and sorting; each dialog state — new task, new task with errors, task details, edit task, delete confirmation, changed elsewhere, task no longer exists), each with a one-line "when this appears", a notation legend and a link to the companion review repository.
- **Diagram tool**: `packages/diagrams/src/extract.ts`/`slug.ts` map `block-beta` (and `block`) fences to diagram kind `wireframe`, so alt text reads `<heading> (wireframe)`; the existing render/check/README-map pipeline picks the 13 new diagrams up unchanged. Manifest grows from 19 to 32 entries; README gains a **UI** map block; `docs/architecture.md` links `docs/ui.md`.

## Automated review output

Per-task reviews during the branch (spec/plan review; diagrams-tool review; `docs/ui.md` content review against the real running UI) were clean after minor fixes to wording, the notation legend, cross-references ("triggers") and a few spec tables and plan corrections — no behavioural code outside `packages/diagrams/src/extract.ts`/`slug.ts` was touched, so these were docs-only and are not separately tracked as findings.

**Final whole-branch review (opus), run alongside the first pass of the review repository's new acceptance harness against this branch's base (`41a279a`) and against the merged result** surfaced three items:

1. **High — BR-20, found by the review repository's independent acceptance harness, not by this PR's own tests**: running the newly-built acceptance catalogue against `41a279a` (the commit this PR is based on) showed that after the `api` container restarts, the web front end returns 502 for every `/api/*` call forever — nginx caches a stale upstream IP and never recovers on its own. This is an app defect in already-merged code (PR #13's keepalive upstream, not anything in this PR), not something PR #18 introduced or could fix (`apps/web/nginx.conf` is untouched by this PR). Tracked here, fixed in app PR #19.
2. **Important — harness pre-clean**: an early run of `scripts/acceptance.sh` (review repository) left a stale `review-acceptance` Compose project behind after an aborted run, with no teardown-before-start guard; a retry could read stale containers/network state. Fixed in the review repository directly (commit `8a70e4b`), not in this app PR — recorded here because it surfaced during this review cycle.
3. **Important — spec §2 vs. the plan's Global Constraints (Ruling R44)**: the design spec's §2 (binding separation of the review package from the app) and `docs/superpowers/plans/2026-10-02-acceptance-storyboard/00-index.md`'s own Global Constraints section described the review-repository allowed-sources list in terms that didn't line up word-for-word — a drift risk since both are meant to say the same thing. Reconciled within this PR: spec §2 is marked binding and the plan's Global Constraints section now names the identical list, cross-referencing spec §2 directly.

No Critical/Important findings against this PR's own diffed code; BR-20 is a High-severity, pre-existing defect in merged code that this PR's own new harness happened to be the first thing to independently exercise against a running stack.

## Findings

| Finding | Severity | Category | Decision | Reason |
|---|---|---|---|---|
| F-96 `scripts/acceptance.sh` did not tear down a stale `review-acceptance` Compose project before starting a new run | Important | tests | Fix | Fixed in this repository's commit `8a70e4b983793bdcca9d4d390ee717aa0128f49d` — `set -Eeuo pipefail` + an ERR trap naming the failing line, and a teardown of any stale stack before starting |
| F-97 The design spec's §2 and the plan's Global Constraints section described the review-repository allowed-sources list in terms that didn't line up word-for-word | Important | docs | Fix | Fixed by this PR (merged `aeaa6020471392f2a1a970bc4b1c23175babd87d`) — Ruling R44: spec §2 marked binding, the plan's Global Constraints section reworded to name the identical list |

(BR-20 itself — the High persistence defect this PR's new harness found in already-merged code — is tracked as **F-91** against PR #19, which fixed it; see `reviews/PR-19-nginx-reresolve-api.md` and `findings/log.md`.)

## CI

- PR CI, final commit `b03cc7c` (run [37108637091](https://github.com/charlesmalo/FociToDo/actions/runs/37108637091)): green, 4/4 jobs — test, images, diagrams, e2e.
- Main CI on the merge commit `aeaa602`: green, 4/4 jobs (test gate 457 tests, coverage 100%; e2e 8/8; `diagrams` reproduces all 32 images byte-for-byte on amd64).

## Checklist

Copy of `checklists/milestone-review.md` with results for PR #18:

### Correctness
- [x] Behaviour matches the spec sections the PR claims (status codes, headers, validation messages) — N/A, no API/web behaviour changed; every visible string in `docs/ui.md` was checked against the actual running UI.
- [~] Error precedence 400 → 428 → 404 → 412 preserved — N/A; no API code changed.
- [x] No silent catch-alls; unexpected errors become logged 500s — N/A for a docs/diagram-tool PR.

### Concurrency
- [x] Every write is a single statement or inside the unit of work — N/A; no shared mutable state touched.
- [x] Version bumps only on real changes; conditional writes use the version — N/A.
- [x] New code paths covered by an invariant test if they touch shared state — N/A.

### Tests
- [x] Test written first (visible in the commit) and mirrors the source path — `packages/diagrams/tests/extract.test.ts` gained the `block-beta`/`block` kind-mapping cases alongside `src/extract.ts`.
- [x] 100% coverage without `v8 ignore` — gate 457 tests, 100/100/100/100.
- [x] Assertions check behaviour, not implementation details or timings — the diagram-kind mapping and manifest-growth assertions are behavioural (rendered SVG kind, manifest entry count), not implementation-coupled.

### Architecture
- [x] Layer rules respected (lint passes); composition only in `app.ts` — unaffected; lint green.
- [x] No new dependency without a reason in the commit or an ADR — no new dependency; reuses the existing Mermaid CLI pipeline from PR #17.

### Docs
- [x] README / guides / OpenAPI still accurate (no drift) — README gains the **UI** diagram-map block; `docs/architecture.md` links `docs/ui.md`; both verified by the gate's `checkReadmeMap`.
- [x] New decisions recorded as ADRs — none needed; an additive documentation deliverable, not an architectural decision.

### Security & operability
- [x] Inputs validated with shared schemas; no secrets or stack traces in responses — N/A, no HTTP surface changed.
- [x] Images non-root; no dev dependencies in runtime images — unaffected.

**Verdict: approved**, with one pre-existing High defect (BR-20) surfaced in already-merged code by this PR's companion harness work and two Important process findings (F-96, F-97) fixed directly in the review repository and the spec. Nothing in this PR's own diff is outstanding.
