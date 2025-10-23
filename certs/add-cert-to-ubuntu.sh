
# certificate extraction
openssl s_client -showcerts -connect gitlab.hello.com:443 -servername gitlab.hello.com < /dev/null 2>/dev/null | openssl x509 -outform PEM > gitlab.hello.com.crt

# This command does the following:

# openssl s_client - Establishes an SSL/TLS connection to a server
# -showcerts - Displays the entire certificate chain from the server
# -connect gitlab.hello.com:443 - Connects to the specified host on port 443 (HTTPS)
# -servername gitlab.hello.com - Sets the Server Name Indication (SNI) for servers hosting multiple SSL certificates
# < /dev/null - Provides empty input to prevent the command from waiting for user input
# 2>/dev/null - Redirects error messages to null (suppresses error output)
# | openssl x509 -outform PEM - Pipes the output to extract and format the certificate in PEM format
# > gitlab.hello.com.crt - Saves the certificate to a file named gitlab.hello.com.crt

# Certificate Verification
echo | openssl s_client -CAfile gitlab.hello.com.crt -connect gitlab.hello.com:443 -servername gitlab.hello.com

# This command verifies the connection using the previously downloaded certificate:
# echo | - Provides empty input to the command
# openssl s_client - Again establishes an SSL/TLS connection
# -CAfile gitlab.hello.com.crt - Uses the downloaded certificate file as a trusted Certificate Authority
# -connect gitlab.hello.com:443 -servername gitlab.hello.com - Same connection parameters as before

# How to set certificate to ubuntu local trusted certificates

# Copy the certificate to the system's trusted certificate directory
sudo cp gitlab.hello.com.crt /usr/local/share/ca-certificates/

# Update the system's certificate store
sudo update-ca-certificates

# Verify the certificate has been added to the trusted store
echo "Certificate installation complete. Verifying..."
openssl verify -CApath /etc/ssl/certs gitlab.hello.com.crt

# Alternative verification: Check if the certificate is in the bundle
grep -l "gitlab.hello.com" /etc/ssl/certs/ca-certificates.crt && echo "Certificate found in system bundle" || echo "Certificate not found in system bundle"
