# how to find the container that is causing the suspicious activity
kubectl get pods -A > pods.json

vim pods.json

# /<container_id>
# it will show the full spec from bottom to top usually
