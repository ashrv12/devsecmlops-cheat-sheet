#!/bin/bash

set -e
set -o pipefail

echo "========================================================="
echo " Starting Hardened Kubernetes v1.35 Worker Setup         "
echo " Stack: Containerd + v1.35 Kubelet                       "
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
echo "[Step 2] Installing containerd.io..."
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

### Step 3: Installing Kubernetes v1.35 Packages ###
echo "[Step 3] Adding Kubernetes v1.35 repository and installing packages..."
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key | sudo gpg --dearmor --yes -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.35/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list >/dev/null

sudo apt-get update >/dev/null
# Matching the master version: 1.35.*
sudo apt-get install -y kubelet=1.35.* kubeadm=1.35.* kubectl=1.35.* >/dev/null
sudo apt-mark hold kubelet kubeadm kubectl

sudo systemctl enable --now kubelet

echo "========================================================="
echo " Worker node is ready to join.                          "
echo " Run the 'kubeadm join' command provided by your master. "
echo "========================================================="
