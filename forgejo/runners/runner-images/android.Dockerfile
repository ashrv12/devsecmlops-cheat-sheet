FROM ubuntu:noble

# 1. Install baseline system dependencies (Added unzip, zip, and xz-utils for SDK extraction)
RUN apt-get update && apt-get install -y \
    ca-certificates curl gnupg git wget jq unzip zip xz-utils \
    && rm -rf /var/lib/apt/lists/*

# 2. Install mise via APT
RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://mise.jdx.dev/gpg-key.pub | gpg --dearmor -o /etc/apt/keyrings/mise-archive-keyring.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg arch=$(dpkg --print-architecture)] https://mise.jdx.dev/deb stable main" | tee /etc/apt/sources.list.d/mise.list && \
    apt-get update && apt-get install -y mise && \
    rm -rf /var/lib/apt/lists/*

# 3. Fetch and install Forgejo Runner
RUN ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/') && \
    RUNNER_VERSION=$(curl -s https://data.forgejo.org/api/v1/repos/forgejo/runner/releases/latest | jq .tag_name -r | sed 's/^v//') && \
    FORGEJO_URL="https://code.forgejo.org/forgejo/runner/releases/download/v${RUNNER_VERSION}/forgejo-runner-${RUNNER_VERSION}-linux-${ARCH}" && \
    curl -Lo /usr/local/bin/forgejo-runner ${FORGEJO_URL} && \
    chmod +x /usr/local/bin/forgejo-runner

# 4. Create unprivileged user and pre-create mise directory with correct permissions
RUN groupadd -g 1001 runnergroup && \
    useradd -u 1001 -g runnergroup -s /bin/bash -m runneruser && \
    mkdir -p /data /opt/mise && \
    chown -R 1001:1001 /data /opt/mise

WORKDIR /data
# Switch to the unprivileged user BEFORE installing backend languages/frameworks
USER 1001

ENV MISE_DATA_DIR=/opt/mise
ENV MISE_CONFIG_DIR=/opt/mise
ENV MISE_STATE_DIR=/opt/mise
ENV PATH="/opt/mise/shims:${PATH}"

# 5. Install Node, Java, Android SDK, and Flutter globally via mise as runneruser
RUN mise use --global node@24 && \
    mise use --global java@21

RUN mise use --global android-sdk@latest

RUN mise use --global flutter@latest

RUN mise reshim

# 6. Automatically accept Android SDK licenses (Required for headless CI compiles)
RUN yes | mise exec -- sdkmanager --licenses

ENTRYPOINT ["forgejo-runner", "daemon", "--config", "/config/runner-config.yml"]