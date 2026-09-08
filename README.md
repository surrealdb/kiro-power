<p align="center">
	<img src="assets/logo.png" alt="SurrealDB" width="120" />
</p>

<h1 align="center">SurrealDB powers for Kiro</h1>

Two [Agent Plugins](https://agent-plugins.org) for [Kiro](https://kiro.dev), built to the Agent Plugins 1.0.0 specification.

| Power | What it gives Kiro |
| --- | --- |
| [`surrealdb`](plugins/surrealdb) | SurrealQL, schema and index design, the `surreal` CLI, SurrealKit migrations, the Python and JavaScript SDKs, vector search, and MCP access to your instances |
| [`spectron`](plugins/spectron) | Persistent memory across sessions with [SurrealDB Agent Memory](https://surrealdb.com/docs/agent-memory) — recall past decisions instead of re-explaining them |

Because they follow the open specification, both also load in any other Agent Plugins client.

## Install

**From GitHub** — Powers panel → **Add Custom Power** → **Import power from GitHub**, then enter:

```
surrealdb-dev/kiro-power
```

A single repository can hold several powers, so both appear and you can install either or both.

**From a local clone** — Powers panel → **Add Custom Power** → **Import power from a folder**, then select `plugins/surrealdb` or `plugins/spectron`.

Once installed, a power activates on its own when your conversation matches its keywords. Nothing loads into context until it does.

## The `surrealdb` power

Eleven skills. Each activates from what you are working on, and each is also available as a slash command.

| Skill | Activates on |
| --- | --- |
| `getting-started` | First-run setup, `surreal` not found, MCP tools missing |
| `surrealql` | SurrealQL, `surql`, queries, schemas, graph relations, live queries |
| `surrealql-performance` | Slow queries, record ID design, indexing, `EXPLAIN`, computed fields |
| `surrealql-functions` | Built-in functions, signatures, `string::`/`array::`/`math::`, the LSP |
| `surrealdb-cli` | `surreal start`, `surreal sql`, import and export, running a server |
| `surrealkit` | Schema migrations, rollouts, typegen, schema tests |
| `surrealdb-python` | The Python SDK, embedded mode, `mem://` and `file://` |
| `surrealdb-js` | The `surrealdb` npm SDK, embedded engines, live queries |
| `surrealdb-vector` | Vector search, HNSW, KNN, embeddings, RAG |
| `surrealdb-connection` | Endpoints, `USE`, WebSocket vs HTTP, authentication |
| `surrealdb-mcp` | Querying or inspecting through MCP tools, connection troubleshooting |

### MCP servers

| Server | Endpoint | Auth |
| --- | --- | --- |
| `surrealdb` | `https://mcp.surrealdb.com` | Sign in with your Surreal ID; Kiro prompts on first use |
| `surrealdb-local` | `http://127.0.0.1:8000/mcp` | None for a dev instance started without auth |

Since SurrealDB 3.1, every instance serves the Model Context Protocol at `/mcp` on the same port as its RPC and HTTP API — there is no separate proxy to run. If no local instance is running, `surrealdb-local` simply does not connect, which affects nothing else.

The two have different tool surfaces. `surrealdb-local` exposes an instance's own tools (`query`, `select`, `info`, …) directly; `mcp.surrealdb.com` is the Cloud API and reaches them through `call_instance_tool`, alongside organisation, instance and billing management and a `search_documentation` tool. The `surrealdb-mcp` skill covers both, and how to reach a remote or secured instance through Kiro's own `.kiro/settings/mcp.json`.

## The `spectron` power

| Skill | Activates on |
| --- | --- |
| `getting-started` | Setup, sign-in, ambient memory hooks, connection failures |
| `spectron` | Spectron or agent memory mentioned, memory tools in use, "remember this", "what did we decide" |

This power ships **no** `mcp.json`. The seven memory tools — `remember`, `recall`, `context`, `reflect`, `forget`, `upload`, `inspect` — are served by your own Agent Memory context host, and an Agent Plugins manifest cannot point at it: `${VAR}` is never expanded inside a `url` or a header, and the spec forbids credentials in headers. The `getting-started` skill writes the server into Kiro's own `.kiro/settings/mcp.json` instead, where expansion works.

If the `surrealdb` power is installed, its `mcp.surrealdb.com` server can also reach memory with no extra setup, through `call_spectron_tool`. That path is two hops and carries around 90 Cloud management tools alongside, so it is the fallback rather than the default.

Memory is on-demand by default; `getting-started` can install hooks that make it ambient.

Agent Memory is in preview — you need a Context and an API key before the power does anything.

## Development

```bash
# Validate both plugins against Agent Plugins 1.0.0
./scripts/test.sh

# Refresh the eight knowledge skills from surrealdb/agent-skills
./scripts/sync-agent-skills.sh
./scripts/sync-agent-skills.sh --check    # report only
```

The eight knowledge skills in the `surrealdb` power are synced from [`surrealdb/agent-skills`](https://github.com/surrealdb/agent-skills), which is upstream for the same content shipped to Claude, Codex, and Cursor. `getting-started`, `surrealdb-connection`, and `surrealdb-mcp` are authored here and never synced.

Each synced skill carries a `.sync-source.json` recording the upstream commit and a hash of what upstream provided. A skill edited locally is reported and skipped rather than reverted — that is the cue to upstream the change. Two such edits stand today: a typo fix in `surrealql`, and a cross-reference to `surrealdb-mcp` in `surrealdb-cli`.

## Support

Open an issue on this repository, or reach the team in the [SurrealDB Discord](https://discord.gg/surrealdb). For documentation, see [surrealdb.com/docs](https://surrealdb.com/docs) and [surrealdb.com/docs/agent-memory](https://surrealdb.com/docs/agent-memory).

Report security issues to security@surrealdb.com rather than in a public issue.

## Privacy

Neither power sends anything anywhere until you connect one of its MCP servers or install a hook.

- **`surrealdb`** — MCP tool calls go to the instance you connect to: `https://mcp.surrealdb.com` after you sign in, or your own instance. Queries and their results travel over that connection.
- **`spectron`** — calling `remember` or `upload` stores that content in your Agent Memory instance; `recall`, `context`, and `reflect` send the query. If you install the ambient memory hooks, this happens automatically each session rather than only on request. Delete the hook files or disable them in the Agent Hooks panel to stop it.

See the [SurrealDB privacy policy](https://surrealdb.com/legal/privacy).

## License

[Apache-2.0](LICENSE)
