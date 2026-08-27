# ==========================================
# STAGE 1: Build the Forgejo Runner from Source
# ==========================================
FROM ubuntu:noble AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    openssl \
    libssl3t64 \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y \
    curl git jq build-essential ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Install mise to pin a secured Go version
RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://mise.jdx.dev/gpg-key.pub | gpg --dearmor -o /etc/apt/keyrings/mise-archive-keyring.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg arch=$(dpkg --print-architecture)] https://mise.jdx.dev/deb stable main" | tee /etc/apt/sources.list.d/mise.list && \
    apt-get update && apt-get install -y mise

ENV PATH="/root/.local/share/mise/shims:${PATH}"

# Pin to a secure Go version that fixes CVE-2025-68121
RUN mise use --global go@1.24.13

# Clone and compile the exact latest version of forgejo-runner
RUN RUNNER_VERSION=$(curl -s https://data.forgejo.org/api/v1/repos/forgejo/runner/releases/latest | jq .tag_name -r) && \
    git clone --depth 1 --branch ${RUNNER_VERSION} https://code.forgejo.org/forgejo/runner.git /build

WORKDIR /build

RUN make build

# ==========================================
# STAGE 2: Final Lean Runner Image
# ==========================================
FROM ubuntu:noble

# Bump these to move versions. TRIVY_DB_REFRESH exists purely to bust
# the DB layer cache: --build-arg TRIVY_DB_REFRESH=$(date +%F)
ARG TRIVY_VERSION=0.74.0
ARG TRIVY_DB_REFRESH=initial

# 1. Install baseline system dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates curl gnupg git wget jq unzip zip \
    && rm -rf /var/lib/apt/lists/*

RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4 | bash

# 2. Install mise via APT
RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://mise.jdx.dev/gpg-key.pub | gpg --dearmor -o /etc/apt/keyrings/mise-archive-keyring.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg arch=$(dpkg --print-architecture)] https://mise.jdx.dev/deb stable main" | tee /etc/apt/sources.list.d/mise.list && \
    apt-get update && apt-get install -y mise && \
    rm -rf /var/lib/apt/lists/*

# 3. Setup global tools using mise
ENV MISE_DATA_DIR=/opt/mise
ENV MISE_CONFIG_DIR=/opt/mise
ENV MISE_STATE_DIR=/opt/mise
ENV PATH="/opt/mise/shims:${PATH}"

# Java 25 + a Maven new enough for Spring Boot 4.x (needs 3.9+), plus Gradle 9
RUN mise use --global \
        java@temurin-25 \
        maven@3.9.11 \
        gradle@9.1.0 \
        node@24 && \
    mise reshim && \
    ln -sfn "$(mise where java@temurin-25)" /opt/java

# Maven and Gradle read JAVA_HOME directly, the shims are not enough
ENV JAVA_HOME=/opt/java
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# 4. Copy the secure binary from the builder stage
COPY --from=builder /build/forgejo-runner /usr/local/bin/forgejo-runner
RUN chmod +x /usr/local/bin/forgejo-runner

# 5. Fetch and install YQ
RUN curl -Lo /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/v4.53.3/yq_linux_amd64" && \
    chmod 755 /usr/local/bin/yq


# 6. Install Trivy at a pinned version
RUN set -eux; \
    case "$(dpkg --print-architecture)" in \
      amd64) TRIVY_ARCH="Linux-64bit" ;; \
      arm64) TRIVY_ARCH="Linux-ARM64" ;; \
      *) echo "unsupported architecture: $(dpkg --print-architecture)" >&2; exit 1 ;; \
    esac; \
    cd /tmp; \
    base="https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}"; \
    curl -fsSLO "${base}/trivy_${TRIVY_VERSION}_${TRIVY_ARCH}.tar.gz"; \
    curl -fsSLO "${base}/trivy_${TRIVY_VERSION}_checksums.txt"; \
    grep "trivy_${TRIVY_VERSION}_${TRIVY_ARCH}.tar.gz$" "trivy_${TRIVY_VERSION}_checksums.txt" | sha256sum -c -; \
    tar -xzf "trivy_${TRIVY_VERSION}_${TRIVY_ARCH}.tar.gz" trivy; \
    install -m 0755 trivy /usr/local/bin/trivy; \
    rm -f trivy_${TRIVY_VERSION}_* trivy; \
    trivy --version

# 7. Bake the CVE data into the image
# Everything below this point should stay at the end of the file so a DB
# refresh rebuilds one layer instead of the whole image.
ENV TRIVY_CACHE_DIR=/opt/trivy/cache
ENV TRIVY_SKIP_DB_UPDATE=true
ENV TRIVY_SKIP_JAVA_DB_UPDATE=true
ENV TRIVY_SKIP_CHECK_UPDATE=true
ENV TRIVY_NO_PROGRESS=true

RUN echo "db refresh marker: ${TRIVY_DB_REFRESH}" && \
    mkdir -p "${TRIVY_CACHE_DIR}" /tmp/emptyscan && \
    # main vulnerability DB (OS packages, language advisories)
    trivy image --cache-dir "${TRIVY_CACHE_DIR}" --skip-db-update=false --download-db-only && \
    # Java DB: maps jar GAV coordinates when a pom is missing. Required for
    # scanning Spring Boot fat jars offline.
    trivy image --cache-dir "${TRIVY_CACHE_DIR}" --skip-java-db-update=false --download-java-db-only && \
    # misconfiguration checks bundle, pulled by running one throwaway scan
    trivy config --cache-dir "${TRIVY_CACHE_DIR}" --skip-check-update=false /tmp/emptyscan || true && \
    rm -rf /tmp/emptyscan && \
    du -sh "${TRIVY_CACHE_DIR}"

# 8. Create unprivileged user and set permissions
RUN groupadd -g 1001 runnergroup && \
    useradd -u 1001 -g runnergroup -s /bin/bash -m runneruser && \
    mkdir -p /data && \
    chown -R 1001:1001 /data && \
    chown -R 1001:1001 /opt/trivy && \
    mkdir -p /home/runneruser/.m2 /home/runneruser/.gradle && \
    chown -R 1001:1001 /home/runneruser

WORKDIR /data
USER 1001

ENTRYPOINT ["forgejo-runner", "daemon", "--config", "/config/runner-config.yml"]
