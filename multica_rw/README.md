# Multica Daemon (read-write)

Read-write HA `/config`, plus `/workspace` for agent scratch.

Ships **Claude Code**, **Cursor Agent**, and **Pi** (OpenRouter). CLIs refresh on start and every 6 hours.

| Option | Purpose |
|--------|---------|
| `multica_token` | required |
| `anthropic_api_key` | Claude plan/API |
| `cursor_api_key` | Cursor plan (headless) |
| `openrouter_api_key` | Pi → OpenRouter |
| `device_name` | default `HA Config (read-write)` |

Leave `runtime_name` blank so all three tools register as separate Multica runtimes.
