# 5. Custom Runner Image Dockerfile
# To eliminate setup overhead during the pipeline run, here is the 
# Dockerfile specification to construct the recommended custom runner image 
# containing Mandrel, the Polylith CLI, and specific locale setups.

# Start from the requested Mandrel base
FROM ghcr.io/graalvm/mandrel:23-openjdk-21-ol9

# Install base dependencies and localization packages
RUN dnf update -y && \
    dnf install -y wget curl git unzip tar fontconfig freetype glibc-locale-source glibc-langpack-ru && \
    dnf clean all

# Generate Russian locales to support localized invoice/document generation
RUN localedef -c -i ru_RU -f UTF-8 ru_RU.UTF-8
ENV LANG=ru_RU.UTF-8 \
    LANGUAGE=ru_RU:ru \
    LC_ALL=ru_RU.UTF-8

# Install Gradle
ARG GRADLE_VERSION=8.7
RUN wget -q https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip -P /tmp && \
    unzip -d /opt/gradle /tmp/gradle-${GRADLE_VERSION}-bin.zip && \
    ln -s /opt/gradle/gradle-${GRADLE_VERSION}/bin/gradle /usr/local/bin/gradle && \
    rm /tmp/gradle-${GRADLE_VERSION}-bin.zip

# Install Polylith CLI
ARG POLY_VERSION=0.2.19
RUN wget -q https://github.com/polyfy/polylith/releases/download/v${POLY_VERSION}/poly-${POLY_VERSION}.jar -O /usr/local/bin/poly.jar && \
    echo '#!/bin/bash\njava -jar /usr/local/bin/poly.jar "$@"' > /usr/local/bin/poly && \
    chmod +x /usr/local/bin/poly

# Add the Forgejo act_runner binary
ARG RUNNER_VERSION=0.3.5
RUN wget -q https://gitea.com/gitea/act_runner/releases/download/v${RUNNER_VERSION}/act_runner-${RUNNER_VERSION}-linux-amd64 -O /usr/local/bin/act_runner && \
    chmod +x /usr/local/bin/act_runner

# Setup a non-root user matching the Kubernetes securityContext
RUN useradd -m -d /home/runner -u 1000 -s /bin/bash runner && \
    mkdir -p /home/runner/.gradle /workspace && \
    chown -R runner:runner /home/runner /workspace

USER runner
WORKDIR /workspace

# Start the runner daemon
CMD ["act_runner", "daemon"]