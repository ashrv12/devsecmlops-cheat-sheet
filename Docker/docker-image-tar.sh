# Save an image as a tar
docker save -o <output_filename.tar> <image_name>:<tag>

# copy from server to server via ssh
scp root@<server-ip>:/opt/home/images/keycloak.tar ./

# multiple images save command
docker save -o images_backup.tar my_image:latest alpine:3.14 nginx:latest

# save and compress so you can transport more easily
docker save my_image:latest | gzip > my_image.tar.gz

# exporting a docker container files
# This exports the filesystem of the specified container to <output_filename.tar>
docker export -o <output_filename.tar> <container_name_or_id>

# finally load all the image tars to your new docker engine
docker load -i images_backup.tar

# how to import the export command tar
docker import output.tar my_new_image:latest
