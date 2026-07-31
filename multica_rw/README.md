# Multica Daemon (read-write)

Separate Multica daemon container whose Home Assistant `/config` mount is **read-write**.

Default Multica names (override in add-on options):

| Field | Default |
|-------|---------|
| `device_name` | `HA Config (read-write)` |
| `runtime_name` | `Claude (HA read-write)` |

Leave those options blank to keep the defaults.

See the repository README for install steps and how this pairs with the read-only add-on.
