# BLOCKED: real app bug found by `race-patch` and `mixed-load`

Ran `docker compose run --rm --build stress` against `APP_REF=a3d1af3f4f8899f2e8800898104d2a9a869d30f6`.
3 of 5 scenarios PASS. `race-patch` and `mixed-load` fail — not because optimistic
concurrency control is broken, but because the app's reverse proxy drops the
majority of requests once sustained throughput is high enough, for ~20-30s.

## Symptom

- `race-patch` (50 VUs, no think-time, 30s): k6 thresholds fail —
  `http_req_failed` 54.9-55.3% (reproduced twice), `checks` ~44-45% pass.
  `successful_patches` counter: 2457-2465 (varies by run, as expected for a race).
- `mixed-load` (ramp to 50 VUs, 50s total): k6 thresholds fail —
  `http_req_failed` 67.96%. Per-iteration `createTodo()` throws on every 502
  (it's called inside the default function, not setup), producing ~60k duplicate
  stack traces in the raw log (trimmed for evidence — see `mixed-load.log`).
- In both scenarios, the invariant checker's own post-run `GET /todos` lands
  during the same failure window and gets nginx's HTML error page back, so
  `node scripts/invariants.mjs` crashes on `JSON.parse` (`race-patch.invariants.txt`,
  `mixed-load.invariants.txt` capture that crash).

## Root cause (confirmed by direct reproduction, not guessed)

`apps/web/nginx.conf`'s `location /api/` proxies to `http://api:3000` with
`proxy_http_version 1.1` but no `keepalive` upstream pool and no
`proxy_set_header Connection ""`. Every proxied request therefore opens a brand
new TCP connection from nginx to the api container and does not reuse it.

Confirmed in the web container's nginx error log during a reproduction run:

```
2026/10/01 16:55:40 [crit] 22#22: *16 connect() to 172.22.0.3:3000 failed
  (99: Address not available) while connecting to upstream, client: 172.22.0.5,
  server: _, request: "PATCH /api/todos/6216f271-... HTTP/1.1",
  upstream: "http://172.22.0.3:3000/api/todos/6216f271-...", host: "web:8080"
172.22.0.5 - - [01/Oct/2026:16:55:40 +0000] "PATCH /api/todos/... HTTP/1.1" 502 157 ...
```

`errno 99 / EADDRNOTAVAIL` on an outbound `connect()` is ephemeral-port exhaustion:
the container's `net.ipv4.ip_local_port_range` is the Linux default
`32768-60999` (~28,231 ports) and `tcp_fin_timeout` is the default 60s. At
~2,000-2,900 req/s (observed, matching k6's reported `http_reqs` rate) each
opening a new unpooled connection, TIME_WAIT sockets accumulate faster than the
60s window recycles them, well past what the port range can hold — so new
outbound connections start failing with `EADDRNOTAVAIL`, and nginx answers the
client with 502.

Reproduced twice independently against a fresh `review-debug`/`review-debug2`
stack (not the `review-stress` project, so it did not touch the run already
captured in this evidence folder):
- Run 1 (50 VUs / 30s, exact `k6/race-patch.js`): `http_req_failed` 55.32%,
  `successful_patches` 2465.
- Run 2 (same script): `http_req_failed` 54.92%, `successful_patches` 2457.
- Polled `GET /api/todos` once per second immediately after run 2 ended: 502 for
  at least 10 straight seconds, still 502 at t+5s and t+10s on the next poll,
  first 200 at roughly t+15s. Full recovery by t+20s. This matches the TIME_WAIT
  drain time for the burst of connections opened in the run's last ~20s.

## This is an availability bug, not a data-correctness bug

After letting the stack recover (t+20s), fetched `GET /api/todos` for the
reproduction run and checked the same invariant `scripts/invariants.mjs` checks
for `race-patch`:

```
todos count: 5
raced count: 5
version gain sum: 2457
```

`2457` exactly matches that run's `successful_patches` counter (`2457`) from the
k6 summary. Optimistic concurrency (the `version` compare-and-swap in
`PgTodoRepository.update`/`delete`) held with zero lost or phantom updates even
under the request storm — the bug is specifically that nginx stops being able to
reach the API at all once connection churn exceeds the ephemeral port supply,
not that the API corrupts state when it is reached.

## Why this isn't a test-script bug

- The two failing scenarios (`race-patch`, `mixed-load`) are exactly the two
  with sustained, un-paced, 30-50s-long load at up to 50 VUs; the three passing
  scenarios (`parallel-complete`, `delete-storm`, `idempotent-replay`) all use
  bounded `iterations` that the app's actual throughput (~2,000+ req/s) finishes
  in roughly a second, never sustaining load long enough to exhaust the port
  range. The failure tracks the load *duration*, not scenario logic.
- `net.ipv4.ip_local_port_range 32768-60999` and `tcp_fin_timeout 60` are the
  stock Linux defaults inside the container — not a constrained or
  non-representative test host.
- The fix is a one-line nginx config change (an `upstream { keepalive N; }`
  block + `proxy_set_header Connection ""`) in `apps/web/nginx.conf`, which is
  app code, out of scope for this review repo to patch.

## Per-scenario results

| Scenario            | k6 thresholds | Invariant check                              |
|----------------------|--------------|-----------------------------------------------|
| race-patch           | FAIL (`http_req_failed` 55.32%, `checks` 44.62%) | CRASHED (502 HTML body, not JSON) |
| parallel-complete     | PASS          | PASS (both checks)                            |
| delete-storm          | PASS          | PASS (both checks)                            |
| idempotent-replay     | PASS          | PASS                                           |
| mixed-load            | FAIL (`http_req_failed` 67.96%, `checks` 99.65%) | CRASHED (502 HTML body, not JSON) |

p95 `GET /todos` latency (mixed-load, the only scenario with that threshold):
**30.83ms**, well under the 250ms budget — the app itself is fast; it's the
proxy's connection handling under load that fails.
