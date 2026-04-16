# Prepare NGINX (The Reverse Proxy)

# Concatenate the leaf and the intermediate into a single file
cat tls.crt intermediate.crt > fullchain.crt

# Convert the standard RSA key to PKCS#8
openssl pkcs8 -topk8 -inform PEM -outform PEM -nocrypt -in tls.key -out pkcs8.key

# Why: The -nocrypt flag means the key isn't password-protected on the disk,
# allowing your Spring Boot microservice to start up automatically without manual password entry.

# TSA: Java's internal cryptography libraries strictly expect private keys to be in the PKCS#8 format when read directly from the filesystem.
# The default OpenSSL output (PKCS#1) will cause Spring Boot to throw parsing exceptions.


# Create the Java/Flutter Keystore (keystore.p12)

openssl pkcs12 -export -out keystore.p12 -inkey tls.key -in tls.crt -certfile intermediate.crt -name "example.xyz"
# Enter Export Password: <input>
# Verifying - Enter Export Password: <input>

# Why?: This bundles the entire chain of trust and the private key into a single,
# password-protected binary payload.


# Prepare the Mobile Client Pinning (pinning.crt)

# Option A: Provide the raw certificate for pinning
cp tls.crt pinning.crt

# Option B: (Often preferred for mobile) Extract just the Public Key 
openssl x509 -in tls.crt -pubkey -noout > pinning_pub.key

# Why?: Pinning the leaf certificate (tls.crt) is the most secure but most brittle method.
# When this certificate expires in 365 days, your Flutter app will break unless you push an app update. When you move to DigiCert,
# consider pinning the intermediate.crt instead. DigiCert intermediates last for years,
# allowing you to rotate your tls.crt automatically without breaking your mobile clients.

# end -> go to verification.sh