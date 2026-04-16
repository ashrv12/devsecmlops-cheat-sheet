# Does the key match the cert?
openssl x509 -noout -modulus -in tls.crt | openssl md5
# MD5(stdin)= df1af87946514bd65cf31469f8456ff9 <- should match

openssl rsa -noout -modulus -in tls.key | openssl md5
# MD5(stdin)= df1af87946514bd65cf31469f8456ff9 <- should match

# Does the trust chain resolve?

# Test if the intermediate successfully validates the leaf
openssl verify -CAfile intermediate.crt tls.crt
# C=MN, O=Local Intermediate CA, CN=Local Intermediate CA
# error 2 at 1 depth lookup: unable to get issuer certificate
# error tls.crt: verification failed
# this failed

openssl x509 -in tls.crt -text -noout | grep "Subject Alternative Name" -A 1
# X509v3 Subject Alternative Name: 
#                 DNS:example.xyz, DNS:www.example.xyz
