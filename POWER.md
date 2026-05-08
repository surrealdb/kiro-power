---
name: "surrealdb"
displayName: "SurrealDB"
description: "SurrealDB power for Kiro — SurrealQL, Python SDK, vector search, and direct connection guidance."
keywords: ["surrealdb", "surreal", "surrealql", "surql", "surrealmcp", "mcp", "surrealdb-python", "hnsw", "vector search"]
author: "SurrealDB"
---

# SurrealDB

## Onboarding

Check that the SurrealDB CLI is available:

```bash
surreal version
```

If the command is not found, direct the user to https://surrealdb.com/install for installation instructions.

Create the following hooks in `.kiro/hooks/`:

**surrealdb-validate.json** — validate `.surql` files on save:
- Trigger: File Save, pattern `**/*.surql`
- Action: Run Command `surreal validate ${file}`

**surrealdb-format.json** — format `.surql` files on save:
- Trigger: File Save, pattern `**/*.surql`
- Action: Run Command `npx @surrealdb/surql-fmt --write ${file}`

**surrealdb-health.json** — check server status on demand:
- Trigger: Manual
- Action: Ask Kiro to run `surreal version` and `curl -s http://localhost:8000/health`, then report whether the server is reachable

## Steering

Route to the relevant steering file based on what the user is working on:

- Writing, modifying, or troubleshooting SurrealQL queries → `steering/surrealql.md`
- Using SurrealDB with Python → `steering/surrealdb-python.md`
- Vector search, HNSW indexes, KNN queries, semantic search, or RAG → `steering/surrealdb-vector.md`
- Connecting to SurrealDB, starting a server, or configuring authentication → `steering/surrealdb-connection.md`
- Using SurrealMCP, inspecting or querying via MCP tools → `steering/database-mcp/STEERING.md`
