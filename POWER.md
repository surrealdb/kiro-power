---
name: "surrealdb"
displayName: "SurrealDB"
description: "SurrealDB power for Kiro — SurrealQL, Python SDK, vector search, and direct connection guidance."
keywords: ["surrealdb", "surreal", "surrealql", "surql", "surrealmcp", "mcp", "surrealdb-python", "surrealdb-js", "typescript", "hnsw", "vector search", "surreal cli", "surrealkit", "migrations", "typegen", "indexing", "performance", "lsp"]
author: "SurrealDB"
---

# SurrealDB

## Onboarding

Check that the SurrealDB CLI is available:

```bash
surreal version
```

If the command is not found, direct the user to https://surrealdb.com/install for installation instructions.

Create the following hook file in `.kiro/hooks/`:

`.kiro/hooks/surrealdb-health.kiro.hook`
```json
{
  "enabled": true,
  "name": "SurrealDB Health Check",
  "description": "Check whether the local SurrealDB server is reachable",
  "version": "1",
  "when": {
    "type": "manual"
  },
  "then": {
    "type": "askAgent",
    "prompt": "Run `surreal version` and `curl -s http://localhost:8000/health`, then report whether the SurrealDB server is reachable and what version is installed."
  }
}
```

## Steering

Route to the relevant steering file based on what the user is working on:

- Writing, modifying, or troubleshooting SurrealQL queries → `steering/surrealql/STEERING.md`
- Optimizing performance — slow queries, record ID/key design, indexing strategy, `EXPLAIN`, computed fields → `steering/surrealql-performance/STEERING.md`
- Looking up a built-in SurrealQL function or its signature, or setting up the SurrealQL language server (LSP) → `steering/surrealql-functions/STEERING.md`
- Running, querying, importing/exporting, or operating SurrealDB from the terminal (`surreal start`, `surreal sql`, `surreal import`/`export`) → `steering/surrealdb-cli/STEERING.md`
- Managing schema with SurrealKit — project scaffolding, dev sync, production rollouts, type generation, declarative tests → `steering/surrealkit/STEERING.md`
- Using SurrealDB with Python → `steering/surrealdb-python/STEERING.md`
- Using SurrealDB from JavaScript or TypeScript (`surrealdb` npm SDK, embedded engines, live queries) → `steering/surrealdb-js/STEERING.md`
- Vector search, HNSW indexes, KNN queries, semantic search, or RAG → `steering/surrealdb-vector/STEERING.md`
- Connecting to a SurrealDB instance (local self-hosted or SurrealDB Cloud), starting a server, or configuring authentication → `steering/surrealdb-connection/STEERING.md`
- Using the SurrealDB MCP server, inspecting or querying via MCP tools → `steering/database-mcp/STEERING.md`
