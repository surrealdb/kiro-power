# SurrealDB MCP

Use this steering when the user asks Kiro to inspect, query, administer, or troubleshoot SurrealDB through the SurrealMCP server.

## Transports

SurrealMCP supports two transports. Do not guess which one the user is using — ask if it is not clear.

**stdio** (local SurrealDB CLI):

The `mcp.json` bundled with this power configures stdio automatically. Requires the `surreal` CLI to be installed and the following environment variables to be set:

| Variable | Description |
| --- | --- |
| `SURREALDB_HOST` | Endpoint for the `instance` server, e.g. `http://localhost:8000` |
| `SURREALDB_USER` | Database username |
| `SURREALDB_PASSWORD` | Database password |
| `SURREALDB_NAMESPACE` | Namespace (optional) |
| `SURREALDB_NAME` | Database name (optional) |

**HTTP** (remote or SurrealDB Cloud):

Add the server manually in Kiro using the MCP endpoint URL:

```
https://<cloud-instance>/mcp
http://127.0.0.1:8000/mcp
```

The endpoint must expose MCP over HTTP. A plain SQL, REST, or WebSocket endpoint is not sufficient unless it also serves `/mcp`.

For bearer auth, set the token in the MCP server configuration. A `surreal-bearer-...` grant key is not the same as a final HTTP auth token — it must be exchanged via SurrealDB signin first.

## Usage Notes

- Treat all query and mutation tools as real database operations with side effects.
- Confirm intent before schema changes, bulk writes, deletes, or permission changes.
- Use `INFO FOR DB` to inspect the current schema before making structural changes.

## Useful Starter Requests

- Inspect the active namespace and database schema.
- Run a read-only SurrealQL query and summarize the results.
- Show all tables and their field definitions.
- Connect to my SurrealDB Cloud MCP URL.
