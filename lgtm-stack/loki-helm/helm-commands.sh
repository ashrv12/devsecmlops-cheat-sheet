# to deploy loki with helm first you need to install
helm install loki grafana/loki -f values.yaml

# to upgrade the loki instance after a config change
helm upgrade loki grafana/loki -f values.yaml
