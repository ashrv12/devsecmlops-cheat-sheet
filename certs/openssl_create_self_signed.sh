# Command for creating a self signed certificate for a specific domain for TLS
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -out dashboard.crt -keyout dashboard.key \
  -subj "/CN=kubernetes-dashboard.127.0.0.1.nip.io"

# command for creating the secret tls for the certain application
kubectl create secret tls dashboard-tls-secret \
  --cert=dashboard.crt \
  --key=dashboard.key \
  -n <namespace>

