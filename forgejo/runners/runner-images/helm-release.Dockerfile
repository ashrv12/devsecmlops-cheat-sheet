FROM ubuntu:noble

# 1. Install baseline system dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates curl gnupg git wget jq \
    && rm -rf /var/lib/apt/lists/*

RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4 | bash

RUN helm version

# 2. Install mise via APT
RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://mise.jdx.dev/gpg-key.pub | gpg --dearmor -o /etc/apt/keyrings/mise-archive-keyring.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg arch=$(dpkg --print-architecture)] https://mise.jdx.dev/deb stable main" | tee /etc/apt/sources.list.d/mise.list && \
    apt-get update && apt-get install -y mise && \
    rm -rf /var/lib/apt/lists/*

# 3. Install Node.js 24 and Java (Temurin) 25
ENV MISE_DATA_DIR=/opt/mise
ENV MISE_CONFIG_DIR=/opt/mise
ENV MISE_STATE_DIR=/opt/mise
ENV PATH="/opt/mise/shims:${PATH}"

RUN mise use --global node@24 && \
    mise reshim && \
    node -v

# 3. Fetch and install Forgejo Runner
RUN ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/') && \
    RUNNER_VERSION=$(curl -s https://data.forgejo.org/api/v1/repos/forgejo/runner/releases/latest | jq .tag_name -r | sed 's/^v//') && \
    FORGEJO_URL="https://code.forgejo.org/forgejo/runner/releases/download/v${RUNNER_VERSION}/forgejo-runner-${RUNNER_VERSION}-linux-${ARCH}" && \
    curl -Lo /usr/local/bin/forgejo-runner ${FORGEJO_URL} && \
    chmod +x /usr/local/bin/forgejo-runner

# 5. Fetch and install YQ (Hardened amd64 target)
RUN curl -Lo /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/v4.53.3/yq_linux_amd64" && \
    chmod 755 /usr/local/bin/yq && \
    yq --version

# 4. Create unprivileged user and set permissions
RUN groupadd -g 1001 runnergroup && \
    useradd -u 1001 -g runnergroup -s /bin/bash -m runneruser && \
    mkdir -p /data && \
    chown -R 1001:1001 /data

WORKDIR /data
USER 1001

RUN yq --version

ENTRYPOINT ["forgejo-runner", "daemon", "--config", "/config/runner-config.yml"]
