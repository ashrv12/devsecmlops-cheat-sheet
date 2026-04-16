# 1. Generate your server's private key
openssl genrsa -out tls.key 2048

# Why?: We use a 2048-bit RSA key for tls.key
# It provides a great balance of strong security and fast TLS handshake performance,
# which is critical when dealing with high-throughput API traffic.

# 2. Create the CSR for example.xyz
openssl req -new -key tls.key -out example.csr -subj "/C=MN/O=Example XYZ/CN=example.xyz"

# FYI: Modern clients (especially Flutter/Dart and browsers) will reject a certificate if the domain is only in the Common Name (CN).
# It must exist as a Subject Alternative Name (SAN).

# Sign the Leaf Certificate (tls.crt)

# 1. Create the SAN extension file
echo "subjectAltName=DNS:example.xyz,DNS:www.example.xyz" > domain_ext.cnf

# 2. Sign the server CSR with the Intermediate CA
openssl x509 -req -in example.csr -CA intermediate.crt -CAkey intermediate.key -CAcreateserial -out tls.crt -days 365 -sha256 -extfile domain_ext.cnf

# Why?: We are injecting the SANs via domain_ext.cnf. This tls.crt is now your official leaf certificate, cryptographically tied back to your local root.