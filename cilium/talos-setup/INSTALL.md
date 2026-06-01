# How to bootstrap talos

Obtain the configuration files first

```bash
talosctl gen config cluster-name https://<FUTURE_CONTROL_PLANE_IP>:6443
```

Obtain main disk

```bash
talosctl -n 192.168.1.19 get disks --insecure
```

Modify the control-plane.yaml

```bash
machine:
  install:
    disk: /dev/nvme0n1  # <- Target your system SSD here
    wipe: true          # <- Ensures all old partitions are destroyed and the full size is claimed
    image: ghcr.io/siderolabs/installer:v1.7.5 # (Matches your booted Talos version)

# ... [rest of your machine config remains the same] ...

cluster:
    id: dOmvPDLusa-1hvj6hbEB2tCLpgw34b5ed6p-HU=
    secret: /vM5nKY39FWqmVqbHcv/EXSc7/V3ys5JYSluvEvQno=
    controlPlane:
        endpoint: https://192.168.11.19:6443
    clusterName: cluster-name

    # 1. Configure the network to use a custom CNI
    network:
        dnsDomain: cluster.local
        podSubnets:
            - 10.244.0.0/16
        serviceSubnets:
            - 10.96.0.0/12
        cni:
            name: none

    token: hckg28.mczr2q87by55gngm
    secretboxEncryptionSecret: aw6ZNEJWzec7hK20JWceMIGd1Fc+5WsSY2nQnMDYigQ=
    ca:
        crt: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0t...
        key: LS0tLS1CRUdJTiBFQyBQUklWQVRFIEtFWS0tLS0t...
    aggregatorCA:
        crt: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0t...
        key: LS0tLS1CRUdJTiBFQyBQUklWQVRFIEtFWS0tLS0t...
    serviceAccount:
        key: LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0t...
    apiServer:
        image: registry.k8s.io/kube-apiserver:v1.36.0
        admissionControl:
            - name: PodSecurity
              configuration:
                  apiVersion: pod-security.admission.config.k8s.io/v1alpha1
                  defaults:
                      audit: restricted
                      audit-version: latest
                      enforce: baseline
                      enforce-version: latest
                      warn: restricted
                      warn-version: latest
                  exemptions:
                      namespaces:
                          - kube-system
                      runtimeClasses: []
                      usernames: []
                  kind: PodSecurityConfiguration
        auditPolicy:
            apiVersion: audit.k8s.io/v1
            kind: Policy
            rules:
                - level: Metadata
    controllerManager:
        image: registry.k8s.io/kube-controller-manager:v1.36.0

    # 2. Disable kube-proxy for pure eBPF routing
    proxy:
        image: registry.k8s.io/kube-proxy:v1.36.0
        disabled: true # <-- Set this to true

    scheduler:
        image: registry.k8s.io/kube-scheduler:v1.36.0
    discovery:
        enabled: true
        registries:
            kubernetes:
                disabled: true
            service: {}
    etcd:
        ca:
            crt: LS0tLS1CRUdJTiBDRJQ0FURS0tLS0t...
            key: LS0tLS1CRUdJTiBFQyRFIEtFWS0tLS0t...

    inlineManifests: []
    allowSchedulingOnControlPlanes: true
---
apiVersion: v1alpha1
kind: HostnameConfig
auto: stable
```

```bash
talosctl apply-config --insecure \
  --nodes 192.168.11.19 \
  --file controlplane.yaml
```

```bash
# 1. Tell talosconfig where the API entrypoint lives
talosctl config endpoint 192.168.11.19 --talosconfig ./talosconfig

# 2. Tell talosconfig which node to target by default
talosctl config node 192.168.11.19 --talosconfig ./talosconfig

talosctl bootstrap --talosconfig ./talosconfig

# if you wish to see the bootstrap live
talosctl dashboard --talosconfig ./talosconfig
```

You may now pull out the usb drive used to install

```bash
talosctl kubeconfig . --talosconfig ./talosconfig
```

```bash
kubectl get nodes
```

```bash
talosctl shutdown --talosconfig ./talosconfig
```
