openssl s_client -showcerts -connect gitlab.tdbm.mn:443 -servername gitlab.tdbm.mn < /dev/null 2>/dev/null | openssl x509 -outform PEM > gitlab.tdbm.mn.crt

echo | openssl s_client -CAfile gitlab.tdbm.mn.crt -connect gitlab.tdbm.mn:443 -servername gitlab.tdbm.mn

kubectl create secret generic <SECRET_NAME> --namespace <NAMESPACE> --from-file=<CERT_FILE>