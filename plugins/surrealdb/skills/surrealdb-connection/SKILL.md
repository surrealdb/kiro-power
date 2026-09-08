---
name: surrealdb-connection
description: "Connect to a SurrealDB instance — self-hosted (local or your own server) or managed SurrealDB Cloud — covering endpoint formats, the connect/USE/sign-in sequence, `SURREAL_*` environment variables, the WebSocket `/rpc` protocol, the stateless HTTP REST API, and root, record access, and JWT authentication. Use when picking or troubleshooting a connection endpoint, starting a server to connect to, choosing between WebSocket and HTTP, or deciding how an application should authenticate. Triggers: connect to SurrealDB, connection string, ws://, wss://, /rpc, surreal.cloud, signin, USE NS, DEFINE ACCESS, bearer token, SURREAL_BIND, /health."
metadata:
  author: surrealdb
  version: "0.1.0"
---

# SurrealDB Connection

Use this skill when connecting to a SurrealDB instance — whether it is self-hosted (local or your own server) or a managed SurrealDB Cloud instance. The connection flow is the same in both cases; only the endpoint and how it is provisioned differ.

## Connection targets

| Target | Endpoint format | Notes |
| --- | --- | --- |
| Local (self-hosted) | `ws://localhost:8000/rpc`, `http://localhost:8000` | You run the server yourself with `surreal start` (see below) |
| Remote (self-hosted) | `wss://<host>/rpc`, `https://<host>` | Your own server behind TLS |
| SurrealDB Cloud | `wss://<instance>.surreal.cloud/rpc`, `https://<instance>.surreal.cloud` | Managed; always TLS (`wss`/`https`). Copy the endpoint from the Cloud dashboard or Surrealist — you do **not** run `surreal start` for Cloud |

In all cases: **connect → `USE` a namespace and database → sign in**, then run queries. Cloud instances are always encrypted, so use `wss://` / `https://` (never `ws://`/`http://`).

## Starting a SurrealDB Server

This section applies to **self-hosted** instances only — a SurrealDB Cloud instance is already running and managed for you. For full CLI coverage of `surreal start` and storage backends, use the **surrealdb-cli** skill.

In-memory (data lost on restart):

```bash
surreal start -u root -p root
```

Persistent with RocksDB:

```bash
surreal start -u root -p root rocksdb:./data
```

Bind to a specific address:

```bash
surreal start --bind 0.0.0.0:8000 -u root -p root rocksdb:./data
```

## Environment Variables

| Variable | Description |
| --- | --- |
| `SURREAL_BIND` | Listen address (default: `0.0.0.0:8000`) |
| `SURREAL_USER` | Root username |
| `SURREAL_PASS` | Root password |
| `SURREAL_NS` | Default namespace |
| `SURREAL_DB` | Default database |
| `SURREAL_LOG` | Log level (`trace`, `debug`, `info`, `warn`, `error`) |

## WebSocket Connection

SurrealDB's primary connection protocol for SDK and RPC communication is WebSocket over `/rpc`.

```
ws://localhost:8000/rpc           # local, unencrypted
wss://myhost.example.com/rpc      # remote self-hosted, TLS
wss://<instance>.surreal.cloud/rpc  # SurrealDB Cloud, always TLS
```

**After connecting, always:**
1. Sign in with credentials
2. Select a namespace and database before running queries

Example (Python):

```python
from surrealdb import Surreal

# Local: "ws://localhost:8000/rpc"
# Cloud: "wss://<instance>.surreal.cloud/rpc"
with Surreal("wss://<instance>.surreal.cloud/rpc") as db:
    db.signin({"username": "root", "password": "root"})
    db.use("my_namespace", "my_database")
    result = db.query("SELECT * FROM person")
```

## Connection Tips

- A namespace and database **must** be selected before running data queries. Calling `USE NS ... DB ...` or `db.use(ns, db)` is required after signin.
- The WebSocket connection is stateful — signin and `USE` selection persist for the lifetime of the connection.
- HTTP requests are stateless — include `NS`, `DB`, and `Authorization` headers on every request.
- Use `INFO FOR DB` to inspect the currently selected database's schema.
- **SurrealDB Cloud**: the endpoint and root credentials come from the Cloud dashboard (or Surrealist) — create root auth in the instance's Authentication panel. Connections are always TLS (`wss://` / `https://`); a plain `ws://`/`http://` endpoint will not work. To drive a Cloud instance through MCP tools, use the **surrealdb-mcp** skill.

## References

- [references/rest-api.md](references/rest-api.md) — the stateless HTTP API: health check, `/sql`, and the key-value `/key/...` endpoints.
- [references/authentication.md](references/authentication.md) — root credentials, record access defined with `DEFINE ACCESS`, and JWT/bearer tokens.
