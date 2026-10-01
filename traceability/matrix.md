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
| FR-8 | Filter (all/completed/incomplete/overdue) | | | Planned |
| FR-9 | Sort (createdAt/dueDate/title, asc/desc) | | | Planned |
| FR-10 | In-app developer documentation | | | Planned |
| DR-1 | id: server UUID | | | Planned |
| DR-2 | title: required, trimmed, 1–200 | `packages/shared/src/todo.ts` (TitleSchema) | `packages/shared/tests/todo.test.ts` | In progress |
| DR-3 | description: optional, ≤2000, '' → null | `packages/shared/src/todo.ts` (DescriptionSchema) | `packages/shared/tests/todo.test.ts` | In progress |
| DR-4 | dueDate: real YYYY-MM-DD, past allowed | `packages/shared/src/todo.ts` (DueDateSchema) | `packages/shared/tests/todo.test.ts` | In progress |
| DR-5 | isCompleted: default false | | | Planned |
| DR-6 | createdAt: UTC timestamp | | | Planned |
| DR-7 | version: read-only, ETag | `packages/shared/src/todo.ts` (TodoViewSchema.version), `packages/shared/src/headers.ts` (IfMatchSchema, toEtag) | `packages/shared/tests/todo.test.ts`, `packages/shared/tests/headers.test.ts` | In progress |
| DR-8 | isOverdue: derived, UTC | | | Planned |
| NFR-0 | Docker is the only prerequisite | `Dockerfile` (base/deps/source/test), `compose.yaml` (`test`, `dev`, `db-test` services) | `.github/workflows/ci.yml` (runs `docker compose --profile test run --rm --build test`) | In progress (test/dev harness only; `api`/`web`/`e2e`/`migrate` targets land in later PRs) |
| NFR-1 | TypeScript on Node 24 LTS | `package.json` (engines, devDependencies), `.nvmrc`, `tsconfig.base.json`, `Dockerfile` (`node:24.21-alpine`) | `.github/workflows/ci.yml`, `npm run typecheck` in `test:ci` | Done |
| NFR-2 | Persistence (Postgres volume) | | | Planned |
| NFR-3 | Storage behind ports, two adapters | | | Planned |
| NFR-4 | Concurrency guarantees | | | Planned |
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
