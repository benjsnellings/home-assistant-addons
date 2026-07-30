# Multica Daemon

Home Assistant add-on that runs the [Multica](https://multica.ai) agent daemon on your HA host.

## What you get

- Multica CLI + daemon + Claude Code runtime inside the add-on
- **Read-write** Home Assistant config at `/config`
- **Read-only** Home Assistant config at `/config-ro`
- Home Assistant Core API access (`states`, `history`, …) via `SUPERVISOR_TOKEN` and helper commands

## Install

1. In Home Assistant → Settings → Add-ons → Add-on Store → ⋮ → Repositories
2. Add: `https://github.com/benjsnellings/home-assistant-addons`
3. Install **Multica Daemon**
4. Create a Multica personal access token at https://multica.ai/settings?tab=tokens
5. Paste the token into the add-on `multica_token` option (optional: set `anthropic_api_key` for Claude)
6. Start the add-on

## Multica project resources

After the daemon is online, add `local_directory` resources on your Home Assistant Multica project:

| Label | Path | Access |
|-------|------|--------|
| HA config (RO) | `/config-ro` | inspect safely |
| HA config (RW) | `/config` | edit configuration |

Both agent contexts inherit Core API helpers (`ha-states`, `ha-history`, `ha-api`).

See [DOCS.md](DOCS.md) for configuration details.
