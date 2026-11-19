# Minimal Forgejo runner for Go projects, without Docker.
# Jobs run directly inside this container ("host" label): go builds and tests
# the code; ko or crane assembles the OCI image and pushes it straight to the
# registry. ko for plain services, crane when the image needs extra files.

ARG RUNNER_VERSION=13.2.1
ARG GO_VERSION=1.27
# Pin to the newest release from https://github.com/ko-build/ko/releases
ARG KO_VERSION=v0.19.1
ARG CRANE_VERSION=v0.22.1

FROM data.forgejo.org/forgejo/runner:${RUNNER_VERSION} AS runner

# ko and crane are compiled here with the current Go toolchain, so the
# binaries don't carry the Go standard-library CVEs of older prebuilt releases.
FROM harbor.internal.m-business.mn/dockerhub/library/golang:${GO_VERSION}-alpine AS tools
ARG KO_VERSION
ARG CRANE_VERSION
RUN CGO_ENABLED=0 GOBIN=/out go install github.com/google/ko@${KO_VERSION} \
 && CGO_ENABLED=0 GOBIN=/out go install github.com/google/go-containerregistry/cmd/crane@${CRANE_VERSION}

FROM harbor.internal.m-business.mn/dockerhub/library/golang:${GO_VERSION}-alpine

# git    -> checkout, private Go modules
# nodejs -> runtime for JavaScript actions (actions/checkout)
# bash   -> default shell for `run:` steps
# tini   -> reaps zombie processes left by jobs
# tar    -> GNU tar, for reproducible root-owned image layers
RUN apk upgrade --no-cache \
 && apk add --no-cache git nodejs bash tini tar ca-certificates \
 && addgroup -g 1000 runner \
 && adduser -D -u 1000 -G runner -h /data runner

COPY --from=runner /bin/forgejo-runner /usr/local/bin/forgejo-runner
COPY --from=tools /out/ko /out/crane /usr/local/bin/

# Fails the image build if any binary is missing or broken.
RUN forgejo-runner --version && ko version && crane version && go version

USER 1000:1000
WORKDIR /data

# Module and build caches live on the runner's persistent volume.
ENV HOME=/data \
    GOPATH=/data/go \
    GOCACHE=/data/.cache/go-build \
    GOFLAGS=-buildvcs=false

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["forgejo-runner", "--config", "/etc/forgejo-runner/config.yml", "daemon"]
