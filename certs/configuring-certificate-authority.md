#### Step 1 - Creating a private key for Certificate Authority:
```sh
mkdir /root/certificates
```
```sh
cd /root/certificates
```

#### Step 2 -  Creating Private Key and CSR:
```sh
openssl genrsa -out ca.key 2048
```

```sh
openssl req -new -key ca.key -subj "/CN=KUBERNETES-CA" -out ca.csr
```
#### Step 3 - Self-Sign the CSR:
```sh
openssl x509 -req -in ca.csr -signkey ca.key -out ca.crt -days 1000
```
#### Step 4 - Remove the CSR
```sh
rm -f ca.csr
```
#### Step 5 - Check Contents of Certificate
```sh
openssl x509 -in ca.crt -text -noout
```

## Generate the user pub priv key pair using the Certificate Authority

#### Step 1 - Generate Client CSR and Client Key:
```sh
cd /root/certificates
```
```sh
openssl genrsa -out rev.key 2048

openssl req -new -key rev.key -subj "/CN=REVERIX" -out rev.csr
```
#### Step 2 - Sign the Client CSR with Certificate Authority
```sh
openssl x509 -req -in rev.csr -CA ca.crt -CAkey ca.key -out rev.crt -days 1000
```
#### Step 3 - Verify Client Certificate
```sh
openssl x509 -in rev.crt -text -noout

openssl verify -CAfile ca.crt rev.crt
```

#### Step 4 - Delete the Client Certificate and Key
```sh
rm -f rev.crt rev.key rev.csr
```
