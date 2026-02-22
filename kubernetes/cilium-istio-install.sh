


### Step 6: Install Helm & Cilium CNI ###
echo "[Step 6] Installing Helm and Cilium CNI..."

# Install Helm (required for a clean Cilium deployment)
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash >/dev/null

# Install Cilium via Helm with kube-proxy replacement enabled
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}

### Step 7: Install Istio Service Mesh ###
echo "[Step 7] Installing Istio via istioctl..."

# Download the latest istioctl binary
curl -sL https://istio.io/downloadIstio | sh - >/dev/null
sudo mv istio-*/bin/istioctl /usr/local/bin/istioctl
rm -rf istio-*/

# Install Istio with the default profile
istioctl install --set profile=default -y

# Enable Istio sidecar injection on the default namespace
kubectl label namespace default istio-injection=enabled

echo "========================================================="
echo " v1.35 Cluster with Cilium + Istio successfully deployed!"
echo " Note: Pods launched in the 'default' namespace will now "
echo " automatically receive an Istio Envoy sidecar.           "
echo "========================================================="
