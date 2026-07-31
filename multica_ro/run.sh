#!/usr/bin/env bash
set -euo pipefail

# Permanent configuration / auth failures — s6 finish will not restart these.
readonly EX_CONFIG=78

OPTIONS_FILE="/data/options.json"
ACCESS_MODE="${MULTICA_ACCESS_MODE:-rw}"
DEFAULT_DEVICE_NAME="${MULTICA_DEFAULT_DEVICE_NAME:-Home Assistant}"
DEFAULT_RUNTIME_NAME="${MULTICA_DEFAULT_RUNTIME_NAME:-}"

export HOME="/data"
export XDG_CONFIG_HOME="/data/.config"
export XDG_DATA_HOME="/data/.local/share"
export XDG_CACHE_HOME="/data/.cache"
mkdir -p "${HOME}" "${XDG_CONFIG_HOME}" "${XDG_DATA_HOME}" "${XDG_CACHE_HOME}" \
  /data/.multica /data/.claude /data/bin /data/workspace /data/.pi/agent \
  /data/.local/bin /data/.local/share

export PATH="/data/bin:/data/.local/bin:/usr/local/bin:/usr/bin:/bin:${PATH}"

log() {
  local level="$1"; shift
  echo "[multica-${ACCESS_MODE}] ${level}: $*"
}

