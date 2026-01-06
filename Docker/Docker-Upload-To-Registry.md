```bash

oc create secret docker-registry registry --docker-server=securereg.registry.com:5000 --docker-username=roo0t --docker-password=Passw0rd

# this is for logging into the registry for images
docker login custom-registry.com:5000 -u admin -p password

# piping strategy for better security practices on logging in via cli
echo "password" | docker login custom-registry.com:5000 -u admin --password-stdin

# this is for tagging a specific image you built locally
docker tag test:latest custom-registry.com:5000/bun-nextjs-frontend:latest || exit 1

# test:latest --> custom-registry.com:5000/bun-nextjs-frontend:latest

# this pushes said image to the registry if it is open or requires login if it authed
docker push custom-registry.com:5000/bun-nextjs-frontend:latest || exit 1

# lastly we can cleanup the image since we uploaded it to the registry
docker rmi custom-registry.com:5000/bun-nextjs-frontend:latest || exit 1

# or operator || and exit 1 says if the condition is 0 then exit as 1 and stops the entire process
[some shell command] || [exit 1]

```
