FROM ubuntu:noble

# 1. Install baseline system dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates curl gnupg git wget jq \
    && rm -rf /var/lib/apt/lists/*

RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4 | bash

RUN helm version

# 3. Fetch and install Forgejo Runner
RUN ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/') && \
    RUNNER_VERSION=$(curl -s https://data.forgejo.org/api/v1/repos/forgejo/runner/releases/latest | jq .tag_name -r | sed 's/^v//') && \
    FORGEJO_URL="https://code.forgejo.org/forgejo/runner/releases/download/v${RUNNER_VERSION}/forgejo-runner-${RUNNER_VERSION}-linux-${ARCH}" && \
    curl -Lo /usr/local/bin/forgejo-runner ${FORGEJO_URL} && \
    chmod +x /usr/local/bin/forgejo-runner

# 4. Create unprivileged user and set permissions
RUN groupadd -g 1001 runnergroup && \
    useradd -u 1001 -g runnergroup -s /bin/bash -m runneruser && \
    mkdir -p /data && \
    chown -R 1001:1001 /data

WORKDIR /data
USER 1001

ENTRYPOINT ["forgejo-runner", "daemon", "--config", "/config/runner-config.yml"]