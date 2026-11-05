# Minimal Java 25 runtime with the OpenTelemetry Java agent.
#
# Runtime: distroless Temurin 25, nonroot (uid 65532). No shell, no package
# manager. Jib uses this as its base and adds the app layers on top.
#
# Build:
#   p build -f Dockerfile \
#     --build-arg OTEL_SHA256=<sha256 of the agent jar> \
#     -t harbor.internal.m-business.mn/library/java25-otel:2.33.1 .

ARG OTEL_VERSION=2.33.1

# ---------- fetch + verify the agent ----------
FROM docker.io/library/alpine:3 AS otel
ARG OTEL_VERSION
ARG OTEL_SHA256
RUN test -n "$OTEL_SHA256" || { echo "OTEL_SHA256 build arg is required" >&2; exit 1; } \
 && wget -qO /opentelemetry-javaagent.jar \
    "https://repo1.maven.org/maven2/io/opentelemetry/javaagent/opentelemetry-javaagent/${OTEL_VERSION}/opentelemetry-javaagent-${OTEL_VERSION}.jar" \
 && echo "${OTEL_SHA256}  /opentelemetry-javaagent.jar" | sha256sum -c -

# ---------- runtime ----------
FROM gcr.io/distroless/java25-debian13:nonroot
ARG OTEL_VERSION

LABEL org.opencontainers.image.title="java25-otel" \
      org.opencontainers.image.description="Distroless Temurin 25 JRE + OpenTelemetry Java agent ${OTEL_VERSION}"

# Root-owned and read-only for the app user.
COPY --from=otel --chmod=0444 /opentelemetry-javaagent.jar /otel/opentelemetry-javaagent.jar

# JDK_JAVA_OPTIONS is read by the java launcher only, which leaves
# JAVA_TOOL_OPTIONS free for per-app flags set in Helm.
# Configure the agent per app with OTEL_* env vars (OTEL_SERVICE_NAME,
# OTEL_EXPORTER_OTLP_ENDPOINT, ...). Disable it with OTEL_JAVAAGENT_ENABLED=false.
ENV JDK_JAVA_OPTIONS="-javaagent:/otel/opentelemetry-javaagent.jar"

