# Findings log

Severity: High (wrong behaviour or data risk) · Medium (robustness, maintainability) · Low (polish).
Decision: Fix · Accept (with reason) · Reject (with reason).

| ID | PR | Severity | Category | Finding | Decision | Resolution |
|---|---|---|---|---|---|---|
| F-1 | 1 | Low | tests | v8 coverage report's per-file row shows `packages/shared/src/index.ts` at 0% while the aggregate (gate-checked) `total` row is 100% — cosmetic artifact for a file with zero coverable statements | Accept | pending PR #1 merge |
| F-2 | 1 | Low | tests | `packages/shared/tests/headers.test.ts` rejects `"1000000000"` (10 digits) rather than the spec's literal boundary example `"9999999999"`; behaviourally equivalent (same regex boundary) | Accept | pending PR #1 merge |
| F-3 | 2 | Important | correctness | In-memory `TodoRepository`/`IdempotencyStore` leaked reference-typed `Date`/`body` fields through shallow-spread copies (`{ ...todo }`), letting a caller's mutation of a returned value silently corrupt the stored row — behaviour Postgres cannot reproduce | Fix | Fixed in PR #2 (folded into branch) via `structuredClone` on every copy-in/copy-out path, with two new contract tests (`'returns detached dates'`, `'stores and returns detached records'`) |
| F-4 | 2 | Low | tests | Speculative `coverage.exclude` entry added for the types-only `repository/ports.ts` without first confirming the gate needed it | Fix | Fixed in PR #2 (folded into branch) — removed after the full gate confirmed 100/100/100/100 without it |
| F-5 | 2 | Low | docs | Commit `c54f188`'s message says it "excludes types-only ports.ts from coverage thresholds," but the final squashed commit carries no such `vitest.config.ts` change | Accept | pending PR #2 merge |
