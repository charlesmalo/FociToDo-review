# Findings log

Severity: High (wrong behaviour or data risk) · Medium (robustness, maintainability) · Low (polish).
Decision: Fix · Accept (with reason) · Reject (with reason).

| ID | PR | Severity | Category | Finding | Decision | Resolution |
|---|---|---|---|---|---|---|
| F-1 | 1 | Low | tests | v8 coverage report's per-file row shows `packages/shared/src/index.ts` at 0% while the aggregate (gate-checked) `total` row is 100% — cosmetic artifact for a file with zero coverable statements | Accept | pending PR #1 merge |
| F-2 | 1 | Low | tests | `packages/shared/tests/headers.test.ts` rejects `"1000000000"` (10 digits) rather than the spec's literal boundary example `"9999999999"`; behaviourally equivalent (same regex boundary) | Accept | pending PR #1 merge |
