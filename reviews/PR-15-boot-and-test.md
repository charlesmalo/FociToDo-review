# Review — PR #15: make boot, smoke test and test runs unambiguous

- App commit range: `de70329..c39af72` (one commit, `89ec5c6`, merged as `c39af72`) · PR: https://github.com/charlesmalo/FociToDo/pull/15 · Date: 2026-10-02 · Reviewer: Claude Code (automated) + solution-lead triage
- Origin: a planned docs-only PR. `git -C FociToDo diff --stat de70329 c39af72` touches only `README.md` (+84/-8) and `AGENTS.md` (+24/-0) — no code, Dockerfile, compose or test file changed.

## What changed

The README's boot/verify/smoke/test instructions were rewritten to be unambiguous for both a human running them by hand and an agent following them literally — explicit exit-code checks, a one-shot `migrate` success condition, a health-endpoint curl with the exact expected body, a curl-based smoke-test sequence, and a teardown snippet. `AGENTS.md` gained matching guidance. No application behaviour changed.

## Verification

Two independent fresh-clone walkthroughs of the new README, each following it literally rather than relying on prior knowledge of the stack:

- **Implementer**, fresh clone: `docker compose up --build -d --wait` exit 0 (the one-shot `migrate` service exiting 0 is the documented success condition, not a failure); health curl body `{"status":"ok","db":"up","schemaVersion":"1759190400001_create-idempotency-keys"}`; smoke-test curl sequence 201/200/200/200/204; full gate (`docker compose --profile test run --rm --build test`) exit 0; e2e 9/9 exit 0.
  - **Found & fixed pre-merge**: the README's teardown snippet captured the previous command's exit status into a variable named `status`, which is a read-only special variable in zsh (`read-only variable: status`), so the snippet failed under zsh even though the teardown itself succeeded. Renamed to `rc`; squashed into `89ec5c6` before merge.
- **Independent reviewer**, second fresh clone, cold-read of only the README (no other context): boot, readiness check, smoke test and teardown all exited 0 and matched the README's documented behaviour under both zsh and sh. The smoke sequence showed `ETag` stepping `"1"` → `"2"` → `"3"` across successive updates, and a stale `If-Match` on the final step correctly returned `412`.

**Review verdict: Spec ✅. Approved.** No Critical or Important findings.

**Minor observation (not a defect, not filed as a finding)**: `compose.yaml` hard-codes `name: foci-todo` as the Compose project name. Running the README's teardown from a second clone while another `foci-todo` container (e.g. `db-test`, from a concurrent test-profile run) still shares the project's network prints a harmless "network … still in use" line from `docker compose down -v`; the command still exits 0 and removes what it owns. Intentional (`name:` keeps `docker compose` commands addressing the one stack regardless of which clone directory they're run from); no action taken.

## CI

- PR CI (run [36974362164](https://github.com/charlesmalo/FociToDo/actions/runs/36974362164)): green, 3/3 jobs (test, e2e, images).
- Main CI on the merge commit `c39af72` (run [36980193267](https://github.com/charlesmalo/FociToDo/actions/runs/36980193267)): green, 3/3 jobs — confirmed via `gh run view 36980193267 --repo charlesmalo/FociToDo --json conclusion,status` → `{"conclusion":"success","status":"completed"}`.

## Checklist

Copy of `checklists/milestone-review.md` with results for PR #15:

### Correctness
- [x] Behaviour matches the spec sections the PR claims (status codes, headers, validation messages) — N/A, no API behaviour changed; the documented status codes (201/200/200/200/204, 412 on stale `If-Match`) were independently re-verified against the real running stack by both walkthroughs.
- [~] Error precedence 400 → 428 → 404 → 412 preserved — N/A; no API code changed.
- [x] No silent catch-alls; unexpected errors become logged 500s — N/A; no code changed.

### Concurrency
- [x] Every write is a single statement or inside the unit of work — N/A; no write path changed.
- [x] Version bumps only on real changes; conditional writes use the version — N/A; unchanged, and re-observed correct (`ETag` `"1"`→`"2"`→`"3"`, stale `If-Match` → 412) by the independent reviewer's walkthrough.
- [x] New code paths covered by an invariant test if they touch shared state — N/A; no shared state touched.

### Tests
- [x] Test written first (visible in the commit) and mirrors the source path — N/A for a docs change; the README's own commands were the test, and the zsh `status` bug was caught by actually running them (RED) before the fix (GREEN), both pre-merge.
- [x] 100% coverage without `v8 ignore` — unaffected; full gate run with 100/100/100/100 as part of both walkthroughs.
- [x] Assertions check behaviour, not implementation details or timings — N/A; walkthroughs asserted on documented exit codes and response bodies, not timings.

### Architecture
- [x] Layer rules respected (lint passes); composition only in `app.ts` — unaffected; no source changed.
- [x] No new dependency without a reason in the commit or an ADR — no dependency change.

### Docs
- [x] README / guides / OpenAPI still accurate (no drift) — this PR's entire purpose; verified accurate by two independent fresh-clone, literal walkthroughs rather than by inspection alone.
- [x] New decisions recorded as ADRs — none needed; a documentation clarity fix, not an architectural decision.

### Security & operability
- [x] Inputs validated with shared schemas; no secrets or stack traces in responses — unaffected.
- [x] Images non-root; no dev dependencies in runtime images — unaffected; no Dockerfile or compose change.

**Verdict: clean, no fix round needed beyond the pre-merge teardown fix.** The zsh `status` read-only-variable bug (F-66) was caught and fixed before merge. The shared Compose project name's harmless "network still in use" message from a second clone (F-67) is accepted as informational. Approved to merge; merged as `c39af72`.
