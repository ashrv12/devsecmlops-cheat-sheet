# creating a secret without specifying the namespace since the oc cli tool has to have a project selected to apply manifest files
oc create secret docker-registry registry --docker-server=secureregistry.com:5000 --docker-username=admin --docker-password=123

