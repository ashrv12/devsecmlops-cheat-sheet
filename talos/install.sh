# install talosctl command line tool first
# macos
brew install siderolabs/tap/talosctl

# linux
curl -sL https://talos.dev/install | sh

# Create the patch.yml
# patch.yaml
# cluster:
#  network:
#    cni:
#      name: none      # Don't install Flannel
#  proxy:
#    disabled: true    # Cilium will replace kube-proxy via eBPF

talosctl gen config my-cluster https://192.168.1.37:6443 \
  --config-patch @patch.yaml

# This produces controlplane.yaml, worker.yaml, and talosconfig.
# Important: Talos requires a static IP so you can use its API. If you don't set this up beforehand, when Talos reboots after bootstrapping, it won't be accessible because the config files recorded that specific IP. Set a DHCP reservation on your router or configure a static interface in your patch.

# make sure to verify where to install the talos linux base install to
talosctl -n 192.168.1.37 get disks --insecure
# NODE   NAMESPACE   TYPE   ID        VERSION   SIZE     READ ONLY   TRANSPORT   ROTATIONAL   WWID                                   MODEL                            SERIAL
#        runtime     Disk   loop0     2         4.1 kB   true
#        runtime     Disk   loop1     2         83 MB    true
#        runtime     Disk   nvme0n1   2         256 GB   false       nvme                     eui.01000000000000008ce38e04032b9414   KBG40ZNS256G NVMe KIOXIA 256GB   Z1APH7DWQXA3
#        runtime     Disk   sda       7         62 GB    false       usb         true                                                SanDisk 3.2Gen1

# Edit your controlplane.yaml patch to explicitly set the install disk:
# machine:
#   install:
#     disk: /dev/nvme0n1  # your internal SSD, NOT /dev/sda
#     wipe: true

# Now for the first time you can boot the server with the talos iso image
# Once the console shows the maintenance mode IP, apply the config from your workstation:
talosctl apply-config --insecure \
  --nodes 192.168.1.37 \
  --file controlplane.yaml

# The --insecure flag is needed because the node doesn't yet have a configuration, so TLS hasn't been established. After the config is applied, the node will reboot and install Talos to disk. You can remove the USB after it reboots.

talosctl bootstrap

# Bootstrap kubernetes
export TALOSCONFIG="talosconfig"
talosctl config endpoint 192.168.1.37
talosctl config node 192.168.1.37

# Wait until kubelet, apiserver, controller-manager, and scheduler are shown as healthy. The node will not be Ready yet — that's expected, since there's no CNI installed.

# once the server shows it is healthy, you can fetch your kubectl config
talosctl kubeconfig ./kubeconfig
export KUBECONFIG=$(pwd)/kubeconfig

# apply the gateway api crds before cilium
kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.5.0/experimental-install.yaml

# add the helm repo for cilium, we will be deploying via helm
helm repo add cilium https://helm.cilium.io/
helm repo update

helm install cilium cilium/cilium \
  --namespace kube-system \
  --set ipam.mode=kubernetes \
  --set kubeProxyReplacement=true \
  --set gatewayAPI.enabled=true \
  --set securityContext.capabilities.ciliumAgent="{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}" \
  --set securityContext.capabilities.cleanCiliumState="{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}" \
  --set cgroup.autoMount.enabled=false \
  --set cgroup.hostRoot=/sys/fs/cgroup \
  --set k8sServiceHost=127.0.0.1 \
  --set k8sServicePort=7445

# cgroup.autoMount.enabled=false + cgroup.hostRoot=/sys/fs/cgroup — Talos already provides the cgroupv2 and bpffs mounts, so Cilium must not try to mount them itself. Sidero Documentation
# k8sServiceHost=127.0.0.1 / k8sServicePort=7445 — uses KubePrism, Talos's local API proxy, so Cilium can reach the API server before kube-proxy is running.
# SYS_MODULE is intentionally omitted — Talos does not allow loading kernel modules by Kubernetes workloads, so SYS_MODULE must be dropped from Cilium's default capabilities. Sidero Documentation

# in case you are running on a single node cluster
helm upgrade cilium cilium/cilium \
  -n kube-system \
  --reuse-values \
  --set operator.replicas=1

