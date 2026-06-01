## Installing Cilium using the Helm Repo

Install the cilium cli + hubble cli
(i am on mac)

```bash
brew install cilium-cli
brew install hubble
```

```bash
helm repo add cilium https://helm.cilium.io

helm repo update

kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.5.0/experimental-install.yaml

helm install cilium cilium/cilium \
    --namespace kube-system \
    --atomic \
    -f <choose-values>.yaml
```

## running single node so we remove the taint

```bash
kubectl taint nodes talos node-role.kubernetes.io/control-plane:NoSchedule-
```
