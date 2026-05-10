FROM ubuntu:noble

# 1. Install system dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    git \
    wget \
    jq \
    && rm -rf /var/lib/apt/lists/*

# 2. Install mise via APT
RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://mise.jdx.dev/gpg-key.pub | gpg --dearmor -o /etc/apt/keyrings/mise-archive-keyring.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg arch=$(dpkg --print-architecture)] https://mise.jdx.dev/deb stable main" | tee /etc/apt/sources.list.d/mise.list && \
    apt-get update && apt-get install -y mise && \
    rm -rf /var/lib/apt/lists/*

# 3. Install Node.js 24 and Java (Temurin) 25
# We use 'mise install' and then add the shims to the PATH
ENV MISE_DATA_DIR=/opt/mise
ENV MISE_CONFIG_DIR=/opt/mise
ENV MISE_STATE_DIR=/opt/mise
ENV PATH="/opt/mise/shims:${PATH}"

RUN mise use --global node@24 java@temurin-25 && \
    mise reshim && \
    node -v && java -version

RUN node -v && java -version

# 4. Install Docker CLI (your existing logic)
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && apt-get install -y docker-ce-cli docker-buildx-plugin && \
    rm -rf /var/lib/apt/lists/*

# 5. Fetch and install Forgejo Runner
RUN ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/') && \
    RUNNER_VERSION=$(curl -s https://data.forgejo.org/api/v1/repos/forgejo/runner/releases/latest | jq .tag_name -r | sed 's/^v//') && \
    FORGEJO_URL="https://code.forgejo.org/forgejo/runner/releases/download/v${RUNNER_VERSION}/forgejo-runner-${RUNNER_VERSION}-linux-${ARCH}" && \
    curl -Lo /usr/local/bin/forgejo-runner ${FORGEJO_URL} && \
    chmod +x /usr/local/bin/forgejo-runner

WORKDIR /data
USER root
ENTRYPOINT ["forgejo-runner", "daemon", "--config", "runner-config.yml"]