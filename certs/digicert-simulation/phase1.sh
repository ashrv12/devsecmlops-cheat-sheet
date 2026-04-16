# 1. Generate the Root Private Key
openssl genrsa -out root.key 4096

# 2. Generate the Root Certificate (Self-signed)
openssl req -x509 -new -nodes -key root.key -sha256 -days 3650 -out root.crt -subj "/C=MN/O=Local Root CA/CN=Local Root CA"

# Why?:
# root.key is the master cryptographic secret. The root.crt is self-signed (using -x509).
# In a real environment, this root cert would be pre-installed in your device's operating system.


# Creating the intermediate certificate aka intermediate.crt

# 1. Generate the Intermediate Private Key
openssl genrsa -out intermediate.key 4096

# 2. Create a Certificate Signing Request (CSR) for the Intermediate
openssl req -new -key intermediate.key -out intermediate.csr -subj "/C=MN/O=Local Intermediate CA/CN=Local Intermediate CA"

# 3. Create a config file to define this as a CA
echo "basicConstraints=critical,CA:TRUE" > intermediate_ext.cnf

# Why?: We explicitly define CA:TRUE in the extension file.
# If we skip this, mobile SDKs and strict TLS clients will reject the chain because the intermediate doesn't have the cryptographic authority to sign other certificates.

# 4. Sign the Intermediate with the Root CA
openssl x509 -req -in intermediate.csr -CA root.crt -CAkey root.key -CAcreateserial -out intermediate.crt -days 1825 -sha256 -extfile intermediate_ext.cnf
# Certificate request self-signature ok
# subject=C=MN, O=Local Intermediate CA, CN=Local Intermediate CA




