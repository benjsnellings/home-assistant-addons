# Multica Daemon (read-write)

## Configuration

| Option | Default when blank | Description |
|--------|--------------------|-------------|
| `multica_token` | — | Multica PAT (`mul_…`) |
| `server_url` | `https://api.multica.ai` | Multica API |
| `app_url` | `https://multica.ai` | Multica app |
| `workspace_id` | — | Optional workspace |
| `device_name` | `HA Config (read-write)` | Daemon / computer name in Multica |
| `runtime_name` | `Claude (HA read-write)` | Runtime display name |
| `anthropic_api_key` | — | Headless Claude auth |
| `max_concurrent_tasks` | `2` | Concurrency |

## Access boundary

Supervisor maps Home Assistant config into this container as **read-write** at `/config`. Only assign agents here when they are allowed to edit configuration.

## Lifecycle (not systemd)

Home Assistant OS does not expose host systemd to add-ons. The Supervisor starts/stops/restarts this container (`boot: auto`). Inside the container, s6-overlay keeps the Multica process alive and restarts it if it crashes.

## HA API

`ha-states`, `ha-history`, and `ha-api` work the same as the read-only add-on.
