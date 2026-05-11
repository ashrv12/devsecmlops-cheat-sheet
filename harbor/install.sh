# add the repo
helm repo add harbor https://helm.goharbor.io

# install a release with a custom name
helm install my-release harbor/harbor

# uninstall that release
helm uninstall my-release