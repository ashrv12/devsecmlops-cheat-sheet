# this command takes the gunzipped base64 input and decrypts it into a normal yaml file
echo "base64 encoded gunzip" | base64 -d | gunzip > prometheus.yaml


# and then we obtain the newly edited config file and zip then encrypt
cat prometheus.yaml | gzip | base64 -w 0

# we are doing this because the secret is always a base64 encrypted data source in k8s
