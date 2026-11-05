# Minimal Forgejo runner for GitOps tag bumps: checkout, yq, git commit/push.
# Jobs run directly in this container (host label), no Docker needed.

ARG RUNNER_VERSION=13.2.1
ARG YQ_VERSION=4.54.1

FROM data.forgejo.org/forgejo/runner:${RUNNER_VERSION} AS runner
FROM docker.io/mikefarah/yq:${YQ_VERSION} AS yq

FROM docker.io/library/alpine:3

# git    -> checkout, commit, push
# nodejs -> runtime for JavaScript actions (actions/checkout)
# bash   -> default shell for `run:` steps
# tini   -> reaps zombie processes left by jobs
RUN apk add --no-cache git nodejs bash tini ca-certificates \
 && addgroup -g 1001 runnergroup \
 && adduser -D -u 1001 -G runnergroup -h /data -s /bin/bash runneruser

COPY --from=runner /bin/forgejo-runner /usr/local/bin/forgejo-runner
# Same path as before, so existing workflows calling /usr/local/bin/yq keep working
COPY --from=yq /usr/bin/yq /usr/local/bin/yq

USER 1001:1001
WORKDIR /data
ENV HOME=/data

ENTRYPOINT ["/sbin/tini", "--", "forgejo-runner", "daemon", "--config", "/config/runner-config.yml"]

