# SurrealDB Kiro Power

SurrealDB power for [Kiro](https://kiro.dev).

## Install

In Kiro, open the Powers panel and click **Add power from GitHub**, then enter:

```
surrealdb/kiro-power
```

## What's included

| Steering file | Activated when you mention |
| --- | --- |
| `surrealql` | SurrealQL, surql, queries, schema |
| `surrealdb-python` | Python SDK, surrealdb Python, embedded |
| `surrealdb-vector` | vector search, HNSW, KNN, RAG, embeddings |
| `surrealdb-connection` | connect, server, authentication, WebSocket |
| `database-mcp` | MCP, surrealmcp, inspect, query via tools |

## MCP

This power includes [SurrealMCP](https://surrealdb.com/mcp) with two pre-configured servers:

| Server | Transport | Use for |
| --- | --- | --- |
| `instance` | stdio | Self-hosted SurrealDB |
| `cloud` | stdio | SurrealDB Cloud |

Both servers use the SurrealDB CLI (`surreal mcp stdio`) and require the following environment variables:

| Variable | Description |
| --- | --- |
| `SURREALDB_USER` | Database username |
| `SURREALDB_PASSWORD` | Database password |
| `SURREALDB_NAMESPACE` | Namespace (optional) |
| `SURREALDB_NAME` | Database name (optional) |

The `instance` server also requires:

| Variable | Description |
| --- | --- |
| `SURREALDB_HOST` | SurrealDB endpoint, e.g. `http://localhost:8000` |

## License

[Apache-2.0](LICENSE)
