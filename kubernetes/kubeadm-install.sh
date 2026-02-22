#!/bin/bash

set -e
set -o pipefail

echo "========================================================="
echo " Starting Hardened Kubernetes v1.35 Setup Script         "
echo " Stack: Containerd + Cilium (eBPF) + Istio               "
echo "========================================================="

### Step 1: Pre-flight & Kernel Configuration ###
echo "[Step 1] Disabling swap and configuring kernel parameters..."

sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf >/dev/null
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf >/dev/null
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system >/dev/null

### Step 2: Install and Configure containerd ###
echo "[Step 2] Installing containerd.io from Docker's official repository..."

sudo apt-get update >/dev/null
sudo apt-get install -y ca-certificates curl gnupg lsb-release apt-transport-https >/dev/null

sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

sudo apt-get update >/dev/null
sudo apt-get install -y containerd.io >/dev/null

sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

sudo systemctl restart containerd
sudo systemctl enable containerd

### Step 3: Configuring Repo and Installing Kubernetes v1.35 ###
echo "[Step 3] Adding Kubernetes v1.35 repository and installing packages..."

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key | sudo gpg --dearmor --yes -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.35/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list >/dev/null

sudo apt-get update >/dev/null
# Using wildcard to grab the latest v1.35.x patch release available
sudo apt-get install -y kubelet=1.35.* kubeadm=1.35.* kubectl=1.35.* >/dev/null
sudo apt-mark hold kubelet kubeadm kubectl

sudo systemctl enable --now kubelet

### Step 4: Initialize Cluster with kubeadm ###
echo "[Step 4] Initializing Kubernetes cluster (without kube-proxy)..."

# We pass --skip-phases=addon/kube-proxy because Cilium will completely replace it using eBPF
sudo kubeadm init --pod-network-cidr=10.0.0.0/8 --skip-phases=addon/kube-proxy

mkdir -p "$HOME/.kube"
sudo cp -i /etc/kubernetes/admin.conf "$HOME/.kube/config"
sudo chown "$(id -u):$(id -g)" "$HOME/.kube/config"
chmod 600 "$HOME/.kube/config"

### Step 5: Remove the Control-Plane Taint ###
echo "[Step 5] Removing control-plane taint..."

kubectl taint nodes --all node-role.kubernetes.io/control-plane- || true

