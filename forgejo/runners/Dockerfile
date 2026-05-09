FROM data.forgejo.org/forgejo/runner:12

RUN export ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')
RUN export RUNNER_VERSION=$(curl -X 'GET' https://data.forgejo.org/api/v1/repos/forgejo/runner/releases/latest | jq .name -r | cut -c 2-)
RUN export FORGEJO_URL="https://code.forgejo.org/forgejo/runner/releases/download/v${RUNNER_VERSION}/forgejo-runner-${RUNNER_VERSION}-linux-${ARCH}"
RUN wget -O forgejo-runner ${FORGEJO_URL} || curl -o forgejo-runner ${FORGEJO_URL}
RUN chmod +x forgejo-runner
RUN wget -O forgejo-runner.asc ${FORGEJO_URL}.asc || curl -o forgejo-runner.asc ${FORGEJO_URL}.asc
RUN gpg --keyserver hkps://keys.openpgp.org --recv EB114F5E6C0DC2BCDD183550A4B61A2DC5923710
RUN gpg --verify forgejo-runner.asc forgejo-runner && echo "✓ Verified" || echo "✗ Failed"

# Good signature from "Forgejo <contact@forgejo.org>"
#         aka "Forgejo Releases <release@forgejo.org>"
# ✓ Verified

RUN cp forgejo-runner /usr/local/bin/forgejo-runner

RUN forgejo-runner -v
# forgejo-runner version v12.7.3

RUN useradd --create-home runner
RUN usermod -aG docker runner

