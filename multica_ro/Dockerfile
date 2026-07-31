ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base-debian:bookworm
FROM ${BUILD_FROM}

ARG BUILD_ARCH=amd64
ARG MULTICA_VERSION=0.4.15
ARG CLAUDE_VERSION=2.1.220
# Pinned SHA256 for Claude glibc binaries (Cursor Agent also requires glibc).
ARG CLAUDE_SHA256_X64=674f61f20ff306f3100cf9200e4c36c4b70278b5bef2884549819b942a89c863
ARG CLAUDE_SHA256_ARM64=159e4a51d796f3bf14677577100f7efb845611b1ceaf0c30cbd8d4650d942185
# Official Node binary (bookworm apt is Node 18; Pi needs >=22.19 for /v regex).
ARG NODE_VERSION=22.23.0
ARG NODE_SHA256_X64=14d7de44f235534799f8b171a4050d9a6a4bc99c87e053a25d3d54afa580aa20
ARG NODE_SHA256_ARM64=4018815ac1bed4f18208901bbde524fee881253b591ee7bc952660e69bd057af

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV HOME=/root \
    DEBIAN_FRONTEND=noninteractive

# Seed Multica + Claude + Cursor + Pi. Runtime update-agent-tools keeps CLIs current.
# Debian/glibc base is required: Cursor Agent's bundled Node needs fcntl64 (fails on Alpine/musl).
RUN \
    apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        curl \
        git \
        jq \
        openssh-client \
        tar \
        xz-utils \
    && rm -rf /var/lib/apt/lists/* \
    \
    && case "${BUILD_ARCH}" in \
         amd64) \
           MULTICA_ARCH="amd64" \
           CLAUDE_PLATFORM="linux-x64" \
           CLAUDE_SHA256="${CLAUDE_SHA256_X64}" \
           NODE_ARCH="x64" \
           NODE_SHA256="${NODE_SHA256_X64}" \
           ;; \
         aarch64) \
           MULTICA_ARCH="arm64" \
           CLAUDE_PLATFORM="linux-arm64" \
           CLAUDE_SHA256="${CLAUDE_SHA256_ARM64}" \
           NODE_ARCH="arm64" \
           NODE_SHA256="${NODE_SHA256_ARM64}" \
           ;; \
         *) echo "Unsupported arch: ${BUILD_ARCH}" >&2; exit 1 ;; \
       esac \
    \
    && NODE_TGZ="node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz" \
    && curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/${NODE_TGZ}" -o "/tmp/${NODE_TGZ}" \
    && echo "${NODE_SHA256}  /tmp/${NODE_TGZ}" | sha256sum -c - \
    && tar -xJf "/tmp/${NODE_TGZ}" -C /usr/local --strip-components=1 \
    && rm -f "/tmp/${NODE_TGZ}" \
    && node --version && npm --version \
    \
    && MULTICA_TGZ="multica-cli-${MULTICA_VERSION}-linux-${MULTICA_ARCH}.tar.gz" \
    && curl -fsSL \
         "https://github.com/multica-ai/multica/releases/download/v${MULTICA_VERSION}/checksums.txt" \
         -o /tmp/checksums.txt \
    && curl -fsSL \
         "https://github.com/multica-ai/multica/releases/download/v${MULTICA_VERSION}/${MULTICA_TGZ}" \
         -o "/tmp/${MULTICA_TGZ}" \
    && grep " ${MULTICA_TGZ}\$" /tmp/checksums.txt | (cd /tmp && sha256sum -c -) \
    && tar -xzf "/tmp/${MULTICA_TGZ}" -C /tmp \
    && install -m 0755 /tmp/multica /usr/local/bin/multica \
    && rm -rf /tmp/multica "/tmp/${MULTICA_TGZ}" /tmp/checksums.txt \
    \
    && curl -fsSL \
         "https://downloads.claude.ai/claude-code-releases/${CLAUDE_VERSION}/${CLAUDE_PLATFORM}/claude" \
         -o /tmp/claude \
    && echo "${CLAUDE_SHA256}  /tmp/claude" | sha256sum -c - \
    && install -m 0755 /tmp/claude /usr/local/bin/claude \
    && rm -f /tmp/claude \
    \
    && curl -fsS https://cursor.com/install | bash \
    && ln -sfn /root/.local/bin/cursor-agent /usr/local/bin/cursor-agent \
    && ln -sfn /root/.local/bin/agent /usr/local/bin/agent \
    \
    && npm install -g --omit=dev @earendil-works/pi-coding-agent@latest \
    \
    && multica version \
    && claude --version \
    && cursor-agent --version \
    && pi --version

COPY rootfs /
COPY run.sh /run.sh
RUN chmod a+x /run.sh \
      /usr/bin/ha-api \
      /usr/bin/ha-states \
      /usr/bin/ha-history \
      /usr/bin/update-agent-tools \
      /etc/cont-init.d/* \
      /etc/services.d/*/run \
      /etc/services.d/*/finish

WORKDIR /workspace
# Entrypoint /init (from HA base) is PID 1. Longruns live in /etc/services.d.
# Do not set CMD to /run.sh — that would start a second Multica alongside services.d.

# Access-mode defaults for this add-on variant (appended by sync-addons.sh)
ENV \
    MULTICA_ACCESS_MODE=ro \
    MULTICA_DEFAULT_DEVICE_NAME="HA Config (read-only)" \
    MULTICA_DEFAULT_RUNTIME_NAME=""
