# how to get a wildcard cert

curl -X POST https://auth.acme-dns.io/register
# Important: It will return a JSON object containing username, password, fulldomain, and subdomain. Save these.

# Step B: Create the CNAME Record
# Go to your "hard to automate" DNS provider's dashboard and create one manual record:

# Type: CNAME
# Name: _acme-challenge.yourdomain.com
# Value: [the "fulldomain" value from the JSON].auth.acme-dns.io.

# Step C: Store credentials in K8s
# Create a secret with the JSON output you received:
kubectl create secret generic acme-dns-secret \
  --namespace cert-manager \
  --from-literal=acmedns-json='{"yourdomain.com": {"username":"...","password":"...","fulldomain":"...","subdomain":"...","allowfrom":[]}}'

# Create the Dual-Solver ClusterIssuer
kubectl apply -f dual-issuer-cluster-issuer.yml
kubectl apply -f dual-issuer-gateway.yml

# 4. How it automates updates
# For example.com (HTTP-01):
# Cert-manager detects the need for a certificate.
# It creates a temporary HTTPRoute on your Envoy Gateway.
# Let's Encrypt hits http://example.com/.well-known/acme-challenge/....
# Envoy routes that to cert-manager; the cert is issued.
# For *.yourdomain.com (DNS-01 via acme-dns):
# Cert-manager calls the auth.acme-dns.io API.
# Let's Encrypt queries _acme-challenge.yourdomain.com.
# Your DNS provider redirects (via the CNAME you set once) to acme-dns.
# The challenge passes; the cert is issued.

# Checking the status

# Check existing certificates
kubectl get certificate -n envoy-gateway-system

# If one is stuck, check the challenge
kubectl get challenges -n envoy-gateway-system
