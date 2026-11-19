# Minimal Forgejo runner for Next.js builds, without Docker.
# Jobs run directly inside this container ("host" label): npm builds the app,
# crane assembles and pushes the OCI image straight to the registry.
#
# Debian (glibc) on purpose: the app runs on the glibc-based distroless bun
# image, so anything with native code is built against the same libc.

ARG RUNNER_VERSION=13.2.1
ARG CRANE_VERSION=v0.22.1
ARG NODE_VERSION=22

FROM data.forgejo.org/forgejo/runner:${RUNNER_VERSION} AS runner
FROM gcr.io/go-containerregistry/crane:${CRANE_VERSION} AS crane

FROM docker.io/library/node:${NODE_VERSION}-bookworm-slim

# git  -> checkout and GitOps commits
# tini -> reaps zombie processes left by jobs
# node -> already in the base: runs npm and JavaScript actions (checkout)
RUN apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y --no-install-recommends git ca-certificates tini \
 && rm -rf /var/lib/apt/lists/* \
 && usermod -d /data -l runner node \
 && groupmod -n runner node

COPY --from=runner /bin/forgejo-runner /usr/local/bin/forgejo-runner
COPY --from=crane /ko-app/crane /usr/local/bin/crane

# Fails the image build if either binary is missing or broken.
RUN forgejo-runner --version && crane version

USER 1000:1000
WORKDIR /data
ENV HOME=/data

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["forgejo-runner", "--config", "/etc/forgejo-runner/config.yml", "daemon"]

