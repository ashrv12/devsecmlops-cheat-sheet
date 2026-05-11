# Add the jetstack repo if you haven't already
helm repo add jetstack https://charts.jetstack.io
helm repo update

# install cert manager
helm install \
  cert-manager oci://quay.io/jetstack/charts/cert-manager \
  --version v1.20.2 \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true \
  --set "extraArgs={--feature-gates=GatewayAPI=true}"
  