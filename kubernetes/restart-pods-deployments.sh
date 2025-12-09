# restart rollout without ns
kubectl rollout restart deployment/my-app

#restart rollout with specific ns
kubectl rollout restart deployment/my-app -n your-namespace

# check the restart rollout status
kubectl rollout status deployment/my-app
