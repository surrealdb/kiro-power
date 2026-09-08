# SurrealDB MCP

Use this steering when the user asks Kiro to inspect, query, administer, or troubleshoot SurrealDB through SurrealDB's MCP server.

## Per-instance MCP (SurrealDB 3.1+)

Since SurrealDB 3.1, every running instance serves the Model Context Protocol directly over HTTP at the `/mcp` route — there is no separate proxy process to run. The `mcp.json` bundled with this power connects to that endpoint:

| Server | URL | Use for |
| --- | --- | --- |
| `instance` | `http://127.0.0.1:8000/mcp` | A locally running self-hosted instance |
| `cloud` | `${SURREALDB_MCP_URL}` | SurrealDB Cloud or a remote instance |

`/mcp` is served on the **same port** as the instance's RPC/HTTP API (default `127.0.0.1:8000`, set with `surreal start --bind`). A plain SQL, REST, or WebSocket endpoint is not sufficient unless that same instance also serves `/mcp`. Confirm an instance is reachable with `curl -s http://127.0.0.1:8000/health`.

## Authentication

- A local development instance started without auth needs no header.
- A secured instance requires an `Authorization` header. Add one to the server entry in `mcp.json`:

  ```json
  "headers": { "Authorization": "Bearer ${SURREALDB_TOKEN}" }
  ```

  Basic auth with root credentials (`Authorization: Basic <base64(user:pass)>`) also works against a self-hosted instance.
- For bearer auth, a `surreal-bearer-...` grant key is **not** a final HTTP auth token — it must be exchanged via SurrealDB signin first to obtain the JWT you pass as the Bearer token.
- For SurrealDB Cloud, set `url` to the instance's `/mcp` URL and authenticate via `headers` (or Kiro's `oauth` config).

## Local stdio (server-less) alternative

If no server is running, `surreal mcp [PATH]` starts an MCP server over **stdio** backed by an embedded datastore (`memory` by default, or `rocksdb:`/`surrealkv:` for persistence). It is configured with `SURREAL_PATH`, `SURREAL_MCP_NS`, `SURREAL_MCP_DB`, `SURREAL_USER`, and `SURREAL_PASS`. This power configures the HTTP per-instance servers above rather than stdio, but the stdio mode is useful for quick, server-less local exploration.

## Usage Notes

- Treat all query and mutation tools as real database operations with side effects.
- Confirm intent before schema changes, bulk writes, deletes, or permission changes.
- Use `INFO FOR DB` to inspect the current schema before making structural changes.

## Useful Starter Requests

- Inspect the active namespace and database schema.
- Run a read-only SurrealQL query and summarize the results.
- Show all tables and their field definitions.
- Connect to my SurrealDB Cloud MCP URL.