kubectl taint nodes --all node-role.kubernetes.io/control-plane-

# remove the taint to be able to deploy on your single node

kubectl run test --image=nginx --restart=Never
kubectl get pod test

# add this to the [./controlplane.yaml] before you bootstrap if you want it to be untainted always
# cluster:
#   allowSchedulingOnControlPlanes: true

kubectl expose pod test --port=80 --name=test-svc
# this creates a small cluster ip test svc

# edit your hosts file or dns to point to the server ip
sudo vi /etc/hosts

# now apply the gateway + http route
kubectl apply -f gateway-test.yaml

# if you dont see the ip and it is pending like here
kubectl get svc
# NAME                          TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
# cilium-gateway-test-gateway   LoadBalancer   10.105.20.208   <pending>     80:32449/TCP   31s
# kubernetes                    ClusterIP      10.96.0.1       <none>        443/TCP        27m
# test-svc                      ClusterIP      10.97.39.230    <none>        80/TCP         2m12s

# apply the ip pool
kubectl apply -f ippool.yaml

# and enable l2 announcements
helm upgrade cilium cilium/cilium \
  -n kube-system \
  --reuse-values \
  --set l2announcements.enabled=true

# verify the addresses
talosctl -n 192.168.1.37 get addresses
# NODE           NAMESPACE   TYPE            ID                                                    VERSION   ADDRESS                                     LINK
# 192.168.1.37   network     AddressStatus   cilium_host/10.244.0.111/32                           1         10.244.0.111/32                             cilium_host
# 192.168.1.37   network     AddressStatus   cilium_host/fe80::3849:e2ff:fe61:cc0d/64              2         fe80::3849:e2ff:fe61:cc0d/64                cilium_host
# 192.168.1.37   network     AddressStatus   cilium_net/fe80::207b:4cff:fe23:7ec2/64               2         fe80::207b:4cff:fe23:7ec2/64                cilium_net
# 192.168.1.37   network     AddressStatus   cilium_vxlan/fe80::ec6d:acff:fec6:ee35/64             2         fe80::ec6d:acff:fec6:ee35/64                cilium_vxlan
# 192.168.1.37   network     AddressStatus   enp0s31f6/192.168.1.37/24                             1         192.168.1.37/24                             enp0s31f6
# 192.168.1.37   network     AddressStatus   enp0s31f6/2407:6400:c000:d74:a229:19ff:fe73:9673/64   1         2407:6400:c000:d74:a229:19ff:fe73:9673/64   enp0s31f6
# 192.168.1.37   network     AddressStatus   enp0s31f6/fe80::a229:19ff:fe73:9673/64                2         fe80::a229:19ff:fe73:9673/64                enp0s31f6
# 192.168.1.37   network     AddressStatus   lo/127.0.0.1/8                                        1         127.0.0.1/8                                 lo
# 192.168.1.37   network     AddressStatus   lo/169.254.116.108/32                                 1         169.254.116.108/32                          lo
# 192.168.1.37   network     AddressStatus   lo/::1/128                                            1         ::1/128                                     lo
# 192.168.1.37   network     AddressStatus   lxc165f1eabc77b/fe80::c4d2:cbff:fe18:a514/64          2         fe80::c4d2:cbff:fe18:a514/64                lxc165f1eabc77b
# 192.168.1.37   network     AddressStatus   lxc9dbe80c2e7d2/fe80::1c45:3eff:fea4:799b/64          2         fe80::1c45:3eff:fea4:799b/64                lxc9dbe80c2e7d2
# 192.168.1.37   network     AddressStatus   lxc9eedadad2d87/fe80::d47f:b3ff:fe3a:3b3c/64          2         fe80::d47f:b3ff:fe3a:3b3c/64                lxc9eedadad2d87
# 192.168.1.37   network     AddressStatus   lxc_health/fe80::24cd:e4ff:fef5:1a00/64               2         fe80::24cd:e4ff:fef5:1a00/64                lxc_health

# create the CiliumL2AnnouncementPolicy using the interface
# 192.168.1.37   network     AddressStatus   enp0s31f6/192.168.1.37/24                             1         192.168.1.37/24                             enp0s31f6
kubectl apply -f l2announce.yaml

