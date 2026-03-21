helm repo add onedev https://code.onedev.io/onedev/~helm
helm repo update onedev

# deployment
helm upgrade --install onedev onedev/onedev -n onedev --create-namespace -f values.yaml

# hacky strats for when you cant find stuff in the values.yml
kubectl patch sts onedev -n onedev --type='json' -p='[{"op": "add", "path": "/spec/template/spec/hostAliases", "value": [{"ip": "10.96.251.136", "hostnames": ["keycloak.local"]}]}]'