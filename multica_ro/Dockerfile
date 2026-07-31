ARG BUILD_FROM
FROM ${BUILD_FROM}

ARG BUILD_ARCH
ARG MULTICA_VERSION=0.4.15
ARG CLAUDE_VERSION=2.1.220
ARG CLAUDE_SHA256_X64=f1c20514a3571cdf9982e25c490042d740ed7cfed3f00c64ba92dc7ec47c3c5b
ARG CLAUDE_SHA256_ARM64=5eb2697a1500c1b8736e53fd696392196dc6758cf1d470c64d8d2a2fd1629eeb

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV HOME=/root

# Seed Multica + Claude + Cursor + Pi. Runtime update-agent-tools keeps CLIs current.
RUN \
    apk add --no-cache \
        bash \
        ca-certificates \
        coreutils \
        curl \
        gcompat \
        git \
        jq \
        libstdc++ \
        nodejs \
        npm \
        openssh-client \
        tar \
        tzdata \
    \
    && case "${BUILD_ARCH}" in \
         amd64) \
           MULTICA_ARCH="amd64" \
           CLAUDE_PLATFORM="linux-x64-musl" \
           CLAUDE_SHA256="${CLAUDE_SHA256_X64}" \
           ;; \
         aarch64) \
           MULTICA_ARCH="arm64" \
           CLAUDE_PLATFORM="linux-arm64-musl" \
           CLAUDE_SHA256="${CLAUDE_SHA256_ARM64}" \
           ;; \
         *) echo "Unsupported arch: ${BUILD_ARCH}" >&2; exit 1 ;; \
       esac \
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
    && npm install -g --omit=dev @mariozechner/pi-coding-agent@latest \
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
      /etc/services.d/multica/run \
      /etc/services.d/multica/finish \
      /etc/services.d/tool-updater/run \
      /etc/services.d/tool-updater/finish \
      /etc/cont-init.d/40-update-agent-tools \
      /etc/cont-init.d/50-workspace

ENV \
    HOME=/data \
    PATH="/data/bin:/data/.local/bin:/usr/local/bin:/usr/bin:/bin" \
    HA_URL=http://supervisor/core/api \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
    TOOL_UPDATE_INTERVAL_SECONDS=21600

WORKDIR /data

# Access-mode defaults for this add-on variant (appended by sync-addons.sh)
ENV \
    MULTICA_ACCESS_MODE=ro \
    MULTICA_DEFAULT_DEVICE_NAME="HA Config (read-only)" \
    MULTICA_DEFAULT_RUNTIME_NAME=""
