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
| DR-2 | title: required, trimmed, 1–200 | | | Planned |
| DR-3 | description: optional, ≤2000, '' → null | | | Planned |
| DR-4 | dueDate: real YYYY-MM-DD, past allowed | | | Planned |
| DR-5 | isCompleted: default false | | | Planned |
| DR-6 | createdAt: UTC timestamp | | | Planned |
| DR-7 | version: read-only, ETag | | | Planned |
| DR-8 | isOverdue: derived, UTC | | | Planned |
| NFR-0 | Docker is the only prerequisite | | | Planned |
| NFR-1 | TypeScript on Node 24 LTS | | | Planned |
| NFR-2 | Persistence (Postgres volume) | | | Planned |
| NFR-3 | Storage behind ports, two adapters | | | Planned |
| NFR-4 | Concurrency guarantees | | | Planned |
| NFR-5 | Strict validation + problem details | | | Planned |
| NFR-6 | 100% coverage enforced | | | Planned |
| NFR-7 | Layer rules enforced by lint | | | Planned |
| NFR-8 | Multi-stage, non-root, prod-only images | | | Planned |
| NFR-9 | Docs for humans and AI, Mermaid | | | Planned |
| NFR-10 | OpenAPI from Zod + explorer | | | Planned |
| D-1 | Public app repository | | | Planned |
| D-2 | README: build/run | | | Planned |
| D-3 | README: tests | | | Planned |
| D-4 | README: design and testing rationale | | | Planned |
| D-5 | README: assumptions | | | Planned |
| D-6 | README: trade-offs | | | Planned |
| D-7 | Curated commit history via PRs | | | Planned |
| D-8 | Public review repository | | | Planned |
| D-9 | CI with the README's Docker commands | | | Planned |
