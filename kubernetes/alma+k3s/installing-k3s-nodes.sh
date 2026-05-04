# ------------------------------------------------------------------

# prereq
sudo dnf update

# install on all nodes
sudo dnf install bind-utils

# Enable the EPEL repository
sudo dnf install epel-release -y

# Install the WireGuard tools
sudo dnf install wireguard-tools -y

# Load the module immediately
sudo modprobe wireguard

# Verify it is loaded (you should see 'wireguard' in the output)
lsmod | grep wireguard

# Ensure the module loads automatically upon system reboot
echo "wireguard" | sudo tee /etc/modules-load.d/wireguard.conf

# Configure sysctl to enable IPv4 forwarding
echo "net.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf

# Apply the changes immediately
sudo sysctl -p /etc/sysctl.d/99-kubernetes-cri.conf

# Open the default WireGuard port
sudo firewall-cmd --permanent --add-port=51820/udp

# Reload the firewall to apply changes
sudo firewall-cmd --reload

# install tar first
sudo dnf install tar

# ------------------------------------------------------------------

# Master node script
curl -sfL https://get.k3s.io | sh -s - --flannel-backend none --disable-network-policy --disable-kube-proxy --disable traefik

# where to find the token
cat /var/lib/rancher/k3s/server/token
# K101e7a9932c06c272<mock-token>eac2d54764cf11be55f5fbb599a79::server:22142d805b6eab9c10f996e2112af9e5

# Worker node script
curl -sfL https://get.k3s.io | K3S_URL=https://192.168.50.200:6443 \
 K3S_TOKEN=K101e7a9932c06c272<mock-token>eac2d54764cf11be55f5fbb599a79::server:22142d805b6eab9c10f996e2112af9e5 sh -

# Find the EXPERIMENTAL channel crd kubectl apply guide
https://gateway-api.sigs.k8s.io/guides/getting-started/#install-standard-channel


# ------------------------------------------------------------------

# in case you have installed the incorrect one just do
kubectl delete -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.5.0/standard-install.yaml

# in case you want to restart the cilium operator
a

# ------------------------------------------------------------------

# verify the experimental crd's
kubectl get crd | grep gateway.networking.k8s.io

# create a session for telling cilium where the kubeconfig file is
export KUBECONFIG=/path/to/your/admin.conf
# Then run cilium install...

# or just use the default by copying the config
mkdir -p $HOME/.kube
sudo cp -i /etc/rancher/k3s/k3s.yaml $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# install cilium cli
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}


# cilium command
cilium install \
 --set kubeProxyReplacement=true \
 --set k8sServiceHost=192.168.50.200 \
 --set k8sServicePort=6443 \
 --set encryption.enabled=true \
 --set encryption.type=wireguard \
 --set encryption.nodeEncryption=true \
 --set hubble.relay.enabled=true \
 --set hubble.ui.enabled=true \
 --set operator.replicas=1 \
 --set gatewayAPI.enabled=true