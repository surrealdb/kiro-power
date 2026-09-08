---
name: getting-started
description: "Set up the SurrealDB power after installation — check that the `surreal` CLI is installed, start or reach an instance, sign in to the bundled MCP servers, and optionally add a health-check hook. Use for first-run onboarding, when `surreal` is not found, when the power's MCP tools are unavailable or will not connect, or when the user asks how to get started with SurrealDB in Kiro. Triggers: install SurrealDB, surreal not found, command not found surreal, set up SurrealDB, power onboarding, MCP tools missing, Failed to connect, health check hook."
metadata:
  author: surrealdb
  version: "0.1.0"
---

# Getting started with the SurrealDB power

Run through this once after installing the power. Each step is independent — skip any that already holds.

## 1. Check the CLI

```bash
surreal version
```

If the command is not found, point the user to <https://surrealdb.com/install>. On macOS and Linux:

```bash
curl -sSf https://install.surrealdb.com | sh
```

The CLI is needed for local instances, `surreal validate`, imports and exports, and version detection. It is **not** needed to use SurrealDB Cloud through the bundled MCP server.

Target the latest stable 3.x release. If the installed CLI is on 2.x, say so — 2.x syntax differences are a common source of failures. Upgrade with `surreal upgrade`.

## 2. Reach an instance

**Local**, for development:

```bash
surreal start -u root -p root rocksdb:./data
curl -s http://127.0.0.1:8000/health
```

**SurrealDB Cloud**: the endpoint and credentials come from the Cloud dashboard or Surrealist. Nothing to start.

For storage backends, bind addresses, and the rest of `surreal start`, use the **surrealdb-cli** skill. For endpoints, `USE`, and authentication, use the **surrealdb-connection** skill.

## 3. Connect the MCP servers

This power bundles two, and Kiro manages both — they activate with the power and are not written into your own MCP settings.

| Server | What it needs |
| --- | --- |
| `surrealdb` (`https://mcp.surrealdb.com`) | Sign in with your Surreal ID when Kiro prompts on first use |
| `surrealdb-local` (`http://127.0.0.1:8000/mcp`) | An instance running on loopback port 8000 |

If neither is running you still get every skill in this power — they are knowledge, not tools. If a server will not connect, or you need to reach a remote instance, or the same tool name shows up twice, use the **surrealdb-mcp** skill.

## 4. Optional: a health-check hook

A hook that reports instance status at the start of each session. Offer it; do not create it unasked — it writes into the user's workspace at `.kiro/hooks/`.

The reliable way to create it is Kiro's own `createHook` tool, which writes whatever file format the installed Kiro version expects:

| Parameter | Value |
| --- | --- |
| `id` | `surrealdb-health-check` |
| `name` | `SurrealDB health check` |
| `description` | `Report whether a local SurrealDB instance is reachable` |
| `eventType` | `sessionStart` |
| `hookAction` | `askAgent` |
| `outputPrompt` | `Run \`surreal version\` and \`curl -s http://127.0.0.1:8000/health\`, then report in one line whether the SurrealDB server is reachable and what version is installed. Say nothing further if it is healthy.` |

To write the file by hand instead, copy [assets/surrealdb-health.kiro.hook](assets/surrealdb-health.kiro.hook) to `.kiro/hooks/surrealdb-health.kiro.hook`.

Hook formats differ across Kiro versions — IDE 0.x writes `.kiro/hooks/<id>.kiro.hook` with `when`/`then` clauses and camelCase event names, while IDE 1.0 and CLI 3.0 use `.kiro/hooks/<id>.json` with a `hooks` array and their own trigger spelling. Prefer `createHook` over writing either by hand; if you must hand-write one, check an existing hook in the workspace and match its shape.

Use `userTriggered` instead of `sessionStart` for a hook that only runs when invoked from the panel.

## 5. What to do next

Every skill in this power activates on its own from what you are working on. Point the user at whichever matches their task:

| Task | Skill |
| --- | --- |
| Writing or debugging SurrealQL | **surrealql** |
| Slow queries, record IDs, indexes, `EXPLAIN` | **surrealql-performance** |
| Finding a built-in function or its signature, LSP setup | **surrealql-functions** |
| Running, backing up, or operating a server | **surrealdb-cli** |
| Schema migrations, rollouts, typegen, schema tests | **surrealkit** |
| Connecting from Python | **surrealdb-python** |
| Connecting from JavaScript or TypeScript | **surrealdb-js** |
| Vector search, HNSW, KNN, RAG | **surrealdb-vector** |
| Endpoints, `USE`, authentication | **surrealdb-connection** |
| Querying or inspecting through MCP tools | **surrealdb-mcp** |

For persistent memory across sessions — recalling past decisions instead of re-explaining them — install the separate **agent-memory** power (SurrealDB Agent Memory).
