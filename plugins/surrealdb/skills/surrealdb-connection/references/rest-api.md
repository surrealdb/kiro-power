---
title: HTTP REST API
---

# HTTP REST API

SurrealDB exposes an HTTP API at the same port as the WebSocket server. HTTP requests are **stateless** — every request must carry the `NS` and `DB` headers and its own credentials.

## Health Check

```bash
curl http://localhost:8000/health
```

Returns `200 OK` when the instance is up. This is the cheapest way to confirm an endpoint is reachable before attempting a connection.

## Running a Query

```bash
curl -X POST http://localhost:8000/sql \
  -H "Accept: application/json" \
  -H "NS: my_namespace" \
  -H "DB: my_database" \
  -u root:root \
  --data "SELECT * FROM person"
```

The body is raw SurrealQL. Multiple statements separated by `;` return an array of results, one per statement.

## Key-Value REST Endpoints

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

## When to prefer HTTP over WebSocket

- One-off scripts, health checks, and CI steps, where a persistent connection is not worth opening.
- Environments without WebSocket support.

For anything long-lived, or for live queries, use the WebSocket `/rpc` endpoint instead — it keeps signin and `USE` selection for the lifetime of the connection.
