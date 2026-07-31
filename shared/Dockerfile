ARG BUILD_FROM
FROM ${BUILD_FROM}

ARG BUILD_ARCH
ARG MULTICA_VERSION=0.4.15

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
         amd64) MULTICA_ARCH="amd64" ;; \
         aarch64) MULTICA_ARCH="arm64" ;; \
         *) echo "Unsupported arch: ${BUILD_ARCH}" >&2; exit 1 ;; \
       esac \
    \
    && curl -fsSL \
         "https://github.com/multica-ai/multica/releases/download/v${MULTICA_VERSION}/multica-cli-${MULTICA_VERSION}-linux-${MULTICA_ARCH}.tar.gz" \
         -o /tmp/multica.tar.gz \
    && tar -xzf /tmp/multica.tar.gz -C /tmp \
    && install -m 0755 /tmp/multica /usr/local/bin/multica \
    && rm -rf /tmp/multica /tmp/multica.tar.gz \
    \
    && curl -fsSL https://claude.ai/install.sh | bash \
    && CLAUDE_BIN="$(command -v claude || true)" \
    && if [[ -z "${CLAUDE_BIN}" ]]; then \
         for candidate in /root/.local/bin/claude /root/.claude/local/claude; do \
           [[ -x "${candidate}" ]] && CLAUDE_BIN="${candidate}" && break; \
         done; \
       fi \
    && [[ -n "${CLAUDE_BIN}" ]] \
    && install -m 0755 "${CLAUDE_BIN}" /usr/local/bin/claude \
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
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0

WORKDIR /data
