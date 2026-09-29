# otel.Dockerfile
# ==========================================
# Stage 1: Download the OpenTelemetry Agent
# ==========================================
FROM docker.io/library/alpine:3.24 AS telemetry-fetcher

# Define the OpenTelemetry Javaagent version
ARG OTEL_VERSION=2.31.1
# sha256 of the v2.31.1 release asset (25107554 bytes).
# Update this whenever OTEL_VERSION changes, or the build will fail closed.
ARG OTEL_SHA256=bbf83c151b6400709e2f225bdd07a04f839d9d13b8b93464241333fd25d3e3ba

RUN apk add --no-cache curl && \
    curl -fL -s -o /opentelemetry-javaagent.jar \
      "https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/v${OTEL_VERSION}/opentelemetry-javaagent.jar" && \
    echo "${OTEL_SHA256}  /opentelemetry-javaagent.jar" | sha256sum -c -

# ==========================================
# Stage 2: Final Minimal Runtime Image
# ==========================================
FROM docker.io/library/eclipse-temurin:25-jre-jammy

LABEL maintainer="DevOps Team" \
      description="Eclipse Temurin 25 JRE on Ubuntu Jammy with OpenTelemetry Java Agent pre-installed." \
      otel.javaagent.version="2.31.1"

# Place the telemetry agent in the expected standard directory
COPY --from=telemetry-fetcher /opentelemetry-javaagent.jar /opt/opentelemetry-javaagent.jar

# Ensure the jar is universally readable
RUN chmod 644 /opt/opentelemetry-javaagent.jar

# Default to root for base setup (downstream applications will drop privileges to 'appuser')
USER root
