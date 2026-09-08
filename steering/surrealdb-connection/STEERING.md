# SurrealDB Connection

Use this steering when connecting to a SurrealDB instance — whether it is self-hosted (local or your own server) or a managed SurrealDB Cloud instance. The connection flow is the same in both cases; only the endpoint and how it is provisioned differ.

## Connection targets

| Target | Endpoint format | Notes |
| --- | --- | --- |
| Local (self-hosted) | `ws://localhost:8000/rpc`, `http://localhost:8000` | You run the server yourself with `surreal start` (see below) |
| Remote (self-hosted) | `wss://<host>/rpc`, `https://<host>` | Your own server behind TLS |
| SurrealDB Cloud | `wss://<instance>.surreal.cloud/rpc`, `https://<instance>.surreal.cloud` | Managed; always TLS (`wss`/`https`). Copy the endpoint from the Cloud dashboard or Surrealist — you do **not** run `surreal start` for Cloud |

In all cases: **connect → `USE` a namespace and database → sign in**, then run queries. Cloud instances are always encrypted, so use `wss://` / `https://` (never `ws://`/`http://`).

## Starting a SurrealDB Server

This section applies to **self-hosted** instances only — a SurrealDB Cloud instance is already running and managed for you. For full CLI coverage of `surreal start` and storage backends, see the `surrealdb-cli` steering.

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

## HTTP REST API

SurrealDB exposes an HTTP API at the same port as the WebSocket server.

### Health Check

```bash
curl http://localhost:8000/health
```

### Running a Query

```bash
curl -X POST http://localhost:8000/sql \
  -H "Accept: application/json" \
  -H "NS: my_namespace" \
  -H "DB: my_database" \
  -u root:root \
  --data "SELECT * FROM person"
```

### Key-Value REST Endpoints

```bash
# Select all records in a table
curl http://localhost:8000/key/person \
  -H "NS: my_namespace" \
  -H "DB: my_database" \
  -u root:root

# Create a record
curl -X POST http://localhost:8000/key/person \
  -H "Content-Type: application/json" \
  -H "NS: my_namespace" \
  -H "DB: my_database" \
  -u root:root \
  -d '{"name": "Alice", "age": 30}'

# Select a specific record
curl http://localhost:8000/key/person/alice \
  -H "NS: my_namespace" \
  -H "DB: my_database" \
  -u root:root
```

## Authentication

### Root Credentials

Root-level signin grants full access to all namespaces and databases:

```json
{ "username": "root", "password": "root" }
```

### Record Access (User-Defined)

Use record access for application-level authentication defined with `DEFINE ACCESS`:

```json
{
  "namespace": "my_namespace",
  "database": "my_database",
  "access": "account",
  "variables": {
    "email": "alice@example.com",
    "password": "secret"
  }
}
```

### JWT / Bearer Token

If the server has issued a JWT (e.g. after signin), pass it as a Bearer token:

```bash
curl http://localhost:8000/sql \
  -H "Authorization: Bearer <jwt>" \
  -H "NS: my_namespace" \
  -H "DB: my_database" \
  --data "SELECT * FROM person"
```

## Connection Tips

- A namespace and database **must** be selected before running data queries. Calling `USE NS ... DB ...` or `db.use(ns, db)` is required after signin.
- The WebSocket connection is stateful — signin and `USE` selection persist for the lifetime of the connection.
- HTTP requests are stateless — include `NS`, `DB`, and `Authorization` headers on every request.
- Use `INFO FOR DB` to inspect the currently selected database's schema.
- **SurrealDB Cloud**: the endpoint and root credentials come from the Cloud dashboard (or Surrealist) — create root auth in the instance's Authentication panel. Connections are always TLS (`wss://` / `https://`); a plain `ws://`/`http://` endpoint will not work. To drive a Cloud instance through MCP tools, see the `database-mcp` steering.
