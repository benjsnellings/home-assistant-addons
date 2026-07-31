# Multica Daemon (read-only)

## Configuration

| Option | Default when blank | Description |
|--------|--------------------|-------------|
| `multica_token` | **required** | Multica PAT (`mul_…`) |
| `server_url` | `https://api.multica.ai` | Multica API |
| `app_url` | `https://multica.ai` | Multica app |
| `workspace_id` | — | Optional workspace |
| `device_name` | `HA Config (read-only)` | Daemon / computer name in Multica |
| `runtime_name` | `Claude (HA read-only)` | Runtime display name |
| `anthropic_api_key` | — | Headless Claude auth |
| `max_concurrent_tasks` | `2` | Concurrency |

## Access boundary

Supervisor maps `/config`, `/share`, and `/media` **read-only**. Agents on this daemon cannot modify those trees. Add-on state under `/data` remains writable (Multica credentials only).

Filesystem RO is not the same as a read-only Home Assistant API: `homeassistant_api` still injects `SUPERVISOR_TOKEN`, which can call Core services. Prefer this add-on for config-file safety; for API-level least privilege, use a dedicated limited HA token in a future iteration. The bundled `ha-api` helper refuses non-GET methods in this add-on.

## Lifecycle (not systemd)

Home Assistant OS does not expose host systemd to add-ons. The Supervisor starts/stops/restarts this container (`boot: auto`). Inside the container, s6-overlay restarts Multica on unexpected crashes, but **does not** loop on configuration/auth failures (fix the token and restart the add-on).

## HA API

`ha-states`, `ha-history`, and `ha-api` work the same as the read-write add-on.
