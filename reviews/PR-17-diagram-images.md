# Review — PR #17: diagram images and README diagram map

- App commit range: `141356a..41a279a` (four commits: `526f59b` feat(diagrams) extract, `cc04320` feat(diagrams) checks, `3d25edf` feat(diagrams) render, `a1f79e3` docs(readme)) · PR: https://github.com/charlesmalo/FociToDo/pull/17 · Date: 2026-10-02 · Reviewer: Claude Code (automated) + solution-lead triage
- Origin: spec [`2026-10-02-docs-diagrams-design.md`](https://github.com/charlesmalo/FociToDo/blob/41a279aeb13ed7aa677fa8248db7b33f9bcf98c7/docs/superpowers/specs/2026-10-02-docs-diagrams-design.md) §2 (every Mermaid diagram gets a generated, committed SVG shown inline above its collapsed source; a gate check and CI step keep images from drifting; the README maps every document's diagrams to their source and image).

## What changed

A new `packages/diagrams` package: `extract.ts`/`slug.ts` pull every ```` ```mermaid ```` block out of `README.md` and `docs/*.md` and assign each a stable `<doc>/<slug>` id; `layout.ts` enforces the image-then-collapsed-source shape at exact line positions; `manifest.ts`/`paths.ts` define `docs/diagrams/manifest.json` (id, source file, heading, image path, content hash); `readmeMap.ts` checks every manifest id appears in the README's diagram table; `check.ts`'s `checkRepository` (`packages/diagrams/src/check.ts:67-81`) composes all of the above into the gate check wired into `vitest.config.ts`'s `diagrams` project; `render.ts`/`mmdc.ts`/`repo.ts` drive the pinned official Mermaid CLI image (`docker compose --profile docs run --rm --build diagrams`) to render all 19 diagrams to SVG (`handDrawnSeed: 1`, `htmlLabels: false`, fixed theme, white background) and write the manifest. `.github/workflows/ci.yml` gains a `diagrams` job (`:63-82`) that regenerates every image and fails if `git status --porcelain -- docs/diagrams` is not empty, printing the diff and uploading the regenerated images as a build artifact on failure. `README.md`'s one-line "More:" list is replaced by a "Documentation and diagrams" section mapping every document (README, Architecture, API, Concurrency, Testing, Decisions) to a table of diagram/image/source links; `docs/*.md` show each diagram as an image with its Mermaid source collapsed underneath.

## Automated review output

**Task 1 (`526f59b` extract)** — gate 405, 100% coverage. Review **Approved**; one minor deferred (indented and annotated Mermaid fences silently ignored by the extractor) — carried forward and fixed as an Important finding in the final whole-branch review (F-82 below).

**Task 2 (`cc04320` checks)** — review **Needs fixes**:
- The layout check ignored blank lines, though the plan mandates exact line positions — blank lines are load-bearing (a `<details>` block runs until a blank line, else GitHub shows the fence as raw text).
- A corrupt `manifest.json` made the check throw instead of reporting a fixable problem.
- Minor, deferred: `readmeMap` treats any `|`-prefixed line as a table row, and `repo.ts` mixes `path.join` and `path.posix.relative`.

**Task 3 (`3d25edf` render)** — gate 448, 100% coverage; the generator rendered all 19 diagrams (README 2, architecture 6, api 7, concurrency 3, testing 1). Determinism required `"handDrawnSeed": 1` in the Mermaid config (Roughjs treats seed `0` as random, breaking determinism for ER and class diagrams) — an implementation deviation found and accepted during this task, documented in spec §2.4. Review **Approved**.

**Task 4 (`a1f79e3` docs)** — RED: 38 problems (19 stale layouts + 19 missing README-map rows) against the pre-restructure docs; GREEN after restructuring every document to the §2.2 shape and rewriting the README map. Gate 100%; e2e 8/8; the drift proof (editing a diagram's Mermaid source without regenerating) reproduced the exact stale-image gate message. Review **Approved**.

**Final whole-branch review (opus)** — no Critical findings. Important: (1) the CI `diagrams` job kept no diagnostics or artifact on failure; (2) the spec's cross-arch contingency (amd64 CI vs. arm64 local rendering) was incoherent as written — parked with evidence instead of further spec changes: CI on amd64 reproduced the arm64-committed SVG bytes exactly; (3) the indented/annotated Mermaid fences deferred from Task 1 now fail loudly instead of being silently skipped; (4) an SVG with `width="100%"` would stretch small diagrams to fill their container on GitHub — fixed with `useMaxWidth: false` and fixed sizes. Minors fixed: stale package descriptions in the README's layout section, `docs/architecture.md` and `CLAUDE.md`; a missing rule in `CLAUDE.md` for how to add a new diagram; unclear spec §2.6 wording; the layout check's indentation and blank-line-after-`</details>` rule; the Mermaid CLI Docker image pinned by tag rather than digest; a missing note that the generator leaves `docs/diagrams/` root-owned on Linux hosts. Parked: `headingText` keeps Markdown formatting characters (e.g. `_`) in exotic headings — no current heading is exotic enough to trigger it, and GitHub keeps `_` in anchors regardless.

## Findings

| Finding | Severity | Category | Decision | Reason |
|---|---|---|---|---|
| F-76 The diagram layout check ignored blank lines, though the plan mandates exact line positions (a `<details>` block runs until a blank line) | Important | correctness | Fix | Fixed by this PR (merged `41a279a`) — Ruling R37: `checkLayout` (`packages/diagrams/src/layout.ts`) now enforces exact line positions |
| F-77 A corrupt `docs/diagrams/manifest.json` made `checkImages` throw instead of reporting a fixable problem | Important | correctness | Fix | Fixed by this PR (merged `41a279a`) — Ruling R38: reported as a problem naming the fix command (`packages/diagrams/src/check.ts:36-41`), not an uncaught exception |
| F-78 `readmeMap` treats any `\|`-prefixed line as a table row, and `repo.ts` mixes `path.join` and `path.posix.relative` | Minor | design | Accept | Accepted in this PR (merged `41a279a`) — deferred at Task 2 review; no behavioural impact on the current README map |
| F-79 Deterministic rendering required `"handDrawnSeed": 1` — Roughjs treats seed `0` as random, breaking determinism for ER and class diagrams | Minor | design | Accept | Accepted in this PR (merged `41a279a`) — Ruling R40: deviation from an assumed default, verified necessary and documented in the design spec §2.4 |
| F-80 The CI `diagrams` job kept no diagnostics or artifact on a drift/render failure | Important | operability | Fix | Fixed by this PR (merged `41a279a`) — the job now prints the diff and uploads the regenerated images as a build artifact on failure (`.github/workflows/ci.yml:74-82`) |
| F-81 The spec's cross-arch contingency for the `diagrams` CI job (amd64 CI vs. arm64 local rendering) was incoherent as written | Important | operability | Accept | Parked in this PR (merged `41a279a`) — Ruling R41, with evidence: CI on amd64 reproduced the arm64-committed SVG bytes exactly (run [36994896549](https://github.com/charlesmalo/FociToDo/actions/runs/36994896549), PR #17's final commit `a1f79e3`) |
| F-82 Indented and annotated Mermaid fences were silently ignored by the extractor instead of being flagged | Important | correctness | Fix | Flagged as a deferred minor at Task 1 review; fixed in this PR's final review (merged `41a279a`) — now fails loudly instead of silently skipping |
| F-83 An SVG with `width="100%"` would stretch small diagrams to fill their container on GitHub | Important | design | Fix | Fixed by this PR (merged `41a279a`) — `useMaxWidth: false` and fixed sizes in the Mermaid config |
| F-84 Stale package descriptions in the README's layout section, `docs/architecture.md` and `CLAUDE.md` | Minor | docs | Fix | Fixed by this PR (merged `41a279a`) — descriptions updated to match the current package layout |
| F-85 No rule in `CLAUDE.md` for how to add a new diagram | Minor | docs | Fix | Fixed by this PR (merged `41a279a`) — rule added |
| F-86 Spec §2.6 wording was unclear | Minor | docs | Fix | Fixed by this PR (merged `41a279a`) — reworded |
| F-87 Layout-check indentation and the blank-line-after-`</details>` rule needed clarification | Minor | design | Fix | Fixed by this PR (merged `41a279a`) — rule and check clarified and aligned |
| F-88 The Mermaid CLI Docker image was pinned by tag rather than digest | Minor | security | Fix | Fixed by this PR (merged `41a279a`) — pinned by digest |
| F-89 No note that `docker compose --profile docs run --rm --build diagrams` leaves `docs/diagrams/` root-owned on Linux hosts | Minor | operability | Fix | Fixed by this PR (merged `41a279a`) — note added |
| F-90 `headingText` keeps Markdown formatting characters (e.g. `_`) in exotic headings, which could affect the GitHub-generated anchor | Minor | design | Accept | Parked in this PR (merged `41a279a`) — Ruling R42: no current heading is exotic enough to trigger it; GitHub keeps `_` in anchors regardless |

## CI

- PR CI, final commit `a1f79e3` (run [36994896549](https://github.com/charlesmalo/FociToDo/actions/runs/36994896549)): green, 4/4 jobs — test, e2e, images, **diagrams** (the new job regenerates all 19 images and confirms `git status --porcelain -- docs/diagrams` is empty on `ubuntu-latest`/amd64, reproducing the arm64-committed SVG bytes exactly; see F-81).
- Main CI on the merge commit `41a279a` (run [36995141552](https://github.com/charlesmalo/FociToDo/actions/runs/36995141552)): green, 4/4 jobs.

## Checklist

Copy of `checklists/milestone-review.md` with results for PR #17:

### Correctness
- [x] Behaviour matches the spec sections the PR claims (status codes, headers, validation messages) — N/A, no API behaviour changed; the diagram tool's own behaviour (extraction, layout, freshness) matches spec §2 after the F-76/F-77/F-82/F-83 fixes.
- [~] Error precedence 400 → 428 → 404 → 412 preserved — N/A; no API code changed.
- [x] No silent catch-alls; unexpected errors become logged 500s — the fix round replaced two silent failure modes (a corrupt manifest throwing, indented fences being skipped) with loud, actionable problems.

### Concurrency
- [x] Every write is a single statement or inside the unit of work — N/A; the tool writes files, no shared mutable state.
- [x] Version bumps only on real changes; conditional writes use the version — N/A.
- [x] New code paths covered by an invariant test if they touch shared state — N/A; no shared state.

### Tests
- [x] Test written first (visible in the commit) and mirrors the source path — `src/a/B.ts` → `tests/a/B.test.ts` throughout `packages/diagrams`; Task 4's RED (38 problems) shown before GREEN.
- [x] 100% coverage without `v8 ignore` — gate 455 tests, 100/100/100/100 at the final state; the one permitted new exclusion is the logic-free `packages/diagrams/src/bin.ts` entry point.
- [x] Assertions check behaviour, not implementation details or timings — `describe('this repository', ...)` (`packages/diagrams/tests/check.test.ts:134-138`) asserts `checkRepository(fsRepo(root))` returns no problems against the real, committed docs tree — a behavioural, not implementation, assertion.

### Architecture
- [x] Layer rules respected (lint passes); composition only in `app.ts` — N/A outside the API/web app; the new package has no layer-boundary rule, lint green.
- [x] No new dependency without a reason in the commit or an ADR — the pinned Mermaid CLI image is a build-time tool dependency, not a runtime one; reason (determinism, no silent drift) is in the spec and commits.

### Docs
- [x] README / guides / OpenAPI still accurate (no drift) — this PR's entire purpose; every document restructured to show its diagrams as images with collapsed source, and the README's new "Documentation and diagrams" section maps every manifest id to a table row, verified by the gate check itself (`checkReadmeMap`).
- [x] New decisions recorded as ADRs — none needed beyond ADR 0015 (recorded in PR #16, per Ruling R33: the decision precedes this PR's implementation of it).

### Security & operability
- [x] Inputs validated with shared schemas; no secrets or stack traces in responses — N/A, no HTTP surface changed.
- [x] Images non-root; no dev dependencies in runtime images — unaffected; the `diagrams` Docker service is a `--profile docs` build-time tool, not part of the `api`/`web` runtime images.

**Verdict: clean after fix rounds at Task 2 and final review.** No Critical findings; four Important findings all resolved (three fixed, one parked with amd64-reproduction evidence); eleven Minors fixed or explicitly accepted with a reason. Approved to merge; merged as `41a279a`. Final state: gate 455 tests, 100/100/100/100 coverage; e2e 8/8; 19 SVGs committed; the CI `diagrams` job reproduces every image byte-for-byte on amd64.
