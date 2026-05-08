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
| `local` | stdio | Self-hosted SurrealDB at `ws://localhost:8000` |
| `cloud` | stdio | SurrealDB Cloud |

Both servers use the SurrealDB CLI (`surreal mcp stdio`) and require the following environment variables:

| Variable | Description |
| --- | --- |
| `SURREAL_USER` | Database username |
| `SURREAL_PASS` | Database password |
| `SURREAL_NS` | Namespace (optional) |
| `SURREAL_DB` | Database (optional) |

## License

[Apache-2.0](LICENSE)
