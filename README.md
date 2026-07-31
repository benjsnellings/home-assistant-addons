# Ben's Home Assistant Add-ons

Repository: https://github.com/benjsnellings/home-assistant-addons

## Add-ons

Two separate Multica daemon containers so agents get real filesystem access boundaries:

| Add-on | Config mount | Default device name | Default runtime name |
|--------|--------------|---------------------|----------------------|
| **Multica Daemon (read-only)** | `/config`, `/share`, `/media` RO | `HA Config (read-only)` | `Claude (HA read-only)` |
| **Multica Daemon (read-write)** | `/config` RW | `HA Config (read-write)` | `Claude (HA read-write)` |

Both can query Home Assistant states/history (`ha-states`, `ha-history`, `ha-api`). Names are overrideable in each add-on's options (blank = packaged default).

### Lifecycle

Home Assistant Supervisor starts/stops these containers (the HAOS equivalent of systemd). Inside each container, s6-overlay supervises the Multica process and restarts it on crash.

## Install

1. HA → **Settings → Add-ons → Add-on Store → ⋮ → Repositories**
2. Add: `https://github.com/benjsnellings/home-assistant-addons`
3. Install **both** Multica add-ons (or only the access level you need)
4. Set `multica_token` on each (same PAT is fine). For self-host, set `server_url` / `app_url`.
5. Optionally override `device_name` / `runtime_name`
6. Start them, then point Multica `local_directory` resources at `/config` on each daemon

## Development

Shared image logic lives in `shared/`. After editing it, run:

```bash
./sync-addons.sh
```
