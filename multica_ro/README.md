# Multica Daemon (read-only)

Read-only HA `/config` (and share/media), plus a **writable** `/workspace` for Multica agent workdirs.

Ships **Claude Code**, **Cursor Agent**, and **Pi** (OpenRouter). CLIs refresh on start and every 6 hours.

| Option | Purpose |
|--------|---------|
| `multica_token` | required |
| `anthropic_api_key` | Claude plan/API |
| `cursor_api_key` | Cursor plan (headless) |
| `openrouter_api_key` | Pi → OpenRouter |
| `device_name` | default `HA Config (read-only)` |

Point Multica `local_directory` at `/workspace` on this daemon.
