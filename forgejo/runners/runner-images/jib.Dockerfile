# Minimal Forgejo runner for Spring Boot + Jib.
# Jobs run directly inside this container ("host" label), so there is no
# Docker, no DinD and no privileged pod. Jib builds and pushes the OCI image
# without a daemon.

ARG RUNNER_VERSION=12
ARG JAVA_VERSION=25

FROM data.forgejo.org/forgejo/runner:${RUNNER_VERSION} AS runner

FROM docker.io/library/eclipse-temurin:${JAVA_VERSION}-jdk-alpine

# git    -> actions/checkout
# nodejs -> runtime for JavaScript actions (checkout etc.)
# bash   -> default shell for `run:` steps
# tini   -> reaps zombie processes left by jobs
RUN apk add --no-cache git nodejs bash tini \
 && addgroup -g 1000 runner \
 && adduser -D -u 1000 -G runner -h /data runner

COPY --from=runner /bin/forgejo-runner /usr/local/bin/forgejo-runner

USER 1000:1000
WORKDIR /data
ENV HOME=/data

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["forgejo-runner", "--config", "/etc/forgejo-runner/config.yml", "daemon"]

