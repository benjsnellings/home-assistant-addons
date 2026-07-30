#!/usr/bin/env bash
set -euo pipefail

OPTIONS_FILE="/data/options.json"
export HOME="/data"
export XDG_CONFIG_HOME="/data/.config"
export XDG_DATA_HOME="/data/.local/share"
export XDG_CACHE_HOME="/data/.cache"
mkdir -p "${HOME}" "${XDG_CONFIG_HOME}" "${XDG_DATA_HOME}" "${XDG_CACHE_HOME}" \
  /data/.multica /data/.claude /data/bin

export PATH="/usr/local/bin:/data/bin:${HOME}/.local/bin:${PATH}"

log() {
  local level="$1"; shift
  echo "[multica-daemon] ${level}: $*"
}

option() {
  local key="$1"
  local default="${2:-}"
  if [[ -f "${OPTIONS_FILE}" ]]; then
    jq -r --arg key "${key}" --arg default "${default}" \
      '.[$key] // $default | if . == null then $default else tostring end' \
      "${OPTIONS_FILE}"
  else
    printf '%s' "${default}"
  fi
}

ensure_config_ro() {
  if [[ ! -d /config ]]; then
    log warning "Home Assistant config is not mounted at /config"
    return 0
  fi

  if mountpoint -q /config-ro 2>/dev/null; then
    log info "Read-only Home Assistant config available at /config-ro"
    return 0
  fi

  log info "Creating read-only bind mount of /config at /config-ro"
  mkdir -p /config-ro
  if mount --bind /config /config-ro && mount -o remount,ro,bind /config-ro; then
    log info "Read-only mount ready at /config-ro"
  else
    log error "Failed to create /config-ro read-only bind mount (needs SYS_ADMIN)"
    exit 1
  fi
}

write_agent_context() {
  cat >/data/HA_AGENT_CONTEXT.md <<'EOF'
# Home Assistant Multica context

This add-on exposes two config filesystems and the Home Assistant Core API.

## Filesystems

| Path | Access | Purpose |
|------|--------|---------|
| `/config` | read-write | Edit Home Assistant configuration |
| `/config-ro` | read-only | Inspect configuration without write risk |
| `/share` | read-write | Shared HA storage |
| `/media` | read-write | Media files |
| `/data` | read-write | Multica daemon state (persists across restarts) |

Register Multica `local_directory` project resources against `/config-ro` and `/config` on this daemon so agents land in the right mount.

## Home Assistant API

`homeassistant_api` is enabled. Use the helpers on PATH:

```bash
ha-states                         # all current states
ha-states sensor.temperature      # one entity
ha-history sensor.temperature     # history (default last 24h)
ha-api GET /states
ha-api GET '/history/period/2026-07-29T00:00:00+00:00?filter_entity_id=sensor.temperature'
```

Environment:

- `HA_URL` — `http://supervisor/core/api`
- `SUPERVISOR_TOKEN` / `HA_TOKEN` — bearer token for Core API
- `MULTICA_HA_CONFIG_RW` — `/config`
- `MULTICA_HA_CONFIG_RO` — `/config-ro`
EOF
}

ensure_config_ro

export HA_URL="${HA_URL:-http://supervisor/core/api}"
export HA_TOKEN="${SUPERVISOR_TOKEN:-}"
export MULTICA_HA_CONFIG_RW="/config"
export MULTICA_HA_CONFIG_RO="/config-ro"

MULTICA_TOKEN="$(option multica_token "")"
SERVER_URL="$(option server_url "https://api.multica.ai")"
APP_URL="$(option app_url "https://multica.ai")"
WORKSPACE_ID="$(option workspace_id "")"
DEVICE_NAME="$(option device_name "Home Assistant")"
ANTHROPIC_API_KEY_OPT="$(option anthropic_api_key "")"
MAX_TASKS="$(option max_concurrent_tasks "2")"
LOG_LEVEL="$(option log_level "info")"

export MULTICA_DAEMON_DEVICE_NAME="${DEVICE_NAME}"
export MULTICA_DAEMON_MAX_CONCURRENT_TASKS="${MAX_TASKS}"

if [[ -n "${ANTHROPIC_API_KEY_OPT}" ]]; then
  export ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY_OPT}"
fi

write_agent_context

if ! command -v multica >/dev/null; then
  log error "multica CLI missing from image"
  exit 1
fi

if ! command -v claude >/dev/null; then
  log warning "claude CLI not found on PATH — Multica needs at least one AI coding tool"
fi

log info "Configuring Multica CLI (server=${SERVER_URL})"
mkdir -p /data/.multica
if [[ ! -f /data/.multica/config.json ]]; then
  printf '%s\n' '{}' > /data/.multica/config.json
fi

# Merge non-secret settings without wiping an existing auth token.
tmp="$(mktemp)"
jq \
  --arg server_url "${SERVER_URL}" \
  --arg app_url "${APP_URL}" \
  --arg device_name "${DEVICE_NAME}" \
  --argjson max_tasks "${MAX_TASKS}" \
  '.server_url = $server_url
   | .app_url = $app_url
   | .device_name = $device_name
   | .max_concurrent_tasks = $max_tasks' \
  /data/.multica/config.json >"${tmp}"
mv "${tmp}" /data/.multica/config.json

if [[ -n "${WORKSPACE_ID}" ]]; then
  tmp="$(mktemp)"
  jq --arg id "${WORKSPACE_ID}" '.workspace_id = $id' /data/.multica/config.json >"${tmp}"
  mv "${tmp}" /data/.multica/config.json
fi

if multica auth status >/dev/null 2>&1; then
  log info "Already authenticated with Multica"
elif [[ -n "${MULTICA_TOKEN}" ]]; then
  log info "Logging in with Multica personal access token"
  if ! multica login --token "${MULTICA_TOKEN}"; then
    log error "multica login failed — check the Multica token option"
    exit 1
  fi
else
  log error "No Multica credentials. Set the 'multica_token' add-on option (Settings → API Tokens on Multica)."
  exit 1
fi

if [[ -n "${WORKSPACE_ID}" ]]; then
  multica workspace switch "${WORKSPACE_ID}" >/dev/null 2>&1 || \
    log warning "Could not switch workspace to ${WORKSPACE_ID}"
fi

log info "Starting Multica daemon in foreground (log_level=${LOG_LEVEL})"
log info "RW config: /config | RO config: /config-ro | HA API: ${HA_URL}"
exec multica daemon start --foreground \
  --device-name "${DEVICE_NAME}" \
  --max-concurrent-tasks "${MAX_TASKS}"
