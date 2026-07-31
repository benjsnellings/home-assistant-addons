#!/usr/bin/env bash
# Copy shared build inputs into each add-on folder (HA builds from the add-on dir only).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"

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
  # Append access-mode defaults after the shared Dockerfile ENV block via overlay file.
  if [[ -f "${dest}/Dockerfile.overlay" ]]; then
    cat "${dest}/Dockerfile.overlay" >> "${dest}/Dockerfile"
  fi
  chmod a+x "${dest}/run.sh" \
    "${dest}/rootfs/usr/bin/ha-api" \
    "${dest}/rootfs/usr/bin/ha-states" \
    "${dest}/rootfs/usr/bin/ha-history" \
    "${dest}/rootfs/etc/services.d/multica/run" \
    "${dest}/rootfs/etc/services.d/multica/finish"
  echo "synced ${dest}"
}

sync_addon "${ROOT}/multica_ro"
sync_addon "${ROOT}/multica_rw"
