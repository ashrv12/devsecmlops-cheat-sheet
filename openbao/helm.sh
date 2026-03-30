helm repo add openbao https://openbao.github.io/openbao-helm

helm search repo openbao/openbao

# NAME            CHART VERSION   APP VERSION             DESCRIPTION
# openbao/openbao 0.4.0           v2.0.0-alpha20240329    Official OpenBao Chart

helm install --dry-run openbao openbao/openbao

# https://openbao.org/docs/platform/k8s/helm/run/

oc port-forward openbao-0 8200:8200
# Forwarding from 127.0.0.1:8200 -> 8200
# Forwarding from [::1]:8200 -> 8200
##...

oc exec -ti openbao-0 -- bao operator init
# Unseal Key 1: MBFSDepD9E6whREc6Dj+k3pMaKJ6cCnCUWcySJQymObb
# Unseal Key 2: zQj4v22k9ixegS+94HJwmIaWLBL3nZHe1i+b/wHz25fr
# Unseal Key 3: 7dbPPeeGGW3SmeBFFo04peCKkXFuuyKc8b2DuntA4VU5
# Unseal Key 4: tLt+ME7Z7hYUATfWnuQdfCEgnKA2L173dptAwfmenCdf
# Unseal Key 5: vYt9bxLr0+OzJ8m7c7cNMFj7nvdLljj0xWRbpLezFAI9

# Initial Root Token: s.zJNwZlRrqISjyBHFMiEca6GF
##...

## Unseal the first openbao server until it reaches the key threshold
oc exec -ti openbao-0 -- bao operator unseal # ... Unseal Key 1
oc exec -ti openbao-0 -- bao operator unseal # ... Unseal Key 2
oc exec -ti openbao-0 -- bao operator unseal # ... Unseal Key 3

# Repeat the unseal process for all OpenBao server pods. When all OpenBao server pods are unsealed they report READY 1/1.

oc get pods -l app.kubernetes.io/name=openbao
# NAME                                    READY   STATUS    RESTARTS   AGE
# openbao-0                                 1/1     Running   0          1m49s
# openbao-1                                 1/1     Running   0          1m49s
# openbao-2                                 1/1     Running   0          1m49s