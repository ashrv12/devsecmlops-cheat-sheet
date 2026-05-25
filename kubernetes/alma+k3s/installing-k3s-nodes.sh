# ------------------------------------------------------------------

firewall-cmd --permanent --add-port=6443/tcp #apiserver
firewall-cmd --permanent --zone=trusted --add-source=10.42.0.0/16 #pods
firewall-cmd --permanent --zone=trusted --add-source=10.43.0.0/16 #services
firewall-cmd --reload

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

# install tar first
sudo dnf install tar

# HOW TO SETUP TRUSTED ZONES BETWEEN CLUSTER NODES SO THAT THEY CAN HAVE FULL ACCESS
# TO EVERY PORT WITH EACH OTHER

# Add the first node
sudo firewall-cmd --permanent --zone=trusted --add-source=192.168.23.200/32

# Add the second node
sudo firewall-cmd --permanent --zone=trusted --add-source=192.168.23.201/32

# Add the third node
sudo firewall-cmd --permanent --zone=trusted --add-source=10.200.200.90/32

# Apply the changes
sudo firewall-cmd --reload

# =================================================================

# HOW TO CHECK DNS CONFIGURATION

# Obtain [CONNECTION_NAME]
nmcli connection show

# current nameservers
cat /etc/resolv.conf

# Set the new DNS servers
nmcli connection modify "[CONNECTION_NAME]" ipv4.dns "8.8.8.8 8.8.4.4"

# Apply the dns changes
nmcli connection up "[CONNECTION_NAME]"

# =================================================================


# *****************************************************************

# THIS IS FOR REMOVING UNNECESSARY PUBLIC PORTS IF THERE ARE ANY AND MOVING FROM
# PUBLIC ZONE TO TRUSTED PRIVATE ZONE FIREWALL SETUP FOR NODE TO NODE CONNECTIVITY

# Remove Cilium VXLAN and Health Check ports
sudo firewall-cmd --permanent --remove-port=8472/udp
sudo firewall-cmd --permanent --remove-port=4240/tcp

# Remove Hubble ports
sudo firewall-cmd --permanent --remove-port=4244/tcp
sudo firewall-cmd --permanent --remove-port=4245/tcp

# Optional: Only do this if you don't need to access the API from a 4th machine
sudo firewall-cmd --permanent --remove-port=6443/tcp

# remove this from the public firewall
sudo firewall-cmd --permanent --remove-port=51820/udp

# Apply the changes
sudo firewall-cmd --reload

# Note: Your nodes will still be able to communicate on 51820 (and all other ports) because their specific
# IP addresses (192.168.50.212, etc.) are now recognized by the trusted zone.

# *****************************************************************

# Apply the changes
sudo firewall-cmd --reload

# ------------------------------------------------------------------

# Master node script
curl -sfL https://get.k3s.io | sh -s - --flannel-backend none --disable-network-policy --disable-kube-proxy --disable traefik
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC='--flannel-backend=none --disable-network-policy --disable traefik' sh -

# where to find the token
cat /var/lib/rancher/k3s/server/token
# K101e7a9932c06c272<mock-token>eac2d54764cf11be55f5fbb599a79::server:22142d805b6eab9c10f996e2112af9e5

# Worker node script
curl -sfL https://get.k3s.io | K3S_URL=https://192.168.50.212:6443 \
 K3S_TOKEN=K101e7a9932c06c272<mock-token>eac2d54764cf11be55f5fbb599a79::server:22142d805b6eab9c10f996e2112af9e5 sh -


curl -sfL https://get.k3s.io | K3S_URL='https://192.168.50.212:6443' K3S_TOKEN=K10b82269d9ffa6254561fc34c10bfcbaa99543e5bc26eba9bfb17980c8f1ad7edc::server:9b7bc29b7a908c83da3372faaffc46e6 sh -

# Find the EXPERIMENTAL channel crd kubectl apply guide
https://gateway-api.sigs.k8s.io/guides/getting-started/#install-standard-channel

kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.5.0/experimental-install.yaml


# ------------------------------------------------------------------

# in case you have installed the incorrect one just do
kubectl delete -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.5.0/standard-install.yaml

# in case you want to restart the cilium operator
a

# ------------------------------------------------------------------

# verify the experimental crd's
kubectl get crd | grep gateway.networking.k8s.io

# create a session for telling cilium where the kubeconfig file is
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
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


cilium install --version 1.19.3 --set=ipam.operator.clusterPoolIPv4PodCIDRList="10.42.0.0/16"

# cilium command
cilium install \
    --set=ipam.operator.clusterPoolIPv4PodCIDRList="10.42.0.0/16" \
    --set kubeProxyReplacement=true \
    --set k8sServiceHost=172.29.1.10 \
    --set k8sServicePort=6443 \
    --set encryption.enabled=true \
    --set encryption.type=wireguard \
    --set encryption.nodeEncryption=true \
    --set hubble.relay.enabled=true \
    --set hubble.ui.enabled=true \
    --set operator.replicas=1 \
    --set ingressController.enabled=true

API_SERVER_IP=`hostname -I`
API_SERVER_PORT=6443
POD_CIDR="10.42.0.0/16"
cilium install \
    --set k8sServiceHost=${API_SERVER_IP} \
    --set k8sServicePort=${API_SERVER_PORT} \
    --set ipam.operator.clusterPoolIPv4PodCIDRList=$POD_CIDR \
    --set kubeProxyReplacement=true \
    --set hubble.relay.enabled=true \
    --set hubble.ui.enabled=true \
    --set operator.replicas=1 \
    --set ingressController.enabled=true


cilium upgrade \
    --reuse-values \
    --set ingressController.enabled=true

# restart cilium
kubectl rollout restart deployment cilium-operator -n kube-system

# critical \/
https://docs.cilium.io/en/stable/installation/k3s/

ss -tulpn | grep -E ":809[0-9]"