die_config() {
  log error "$*"
  exit "${EX_CONFIG}"
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

ensure_workspace() {
  mkdir -p /data/workspace
  if [[ ! -e /workspace ]]; then
    ln -s /data/workspace /workspace
  elif [[ -L /workspace ]]; then
    ln -sfn /data/workspace /workspace
  fi
}

write_agent_context() {
  local access_label share_access media_access local_dir_hint
  if [[ "${ACCESS_MODE}" == "ro" ]]; then
    access_label="read-only"
    share_access="read-only"
    media_access="read-only"
    local_dir_hint="/workspace (writable). Read HA config from /config (read-only)."
  else
    access_label="read-write"
    share_access="read-write"
    media_access="read-write"
    local_dir_hint="/config (HA config, writable) or /workspace (agent scratch)."
  fi

  cat >/data/HA_AGENT_CONTEXT.md <<EOF
# Home Assistant Multica context (${access_label})

This container runs Multica with Claude Code, Cursor Agent, and Pi CLIs.

## Filesystem

| Path | Access | Purpose |
|------|--------|---------|
| \`/config\` | ${access_label} | Home Assistant configuration |
| \`/workspace\` | read-write | Multica agent workdirs / scratch (persisted in \`/data/workspace\`) |
| \`/share\` | ${share_access} | Shared HA storage |
| \`/media\` | ${media_access} | Media files |
| \`/data\` | read-write | Daemon credentials + tool state |

**Recommended Multica \`local_directory\`:** ${local_dir_hint}

## Runtimes

- \`claude\` — Claude Code (subscription/API via add-on options)
- \`cursor-agent\` — Cursor Agent CLI (Cursor plan via \`cursor_api_key\`)
- \`pi\` — Pi coding agent (OpenRouter via \`openrouter_api_key\`)

CLIs auto-update on start and every \`${TOOL_UPDATE_INTERVAL_SECONDS:-21600}\` seconds.

## Home Assistant API

\`\`\`bash
ha-states
ha-history sensor.temperature
ha-api GET /states
\`\`\`

Filesystem mode is \`${ACCESS_MODE}\`. \`ha-api\` blocks non-GET when RO; \`SUPERVISOR_TOKEN\` still allows Core API calls via raw curl.

Environment: \`HA_URL\`, \`HA_TOKEN\`/\`SUPERVISOR_TOKEN\`, \`MULTICA_ACCESS_MODE\`, \`MULTICA_HA_CONFIG=/config\`, \`MULTICA_WORKSPACE=/workspace\`
EOF
}

configure_provider_auth() {
  local anthropic_key cursor_key openrouter_key openrouter_model
  anthropic_key="$(option anthropic_api_key "")"
  cursor_key="$(option cursor_api_key "")"
  openrouter_key="$(option openrouter_api_key "")"
  openrouter_model="$(option openrouter_model "anthropic/claude-sonnet-4")"

  if [[ -n "${anthropic_key}" ]]; then
    export ANTHROPIC_API_KEY="${anthropic_key}"
    log info "ANTHROPIC_API_KEY set for Claude Code"
  else
    log info "No anthropic_api_key — Claude subscription login must already exist under /data/.claude (run claude auth from a shell if needed)"
  fi

  if [[ -n "${cursor_key}" ]]; then
    export CURSOR_API_KEY="${cursor_key}"
    log info "CURSOR_API_KEY set for Cursor Agent (plan auth)"
  else
    log info "No cursor_api_key — Cursor Agent will not authenticate until set"
  fi

  if [[ -n "${openrouter_key}" ]]; then
    export OPENROUTER_API_KEY="${openrouter_key}"
    mkdir -p /data/.pi/agent
    jq -n --arg key "${openrouter_key}" \
      '{openrouter: {type: "api_key", key: $key}}' > /data/.pi/agent/auth.json
    jq -n --arg model "${openrouter_model}" \
      '{defaultProvider: "openrouter", defaultModel: $model}' > /data/.pi/agent/settings.json
    chmod 600 /data/.pi/agent/auth.json
    log info "Pi configured for OpenRouter (model=${openrouter_model})"
  else
    log info "No openrouter_api_key — Pi OpenRouter auth not configured"
  fi
}

ensure_workspace

if [[ ! -d /config ]]; then
  die_config "Home Assistant config is not mounted at /config"
fi

export HA_URL="${HA_URL:-http://supervisor/core/api}"
export HA_TOKEN="${SUPERVISOR_TOKEN:-}"
export MULTICA_HA_CONFIG="/config"
export MULTICA_WORKSPACE="/workspace"
export MULTICA_ACCESS_MODE="${ACCESS_MODE}"

MULTICA_TOKEN="$(option multica_token "")"
SERVER_URL="$(option server_url "https://api.multica.ai")"
APP_URL="$(option app_url "https://multica.ai")"
WORKSPACE_ID="$(option workspace_id "")"
DEVICE_NAME="$(option_or_default device_name "${DEFAULT_DEVICE_NAME}")"
RUNTIME_NAME="$(option_or_default runtime_name "${DEFAULT_RUNTIME_NAME}")"
MAX_TASKS="$(option max_concurrent_tasks "2")"

export MULTICA_DAEMON_DEVICE_NAME="${DEVICE_NAME}"
export MULTICA_DAEMON_MAX_CONCURRENT_TASKS="${MAX_TASKS}"
if [[ -n "${RUNTIME_NAME}" ]]; then
  export MULTICA_AGENT_RUNTIME_NAME="${RUNTIME_NAME}"
fi

configure_provider_auth
write_agent_context

if ! command -v multica >/dev/null; then
  die_config "multica CLI missing from image"
fi

for tool in claude cursor-agent pi; do
  if command -v "${tool}" >/dev/null; then
    log info "runtime tool present: ${tool} ($(${tool} --version 2>/dev/null | head -1 || echo ok))"
  else
    log warning "runtime tool missing: ${tool}"
  fi
done

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

if [[ -n "${MULTICA_TOKEN}" ]]; then
  log info "Authenticating with Multica personal access token from add-on options"
  if ! multica login --token "${MULTICA_TOKEN}"; then
    die_config "multica login failed — check the Multica token option"
  fi
elif multica auth status >/dev/null 2>&1; then
  log info "Using existing Multica credentials stored in /data"
else
  die_config "No Multica credentials. Set the 'multica_token' add-on option (Settings → API Tokens on Multica)."
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

log info "Starting Multica daemon (access=${ACCESS_MODE}, device=${DEVICE_NAME})"
log info "HA config: /config (${ACCESS_MODE}) | agent workspace: /workspace (rw) | HA API: ${HA_URL}"
exec multica "${DAEMON_ARGS[@]}"
