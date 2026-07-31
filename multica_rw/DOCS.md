# Multica Daemon (read-write)

## Configuration

| Option | Default when blank | Description |
|--------|--------------------|-------------|
| `multica_token` | **required** | Multica PAT (`mul_…`) |
| `server_url` / `app_url` | Multica Cloud | Self-host override |
| `device_name` | `HA Config (read-write)` | Computer name in Multica |
| `runtime_name` | *(empty)* | Leave blank so Claude, Cursor, and Pi each register |
| `anthropic_api_key` | — | Claude Code API / plan-linked key |
| `cursor_api_key` | — | Cursor Agent API key (Cursor plan) |
| `openrouter_api_key` | — | Pi → OpenRouter |
| `openrouter_model` | `anthropic/claude-sonnet-4` | Default Pi model on OpenRouter |
| `max_concurrent_tasks` | `2` | Concurrency |

## Access boundary

`/config` is read-write. `/workspace` is also available as a writable agent scratch dir.

## Runtimes & updates

Image seeds Claude Code, Cursor Agent (`cursor-agent`), and Pi. On every start (and every 6h) `update-agent-tools` refreshes them to the latest verified releases.

## Plan / provider login

- **Claude:** set `anthropic_api_key`, or persist interactive login under `/data/.claude`.
- **Cursor:** set `cursor_api_key` from Cursor dashboard.
- **Pi / OpenRouter:** set `openrouter_api_key`.
