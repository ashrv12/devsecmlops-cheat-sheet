# Minimal Java runtime with the OpenTelemetry Java agent.
#
# Runtime: distroless Temurin, nonroot (uid 65532). No shell, no package
# manager. Jib uses this as its base and adds the app layers on top.
#
# Build (one image per Java version, same agent):
#   p build -f java-otel.Dockerfile --build-arg JAVA_VERSION=25 --build-arg OTEL_SHA256=<sha256> \
#     -t harbor.internal.m-business.mn/library/java25-otel:2.33.1 .
#   p build -f java-otel.Dockerfile --build-arg JAVA_VERSION=17 --build-arg OTEL_SHA256=<sha256> \
#     -t harbor.internal.m-business.mn/library/java17-otel:2.33.1 .

ARG JAVA_VERSION=25
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
FROM gcr.io/distroless/java${JAVA_VERSION}-debian13:nonroot
ARG JAVA_VERSION
ARG OTEL_VERSION

LABEL org.opencontainers.image.title="java${JAVA_VERSION}-otel" \
      org.opencontainers.image.description="Distroless Temurin ${JAVA_VERSION} + OpenTelemetry Java agent ${OTEL_VERSION}"

# Root-owned and read-only for the app user.
COPY --from=otel --chmod=0444 /opentelemetry-javaagent.jar /otel/opentelemetry-javaagent.jar

# Agent only. Memory and GC flags belong in each app's Helm values
# (JAVA_TOOL_OPTIONS), so nothing here overrides them.
# Configure the agent per app with OTEL_* env vars; disable it with
# OTEL_JAVAAGENT_ENABLED=false.
ENV JDK_JAVA_OPTIONS="-javaagent:/otel/opentelemetry-javaagent.jar"

