#!/usr/bin/env bash
set -euo pipefail

OPTIONS_FILE="/data/options.json"
ACCESS_MODE="${MULTICA_ACCESS_MODE:-rw}"
DEFAULT_DEVICE_NAME="${MULTICA_DEFAULT_DEVICE_NAME:-Home Assistant}"
DEFAULT_RUNTIME_NAME="${MULTICA_DEFAULT_RUNTIME_NAME:-}"

export HOME="/data"
export XDG_CONFIG_HOME="/data/.config"
export XDG_DATA_HOME="/data/.local/share"
export XDG_CACHE_HOME="/data/.cache"
mkdir -p "${HOME}" "${XDG_CONFIG_HOME}" "${XDG_DATA_HOME}" "${XDG_CACHE_HOME}" \
  /data/.multica /data/.claude /data/bin

export PATH="/usr/local/bin:/data/bin:${HOME}/.local/bin:${PATH}"

log() {
  local level="$1"; shift
  echo "[multica-${ACCESS_MODE}] ${level}: $*"
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

# Empty / whitespace option → fall back to packaged default.
option_or_default() {
  local key="$1"
  local packaged_default="$2"
  local value
  value="$(option "${key}" "")"
  if [[ -z "${value// }" ]]; then
    printf '%s' "${packaged_default}"
  else
    printf '%s' "${value}"
  fi
}

write_agent_context() {
  local access_label
  if [[ "${ACCESS_MODE}" == "ro" ]]; then
    access_label="read-only"
  else
    access_label="read-write"
  fi

  cat >/data/HA_AGENT_CONTEXT.md <<EOF
# Home Assistant Multica context (${access_label})

This container is a dedicated Multica daemon with a **${access_label}** mount of the Home Assistant configuration.

## Filesystem

| Path | Access | Purpose |
|------|--------|---------|
| \`/config\` | ${access_label} | Home Assistant configuration |
| \`/share\` | read-write | Shared HA storage |
| \`/media\` | read-write | Media files |
| \`/data\` | read-write | This daemon's Multica state |

Register a Multica \`local_directory\` project resource at \`/config\` on **this** daemon so agents inherit the container's access boundary.

## Home Assistant API

\`homeassistant_api\` is enabled. Helpers on PATH:

\`\`\`bash
ha-states
ha-states sensor.temperature
ha-history sensor.temperature
ha-api GET /states
\`\`\`

Environment:

- \`HA_URL\` — \`http://supervisor/core/api\`
- \`SUPERVISOR_TOKEN\` / \`HA_TOKEN\` — bearer token for Core API
- \`MULTICA_ACCESS_MODE\` — \`${ACCESS_MODE}\`
- \`MULTICA_HA_CONFIG\` — \`/config\`
EOF
}

if [[ ! -d /config ]]; then
  log error "Home Assistant config is not mounted at /config"
  exit 1
fi

export HA_URL="${HA_URL:-http://supervisor/core/api}"
export HA_TOKEN="${SUPERVISOR_TOKEN:-}"
export MULTICA_HA_CONFIG="/config"
export MULTICA_ACCESS_MODE="${ACCESS_MODE}"

MULTICA_TOKEN="$(option multica_token "")"
SERVER_URL="$(option server_url "https://api.multica.ai")"
APP_URL="$(option app_url "https://multica.ai")"
WORKSPACE_ID="$(option workspace_id "")"
DEVICE_NAME="$(option_or_default device_name "${DEFAULT_DEVICE_NAME}")"
RUNTIME_NAME="$(option_or_default runtime_name "${DEFAULT_RUNTIME_NAME}")"
ANTHROPIC_API_KEY_OPT="$(option anthropic_api_key "")"
MAX_TASKS="$(option max_concurrent_tasks "2")"
LOG_LEVEL="$(option log_level "info")"

export MULTICA_DAEMON_DEVICE_NAME="${DEVICE_NAME}"
export MULTICA_DAEMON_MAX_CONCURRENT_TASKS="${MAX_TASKS}"
if [[ -n "${RUNTIME_NAME}" ]]; then
  export MULTICA_AGENT_RUNTIME_NAME="${RUNTIME_NAME}"
fi

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

if [[ -n "${RUNTIME_NAME}" ]]; then
  tmp="$(mktemp)"
  jq --arg name "${RUNTIME_NAME}" '.runtime_name = $name' /data/.multica/config.json >"${tmp}"
  mv "${tmp}" /data/.multica/config.json
fi

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

DAEMON_ARGS=(
  daemon start --foreground
  --device-name "${DEVICE_NAME}"
  --max-concurrent-tasks "${MAX_TASKS}"
)
if [[ -n "${RUNTIME_NAME}" ]]; then
  DAEMON_ARGS+=(--runtime-name "${RUNTIME_NAME}")
fi

log info "Starting Multica daemon (access=${ACCESS_MODE}, device=${DEVICE_NAME}, log_level=${LOG_LEVEL})"
log info "Config mount: /config (${ACCESS_MODE}) | HA API: ${HA_URL}"
exec multica "${DAEMON_ARGS[@]}"
