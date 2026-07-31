# Multica Daemon (read-only)

Separate Multica daemon container with **read-only** `/config`, `/share`, and `/media`.

Default Multica names (override in add-on options):

| Field | Default |
|-------|---------|
| `device_name` | `HA Config (read-only)` |
| `runtime_name` | `Claude (HA read-only)` |

`multica_token` is required. Leave name options blank to keep the defaults.

See the repository README for install steps and how this pairs with the read-write add-on.
