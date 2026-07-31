#!/usr/bin/env bash
# Copy shared build inputs into each add-on folder (HA builds from the add-on dir only).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"

chmod_scripts() {
  local base="$1"
  chmod a+x "${base}/run.sh" 2>/dev/null || true
  find "${base}/rootfs/usr/bin" -type f -exec chmod a+x {} + 2>/dev/null || true
  find "${base}/rootfs/etc/services.d" -type f -exec chmod a+x {} + 2>/dev/null || true
  find "${base}/rootfs/etc/cont-init.d" -type f -exec chmod a+x {} + 2>/dev/null || true
}

chmod_scripts "${ROOT}/shared"
chmod a+x "${ROOT}/shared/run.sh"

sync_addon() {
  local dest="$1"
  mkdir -p "${dest}"
  rsync -a --delete \
    --exclude '.DS_Store' \
    "${ROOT}/shared/Dockerfile" \
    "${ROOT}/shared/build.yaml" \
    "${ROOT}/shared/run.sh" \
    "${dest}/"
  mkdir -p "${dest}/rootfs"
  rsync -a --delete "${ROOT}/shared/rootfs/" "${dest}/rootfs/"
  if [[ -f "${dest}/Dockerfile.overlay" ]]; then
    cat "${dest}/Dockerfile.overlay" >> "${dest}/Dockerfile"
  fi
  chmod_scripts "${dest}"
  echo "synced ${dest}"
}

sync_addon "${ROOT}/multica_ro"
sync_addon "${ROOT}/multica_rw"
