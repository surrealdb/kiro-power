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
| `surrealql-performance` | slow queries, performance, record id design, indexing, EXPLAIN, computed fields |
| `surrealql-functions` | built-in functions, function signatures, `string::`/`array::`/`math::`, LSP |
| `surrealdb-cli` | `surreal start`, `surreal sql`, import/export, CLI, running a server |
| `surrealkit` | SurrealKit, schema migrations, rollouts, typegen, schema tests |
| `surrealdb-python` | Python SDK, surrealdb Python, embedded |
| `surrealdb-js` | JavaScript/TypeScript SDK, surrealdb npm, live queries |
| `surrealdb-vector` | vector search, HNSW, KNN, RAG, embeddings |
| `surrealdb-connection` | connect, local or cloud instance, server, authentication, WebSocket |
| `database-mcp` | MCP, inspect, query via tools |

## MCP

Since SurrealDB 3.1, every running instance serves the [Model Context Protocol](https://surrealdb.com/mcp) directly over HTTP at the `/mcp` route — no separate proxy process is needed. This power ships two pre-configured servers:

| Server | Transport | Use for |
| --- | --- | --- |
| `instance` | HTTP | A locally running self-hosted SurrealDB (`http://127.0.0.1:8000/mcp`) |
| `cloud` | HTTP | SurrealDB Cloud or a remote instance |

`/mcp` is served on the same port as the instance's RPC/HTTP API (default `127.0.0.1:8000`).

The `instance` server works out of the box against a local development instance. For a secured instance, add an `Authorization` header to its entry in `mcp.json`.

The `cloud` server reads two environment variables:

| Variable | Description |
| --- | --- |
| `SURREALDB_MCP_URL` | The instance's MCP endpoint, e.g. `https://<instance>.surreal.cloud/mcp` |
| `SURREALDB_TOKEN` | Bearer token used in the `Authorization` header |

## License

[Apache-2.0](LICENSE)
