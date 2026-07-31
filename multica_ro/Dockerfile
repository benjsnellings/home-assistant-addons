ARG BUILD_FROM
FROM ${BUILD_FROM}

ARG BUILD_ARCH
ARG MULTICA_VERSION=0.4.15
ARG CLAUDE_VERSION=2.1.220
# Pinned SHA256 for Claude musl binaries (from downloads.claude.ai manifest).
ARG CLAUDE_SHA256_X64=f1c20514a3571cdf9982e25c490042d740ed7cfed3f00c64ba92dc7ec47c3c5b
ARG CLAUDE_SHA256_ARM64=5eb2697a1500c1b8736e53fd696392196dc6758cf1d470c64d8d2a2fd1629eeb

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV HOME=/root

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
    && multica version \
    && claude --version

COPY rootfs /
COPY run.sh /run.sh
RUN chmod a+x /run.sh \
      /usr/bin/ha-api \
      /usr/bin/ha-states \
      /usr/bin/ha-history \
      /etc/services.d/multica/run \
      /etc/services.d/multica/finish

ENV \
    HOME=/data \
    PATH="/usr/local/bin:/usr/bin:/bin" \
    HA_URL=http://supervisor/core/api \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
    DISABLE_AUTOUPDATER=1

WORKDIR /data

# Access-mode defaults for this add-on variant (appended by sync-addons.sh)
ENV \
    MULTICA_ACCESS_MODE=ro \
    MULTICA_DEFAULT_DEVICE_NAME="HA Config (read-only)" \
    MULTICA_DEFAULT_RUNTIME_NAME="Claude (HA read-only)"
