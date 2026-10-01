# Requirements traceability

| ID | Requirement | Implemented in | Verified by | Status |
|---|---|---|---|---|
| FR-1 | Add a to-do | | | Planned |
| FR-2 | List all to-dos | | | Planned |
| FR-3 | View a to-do by ID | | | Planned |
| FR-4 | Update title/description/due date | | | Planned |
| FR-5 | Mark complete | | | Planned |
| FR-6 | Mark incomplete | | | Planned |
| FR-7 | Delete | | | Planned |
| FR-8 | Filter (all/completed/incomplete/overdue) | `apps/api/src/repository/in-memory/ordering.ts` (`matchesStatus`), `apps/api/src/repository/in-memory/InMemoryTodoRepository.ts` (`list`) | `apps/api/tests/repository/in-memory/ordering.test.ts`, `apps/api/tests/repository/repository.contract.ts` | In progress (storage-level filtering only; HTTP wiring lands in PR 5) |
| FR-9 | Sort (createdAt/dueDate/title, asc/desc) | `apps/api/src/repository/in-memory/ordering.ts` (`compareTodos`, `compareCodePoints`) | `apps/api/tests/repository/in-memory/ordering.test.ts`, `apps/api/tests/repository/repository.contract.ts` | In progress (storage-level sorting only; HTTP wiring lands in PR 5) |
| FR-10 | In-app developer documentation | | | Planned |
| DR-1 | id: server UUID | `apps/api/src/domain/ids.ts` (`IdGenerator`, `uuidGenerator`), `apps/api/src/domain/todo.ts` (`Todo.id`) | `apps/api/tests/domain/ids.test.ts` | In progress (domain port in place; server-side enforcement — rejecting client-supplied `id` at the HTTP layer is already in `packages/shared/src/todo.ts`'s strict schemas from PR 1 — the generator is wired into creation by `TodoService` in a later PR) |
| DR-2 | title: required, trimmed, 1–200 | `packages/shared/src/todo.ts` (TitleSchema) | `packages/shared/tests/todo.test.ts` | In progress |
| DR-3 | description: optional, ≤2000, '' → null | `packages/shared/src/todo.ts` (DescriptionSchema) | `packages/shared/tests/todo.test.ts` | In progress |
| DR-4 | dueDate: real YYYY-MM-DD, past allowed | `packages/shared/src/todo.ts` (DueDateSchema) | `packages/shared/tests/todo.test.ts` | In progress |
| DR-5 | isCompleted: default false | `apps/api/src/domain/todo.ts` (`Todo.isCompleted` field) | — | In progress (field defined and persisted faithfully by the in-memory repository; the default-false-on-creation rule is applied by `TodoService.create`, not yet implemented) |
| DR-6 | createdAt: UTC timestamp | `apps/api/src/domain/todo.ts` (`Todo.createdAt`, `toView` serialises via `toISOString()`), `apps/api/src/domain/clock.ts` (`Clock`, `systemClock`, `utcDate`) | `apps/api/tests/domain/todo.test.ts`, `apps/api/tests/domain/clock.test.ts`, `apps/api/tests/repository/repository.contract.ts` ('returns detached dates') | In progress (domain/repository round-trip proven; HTTP exposure lands in PR 5) |
| DR-7 | version: read-only, ETag | `packages/shared/src/todo.ts` (TodoViewSchema.version), `packages/shared/src/headers.ts` (IfMatchSchema, toEtag), `apps/api/src/domain/todo.ts` (`Todo.version`), `apps/api/src/repository/ports.ts` (`expectedVersion` params), `apps/api/src/repository/in-memory/InMemoryTodoRepository.ts` (conditional update/delete, version-bump rules) | `packages/shared/tests/todo.test.ts`, `packages/shared/tests/headers.test.ts`, `apps/api/tests/repository/repository.contract.ts` | In progress (storage-level version gating proven; HTTP ETag/If-Match wiring lands in PR 5) |
| DR-8 | isOverdue: derived, UTC | `apps/api/src/domain/todo.ts` (`isOverdue`, `toView`), `apps/api/src/repository/in-memory/ordering.ts` (`matchesStatus` 'overdue') | `apps/api/tests/domain/todo.test.ts`, `apps/api/tests/repository/in-memory/ordering.test.ts`, `apps/api/tests/repository/repository.contract.ts` | In progress (domain/storage-level derivation proven; HTTP response exposure lands in PR 5) |
| NFR-0 | Docker is the only prerequisite | `Dockerfile` (base/deps/source/test), `compose.yaml` (`test`, `dev`, `db-test` services) | `.github/workflows/ci.yml` (runs `docker compose --profile test run --rm --build test`) | In progress (test/dev harness only; `api`/`web`/`e2e`/`migrate` targets land in later PRs) |
| NFR-1 | TypeScript on Node 24 LTS | `package.json` (engines, devDependencies), `.nvmrc`, `tsconfig.base.json`, `Dockerfile` (`node:24.21-alpine`) | `.github/workflows/ci.yml`, `npm run typecheck` in `test:ci` | Done |
| NFR-2 | Persistence (Postgres volume) | | | Planned |
| NFR-3 | Storage behind ports, two adapters | `apps/api/src/repository/ports.ts` (`TodoRepository`, `IdempotencyStore`, `UnitOfWork`, `Storage`), `apps/api/src/repository/in-memory/*` (first adapter: `InMemoryDatabase`, `InMemoryTodoRepository`, `InMemoryIdempotencyStore`, `InMemoryUnitOfWork`, `createInMemoryStorage`, `AsyncMutex`, `ordering.ts`) | `apps/api/tests/repository/repository.contract.ts` (adapter-agnostic contract), `apps/api/tests/repository/in-memory/createInMemoryStorage.test.ts`, `apps/api/tests/repository/in-memory/ordering.test.ts`, `apps/api/tests/repository/in-memory/AsyncMutex.test.ts` | In progress (one of two adapters done; the Postgres adapter in PR 3 must pass the same `repository.contract.ts` suite) |
| NFR-4 | Concurrency guarantees | `apps/api/src/repository/in-memory/AsyncMutex.ts`, `apps/api/src/repository/in-memory/InMemoryUnitOfWork.ts`, `apps/api/src/repository/in-memory/InMemoryDatabase.ts` (snapshot/rollback), `apps/api/src/repository/in-memory/InMemoryTodoRepository.ts` / `InMemoryIdempotencyStore.ts` (conditional, version-gated writes) | `apps/api/tests/repository/in-memory/AsyncMutex.test.ts`, `apps/api/tests/repository/repository.contract.ts` (UnitOfWork commit/rollback and the 5-way concurrent same-key claim race) | In progress (unit-of-work serialisation and version-gated writes proven for the in-memory adapter only; Postgres transactional guarantees and HTTP-level 412/428/422 wiring land in later PRs) |
| NFR-5 | Strict validation + problem details | | | Planned |
| NFR-6 | 100% coverage enforced | `vitest.config.ts` (thresholds: 100/100/100/100, exclusions), `package.json` (`test:ci`) | `reports/coverage/coverage-summary.json`, `.github/workflows/ci.yml` | Done |
| NFR-7 | Layer rules enforced by lint | `eslint.config.js` (`import-x/no-restricted-paths` zones for domain/service/repository/http and web/todos/dev) | Probed in `.superpowers/sdd/01-foundation-shared-contract/task-1-report.md` (zone fires correctly); no `apps/api/src` files exist yet to exercise it in CI | In progress (rule wired and positively probed; dormant until later PRs add the layered source files) |
| NFR-8 | Multi-stage, non-root, prod-only images | | | Planned |
| NFR-9 | Docs for humans and AI, Mermaid | | | Planned |
| NFR-10 | OpenAPI from Zod + explorer | | | Planned |
| D-1 | Public app repository | `github.com/charlesmalo/FociToDo` | — | Done |
| D-2 | README: build/run | | | Planned |
| D-3 | README: tests | | | Planned |
| D-4 | README: design and testing rationale | | | Planned |
| D-5 | README: assumptions | | | Planned |
| D-6 | README: trade-offs | | | Planned |
| D-7 | Curated commit history via PRs | | | Planned |
| D-8 | Public review repository | | | Planned |
| D-9 | CI with the README's Docker commands | `.github/workflows/ci.yml` (runs `docker compose --profile test run --rm --build test`) | — | In progress (README's full command set — `up`, e2e, images — not written yet; CI test job matches the test command already) |
