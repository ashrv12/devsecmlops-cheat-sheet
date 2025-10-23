kubectl create configmap gitlab-cert --from-file=gitlab-ca.crt --namespace=gitlab-runners
kubectl create secret generic gitlab-cert --from-file=gitlab-ca.crt --namespace=gitlab-runners

microk8s helm upgrade --namespace gitlab-runners gitlab-runner -f values.yml gitlab/gitlab-runner
microk8s helm install --namespace gitlab-runners gitlab-runner -f values.yml gitlab/gitlab-runner

values.yml :

name: gitlab-runner
gitlabUrl: https://gitlab.hello.com/
runnerToken: "token"
unregisterRunners: true
checkInterval: 5
rbac:
  create: true
certsSecretName: gitlab-hello-cert
runners:
  config: |
    [[runners]]
      url = "https://gitlab.hello.com/"
      token = "token"
      executor = "docker"
      [runners.kubernetes]
        image = "ubuntu:22.04"
        privileged = true
        tls_verify = false
      [[runners.kubernetes.volumes.secret]]
          name = "gitlab-hello-cert"
          mount_path = "/etc/gitlab-runner/certs/ca.crt"
