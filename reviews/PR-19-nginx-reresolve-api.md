# Review — PR #19: fix(web): re-resolve the api so the proxy survives an api restart

- App commit range: `aeaa602..3b76cfa` (one commit, `c166858`; merged as `3b76cfa94d35d16caa9ddd581e64edc053b59bbc`) · PR: https://github.com/charlesmalo/FociToDo/pull/19 · Date: 2026-10-03 · Reviewer: Claude Code (automated) + solution-lead triage
- Origin: not a planned PR. The companion review repository's new independent **acceptance** harness, built in PR #18's cycle, ran its `BR-20` check (persistence across an api+db restart) against `41a279a`/`aeaa602` and found that after the `api` container restarts, every `/api/*` request returns 502 forever — the stack never recovers on its own. Recorded as **F-91**.

## Automated review output

Scope of PR #19 (one commit, `c166858`; `apps/web/nginx.conf` and `docs/architecture.md` only).

**Root cause (independently re-read, not trusted on the report's word)**: `apps/web/nginx.conf`'s `upstream api_upstream { server api:3000; }` (added by PR #13 for keepalive) resolves the hostname `api` to an IP **once**, at nginx startup, and then reuses that IP for the life of the pooled connections — nginx has no mechanism to notice that Docker's embedded DNS now maps `api` to a different address after a restart. The review's own acceptance evidence before the fix (`evidence/2026-10-03T073446Z/acceptance/`) shows exactly this: `api` restarted on a new IP, and the harness aborted at `BR-20` because every subsequent request 502'd.

**The change**:
- `resolver 127.0.0.11 valid=10s ipv6=off;` — nginx's own re-resolution of names through Docker's embedded DNS server, re-checked every 10 s.
- `upstream api_upstream { zone api_upstream 64k; server api:3000 resolve; }` — nginx 1.31's open-source `resolve` parameter makes this upstream dynamically re-resolvable (it requires a shared-memory `zone` to do so); without `resolve`, `server` is still resolved once at config load like before.
- `keepalive 64; keepalive_timeout 4s;` (PR #13's settings) are unchanged, so the keepalive pool that fixed F-55 stays intact — this fix adds re-resolution without reintroducing the per-request-connection problem it previously solved.
- `docs/architecture.md` gains a one-line note that the proxy re-resolves the API.

**Verification (independently re-read)**:
- RED: `docker compose restart db api` changed the api container's IP from `172.20.0.4` to `.3`; 30/30 sequential `/api/health` requests → 502 over 60 s (matches the acceptance harness's own `BR-20.logs.txt`).
- GREEN: with the fix, a forced IP change `172.20.0.3` → `.6`; `/api/health` → 200 within 11 s of the api becoming healthy again, without touching `web`; then 2,000/2,000 sequential `/api/todos` requests → 200, confirming the keepalive pool still works (no F-55 regression).
- `nginx -t` passes on the built image. Full gate 457 tests, 100% coverage; e2e 8/8.

**Independent re-confirmation by this review's own acceptance run on the merged commit `5c43da9`** (this sign-off cycle): 99/99 PASS including `BR-20` — [`evidence/2026-10-03T090410Z/acceptance/results.md`](../evidence/2026-10-03T090410Z/acceptance/results.md).

**No new findings beyond F-91.** The fix is minimal, correctly scoped to the actual root cause (DNS re-resolution, not a symptom patch), and preserves the PR #13 keepalive fix it sits beside.

## Findings

| Finding | Severity | Category | Decision | Reason |
|---|---|---|---|---|
| F-91 `apps/web/nginx.conf`'s upstream resolved `api` once at nginx startup; after an api restart on a new IP, nginx kept proxying to the stale address and every `/api/*` request 502'd forever, with no self-recovery | High | availability | Fix | Fixed by this PR (merged `3b76cfa94d35d16caa9ddd581e64edc053b59bbc`) — `resolver 127.0.0.11 valid=10s ipv6=off;` plus `zone api_upstream 64k;` / `server api:3000 resolve;`, keeping the PR #13 keepalive pool intact; RED 30/30 502 → GREEN recovery ≤ 11 s, 2,000/2,000 keepalive requests 200; independently re-confirmed by this review's acceptance run at `5c43da9` (99/99 PASS including BR-20) |

## CI

- PR CI, head commit `c166858` (run [37109535429](https://github.com/charlesmalo/FociToDo/actions/runs/37109535429)): green, 4/4 jobs — test, images, diagrams, e2e.
- Main CI on the merge commit `3b76cfa`: green, 4/4 jobs.

## Checklist

Copy of `checklists/milestone-review.md` with results for PR #19:

### Correctness
- [x] Behaviour matches the spec sections the PR claims (status codes, headers, validation messages) — N/A, proxy-layer fix; the API's own responses are untouched and pass through unchanged, confirmed by the 2,000/2,000 `GET /api/todos` → 200 run.
- [~] Error precedence 400 → 428 → 404 → 412 preserved — N/A; no API code changed.
- [x] No silent catch-alls; unexpected errors become logged 500s — the fix removes a silent-forever-502 failure mode rather than masking one; nginx's error log named the stale upstream address before the fix.

### Concurrency
- [x] Every write is a single statement or inside the unit of work — N/A; no write path changed.
- [x] Version bumps only on real changes; conditional writes use the version — N/A; unaffected.
- [x] New code paths covered by an invariant test if they touch shared state — N/A; no shared state. Covered instead by this review's own BR-20 acceptance check and this PR's RED/GREEN restart evidence.

### Tests
- [~] Test written first (visible in the commit) and mirrors the source path — N/A for an nginx config fix (no unit-test layer for `nginx.conf`); RED/GREEN against the real restarted stack is the equivalent evidence, matching the independent acceptance harness's own RED finding.
- [x] 100% coverage without `v8 ignore` — gate re-run at 100/100/100/100; no source or exclusion changed.
- [x] Assertions check behaviour, not implementation details or timings — health-check status and keepalive request-count assertions, not raw timings (the ≤ 11 s recovery figure is reported, not asserted as a strict threshold).

### Architecture
- [x] Layer rules respected (lint passes); composition only in `app.ts` — unaffected; lint green.
- [x] No new dependency without a reason in the commit or an ADR — no new dependency; uses nginx 1.31's built-in `resolve` parameter and Docker's existing embedded DNS at `127.0.0.11`.

### Docs
- [x] README / guides / OpenAPI still accurate (no drift) — `docs/architecture.md` updated with the one-line re-resolution note; nothing else needed updating.
- [x] New decisions recorded as ADRs — none needed; a targeted bug fix, not an architectural decision.

### Security & operability
- [x] Inputs validated with shared schemas; no secrets or stack traces in responses — unaffected.
- [x] Images non-root; no dev dependencies in runtime images — unaffected; the `web` image is still `nginx-unprivileged` with only the built SPA.

**Verdict: clean.** A minimal, correctly root-caused fix for a real availability defect that this review's own new acceptance harness was the first thing to find, with matching RED/GREEN evidence, a green gate and CI, and independent re-confirmation by the acceptance run on the final merged commit.
