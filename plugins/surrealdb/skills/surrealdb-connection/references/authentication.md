---
title: Authentication
---

# Authentication

SurrealDB has three authentication models. Pick the narrowest one that works: root credentials for administration, record access for application users, JWT for anything that already holds a token.

## Root Credentials

Root-level signin grants full access to all namespaces and databases:

```json
{ "username": "root", "password": "root" }
```

Use this for local development, administration, and migrations. Do not ship root credentials to an application client.

## Record Access (User-Defined)

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

The `access` name and the `variables` keys are whatever the `DEFINE ACCESS ... TYPE RECORD` definition declares. For writing those definitions, use the **surrealql** skill.

## JWT / Bearer Token

If the server has issued a JWT (for example after signin), pass it as a Bearer token:

```bash
curl http://localhost:8000/sql \
  -H "Authorization: Bearer <jwt>" \
  -H "NS: my_namespace" \
  -H "DB: my_database" \
  --data "SELECT * FROM person"
```

The same token works on the WebSocket connection through the `authenticate` RPC method.

## Notes

- Tokens carry their own namespace/database/access scope. A token minted for one database will not authorise queries against another.
- On **SurrealDB Cloud**, create root auth in the instance's Authentication panel; the endpoint and credentials both come from the Cloud dashboard or Surrealist.
