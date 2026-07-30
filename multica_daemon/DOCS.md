# Multica Daemon

Runs the Multica agent daemon inside Home Assistant OS / Supervised so agents can work on your Home Assistant configuration and query live state.

## Configuration

| Option | Required | Description |
|--------|----------|-------------|
| `multica_token` | yes (first start) | Multica personal access token (`mul_…`) from Settings → API Tokens |
| `server_url` | no | Multica API URL (default `https://api.multica.ai`) |
| `app_url` | no | Multica app URL (default `https://multica.ai`) |
| `workspace_id` | no | Workspace to select after login |
| `device_name` | no | Runtime display name (default `Home Assistant`) |
| `anthropic_api_key` | recommended | API key so Claude Code can run headlessly |
| `max_concurrent_tasks` | no | Daemon concurrency (default `2`) |
| `log_level` | no | Add-on log verbosity |

Credentials and Multica state persist under the add-on `/data` volume (`HOME=/data`).

### Self-hosted Multica

Set `server_url` / `app_url` to your self-hosted endpoints before starting.

## Filesystems

| Path | Access | Notes |
|------|--------|-------|
| `/config` | read-write | Home Assistant configuration directory (Supervisor map) |
| `/config-ro` | read-only | Same tree via a read-only bind mount created at start |
| `/share` | read-write | HA share |
| `/media` | read-write | HA media |
| `/ssl` | read-only | Certificates |
| `/data` | read-write | Multica + Claude state (backed up with the add-on) |

Point Multica `local_directory` project resources at `/config-ro` and `/config` using this add-on's daemon id once the runtime shows online.

## Home Assistant API

`homeassistant_api: true` injects `SUPERVISOR_TOKEN`. Agents can call:

```bash
ha-states
ha-states light.kitchen
ha-history sensor.outdoor_temperature
ha-api GET /states
ha-api GET '/history/period/2026-07-29T00:00:00+00:00?filter_entity_id=sensor.outdoor_temperature'
```

Environment variables available to agent processes:

- `HA_URL=http://supervisor/core/api`
- `HA_TOKEN` / `SUPERVISOR_TOKEN`
- `MULTICA_HA_CONFIG_RW=/config`
- `MULTICA_HA_CONFIG_RO=/config-ro`

A short reference is also written to `/data/HA_AGENT_CONTEXT.md` on each start.

## Security notes

- The Multica token and Anthropic API key are stored in add-on options (Supervisor secrets) and/or `/data/.multica/config.json`.
- `/config` is writable — prefer assigning exploratory agents to `/config-ro`.
- `SYS_ADMIN` is requested only so the add-on can create the read-only bind mount fallback.

## Troubleshooting

1. Check add-on logs for `multica login failed` → refresh the PAT.
2. Runtime offline in Multica → confirm Claude is authenticated (`anthropic_api_key` set) and restart the add-on.
3. Missing `/config-ro` → check logs for the bind-mount fallback; ensure the add-on kept `SYS_ADMIN`.
4. States/history failing → confirm `homeassistant_api` is enabled (it is by default in this add-on).
