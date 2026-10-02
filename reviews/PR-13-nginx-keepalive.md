# Review — PR #13 fix(web): keep upstream connections alive between nginx and the API

- App commit range: `a3d1af3..c590910` (one commit; merged as `47eb261`) · PR: https://github.com/charlesmalo/FociToDo/pull/13 · Date: 2026-10-01 (pre-merge review), written up here 2026-10-02 · Reviewer: Claude Code (automated) + solution-lead triage
- Origin: not a planned PR. This repository's k6 stress suite, run against the then release candidate `a3d1af3`,
  found that nginx returned 502 for more than half of all requests under sustained load
  ([`evidence/2026-10-01T165123Z/stress/BLOCKED-root-cause.md`](../evidence/2026-10-01T165123Z/stress/BLOCKED-root-cause.md)).
  The solution lead ruled it an app fix (Ruling R18): availability under sustained load is part of "the app works".
  Recorded as F-55.

## Automated review output

Scope of PR #13 (one commit, `c590910`; confirmed via `review-a3d1af3..c590910.diff`: `apps/web/nginx.conf` only,
13 insertions, 1 deletion). Reviewed against the root-cause evidence above, the fix implementer's report
(RED/GREEN k6 runs, full gate, e2e), and the API's server settings at the same commit.

**Root cause (independently re-read from the evidence, not trusted on the report's word)**
- Before the fix, `location /api/` used `proxy_pass http://api:3000;` with no `upstream` pool. nginx's default is
  `Connection: close` upstream, so every proxied request opened a new TCP connection to `api`. Under the stress
  suite's 50 VUs with no think time, TIME_WAIT sockets piled up faster than the kernel reclaimed them, the
  container's ephemeral port range ran out, and nginx's `connect()` failed with `99: Address not available` —
  answered to clients as 502. The k6 logs beside the root-cause note show exactly that, while the optimistic-locking
  invariant stayed exact throughout (2457 = 2457): an availability bug in the proxy, not a concurrency bug in the API.

**The change**
- New `upstream api_upstream { server api:3000; keepalive 64; keepalive_timeout 4s; }`, and `location /api/` now
  uses `proxy_pass http://api_upstream;`, `proxy_http_version 1.1;` and `proxy_set_header Connection "";`. All three
  are needed for nginx to actually reuse upstream connections (HTTP/1.1 plus clearing the default `Connection: close`).
- `proxy_pass http://api_upstream;` has no URI part, so the request path (`/api/...`) still passes through unchanged
  — the same behaviour as before. The existing `Host`/`X-Forwarded-*` headers are untouched.
- `keepalive_timeout 4s` sits below Node's default `server.keepAliveTimeout` of 5 s. Confirmed at `de70329`:
  `apps/api/src/server.ts` calls `runtime.app.listen(config.PORT, …)` and sets neither `keepAliveTimeout` nor
  `headersTimeout`, so Node's defaults apply. nginx therefore always retires a pooled socket before Node closes it
  from its end, which avoids sporadic resets on reuse. The ordering is explained in a comment above the block.
- No API code, docs or other config changed. `docs/architecture.md` ("nginx serves the SPA and proxies `/api/*`
  unchanged") is still accurate.

**Verification**
- RED (unmodified config, k6 `race-patch`, 50 VUs, 30 s): `http_req_failed` 54.43 % (33,722 of 61,953), matching the
  root-cause run's 54.9–55.3 %. GREEN (with the fix, same stack): 0 % of 216,537 requests; `mixed-load` 0 % failed,
  p95 `GET /todos` 9.76 ms. Full gate 57 files / 417 tests, 100 % coverage; e2e 9/9 (from the fix report).
- PR CI green on the PR head `c590910` (run [36897947548](https://github.com/charlesmalo/FociToDo/actions/runs/36897947548):
  test, e2e, images) and on the merge commit `47eb261` (run [36898923442](https://github.com/charlesmalo/FociToDo/actions/runs/36898923442)).
- Re-confirmed independently by this repository's stress suite after merge — at `47eb261`
  ([`evidence/2026-10-01T171832Z/stress/`](../evidence/2026-10-01T171832Z/stress/), all scenarios PASS, 0 % failed)
  and again at the release candidate `de70329` (see `signoff.md` → Evidence).

**No new Critical, Important or Minor findings.** The pre-merge review was clean; nothing new turned up in this
write-up's re-read of the diff.

## Triage

| Finding | Severity | Category | Decision | Reason |
|---|---|---|---|---|
| F-55 nginx had no upstream keepalive → ephemeral port exhaustion → 502s under sustained load | High | availability | Fix | Fixed by this PR (merged `47eb261`); RED 54.43 % failed → GREEN 0 %, re-confirmed by this repository's own stress runs |

## Checklist

Copy of `checklists/milestone-review.md` with results for PR #13:

### Correctness
- [x] Behaviour matches the spec sections the PR claims (status codes, headers, validation messages) — proxy path,
  `Host` and `X-Forwarded-*` headers unchanged; the e2e `api.spec.ts` journeys (problem details, `ETag`/`If-Match`/
  `Location`, `Idempotency-Key` replay) pass through the proxy unchanged.
- [~] Error precedence 400 → 428 → 404 → 412 preserved — N/A; no API code changed.
- [x] No silent catch-alls; unexpected errors become logged 500s — N/A for an nginx config change; the fix removes a
  source of 502s rather than masking one.

### Concurrency
- [x] Every write is a single statement or inside the unit of work — N/A; no write path changed.
- [x] Version bumps only on real changes; conditional writes use the version — N/A; unchanged. The stress runs'
  Σ(version − 1) = successful-PATCH invariant held before and after the fix.
- [x] New code paths covered by an invariant test if they touch shared state — no shared state; the behaviour is
  covered by this repository's k6 scenarios (`race-patch`, `mixed-load` with `http_req_failed: rate==0`).

### Tests
- [~] Test written first (visible in the commit) and mirrors the source path — N/A for nginx config (no unit-test
  layer); the RED/GREEN evidence is the k6 run against the unmodified and the fixed config.
- [x] 100% coverage without `v8 ignore` — gate re-run at 100/100/100/100; no source or exclusion changed.
- [x] Assertions check behaviour, not implementation details or timings — the k6 thresholds check failure rate and
  correctness checks, not timings (the p95 threshold is a loose 250 ms ceiling).

### Architecture
- [x] Layer rules respected (lint passes); composition only in `app.ts` — unaffected; lint green in the gate.
- [x] No new dependency without a reason in the commit or an ADR — no dependency added.

### Docs
- [x] README / guides / OpenAPI still accurate (no drift) — `docs/architecture.md`'s proxy description still holds;
  the "why" of the keepalive settings is in a comment beside them.
- [x] New decisions recorded as ADRs — none needed; a proxy tuning fix, not an architectural decision.

### Security & operability
- [x] Inputs validated with shared schemas; no secrets or stack traces in responses — unaffected.
- [x] Images non-root; no dev dependencies in runtime images — unaffected; the `web` image is still
  `nginx-unprivileged` with only the built SPA.

**Verdict: clean.** A minimal, correctly ordered fix for a real availability bug, found by this repository's
stress suite, with a RED/GREEN load check, a green gate, e2e and CI, and re-confirmed by independent stress runs
after merge. No new findings.
