# this is how to deploy gitlab agent to your local kubernetes cluster using a selfsigned certificate file for tls

microk8s helm repo add gitlab https://charts.gitlab.io
microk8s helm repo update
microk8s helm upgrade --install k8s-agent-hx101 gitlab/gitlab-agent \
    --namespace gitlab-agent-k8s-agent-hx101 \
    -f agent.yaml \
    --set-file config.kasCaCert=gitlab-ca.crt