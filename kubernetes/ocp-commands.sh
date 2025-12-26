# creating a secret without specifying the namespace since the oc cli tool has to have a project selected to apply manifest files
oc create secret docker-registry registry --docker-server=secureregistry.com:5000 --docker-username=admin --docker-password=123

# making the web service-account have anyuid admin permissions for read write access to files and mounts (chmod  chown)
oc adm policy add-scc-to-user anyuid -z web -n pre-web
