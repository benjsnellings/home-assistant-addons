# Ben's Home Assistant Add-ons

Repository: https://github.com/benjsnellings/home-assistant-addons

## Add-ons

### Multica Daemon

Runs the [Multica](https://multica.ai) agent daemon inside Home Assistant with:

- Read-write Home Assistant config at `/config`
- Read-only Home Assistant config at `/config-ro`
- Core API helpers for states and history (`ha-states`, `ha-history`, `ha-api`)

See [`multica_daemon/README.md`](multica_daemon/README.md).

## Install

In Home Assistant: **Settings → Add-ons → Add-on Store → ⋮ → Repositories**, then add:

```text
https://github.com/benjsnellings/home-assistant-addons
```
