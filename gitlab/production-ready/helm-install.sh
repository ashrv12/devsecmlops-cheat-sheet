helm repo add gitlab https://charts.gitlab.io/

helm repo update gitlab

helm search repo gitlab

kubectl create namespace gitlab

# here is the secret creation sample that we will use with this helm
kubectl create secret generic gitlab-pg-password \
  --from-literal=password=gitlab -n gitlab

# IT IS IMPORTANT THAT WE DOWNLOAD ALL IMAGES BEFORE WE DEPLOY AND SET REDIS AND OTHER
# EXTERNAL PROVIDERS ALL ON
# EVEN THE GITALY
# ALSO REMEMBER TO DISABLE PROMETHEUS

helm install gitlab gitlab/gitlab \
  --set postgresql.install=false \
  --set global.psql.host=pgbouncer-pooler.cnpg-system.svc.cluster.local \
  --set global.psql.database=gitlabhq_production \
  --set global.psql.username=gitlab \
  --set global.psql.password.secret=gitlab-pg-password \
  --set global.psql.password.key=password \
  --set global.hosts.https=false \
  --set certmanager-issuer.email=false \
  --set prometheus.install=false \
  --set global.time_zone="Asia/Ulaanbaatar" \
  --create-namespace -n gitlab

# we use the secret for the password on this one liner global.psql.password.secret=gitlab-pg-password

# after slightly successful deployment we can obtain the password
kubectl get secret gitlab-gitlab-initial-root-password \
  -n gitlab \
  -o jsonpath="{.data.password}" | base64 --decode; echo
