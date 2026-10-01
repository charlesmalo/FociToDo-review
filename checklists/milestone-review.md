# Milestone review checklist (per app PR)

## Correctness
- [ ] Behaviour matches the spec sections the PR claims (status codes, headers, validation messages)
- [ ] Error precedence 400 → 428 → 404 → 412 preserved
- [ ] No silent catch-alls; unexpected errors become logged 500s

## Concurrency
- [ ] Every write is a single statement or inside the unit of work
- [ ] Version bumps only on real changes; conditional writes use the version
- [ ] New code paths covered by an invariant test if they touch shared state

## Tests
- [ ] Test written first (visible in the commit) and mirrors the source path
- [ ] 100% coverage without `v8 ignore`
- [ ] Assertions check behaviour, not implementation details or timings

## Architecture
- [ ] Layer rules respected (lint passes); composition only in `app.ts`
- [ ] No new dependency without a reason in the commit or an ADR

## Docs
- [ ] README / guides / OpenAPI still accurate (no drift)
- [ ] New decisions recorded as ADRs

## Security & operability
- [ ] Inputs validated with shared schemas; no secrets or stack traces in responses
- [ ] Images non-root; no dev dependencies in runtime images
