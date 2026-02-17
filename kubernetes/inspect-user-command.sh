# install skopeo first, then you can inspect the image's user, MAKE SURE IT IS NOT ROOT
skopeo inspect docker://<image-name> | grep -i "User"

# if the image is already pulled onto the host machine and you happen to have either docker
# or podman you can inspect the image user like so
# <This is especially useful if you want to pull the image locally first, inspect it and then deploy it on the cluster>
docker inspect <image-name> --format='{{.Config.User}}'
