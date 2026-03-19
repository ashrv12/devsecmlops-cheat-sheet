# How to deploy Cloud native PG in a production environment via helm

1. Add the helm repository.

```bash
helm repo add cnpg https://cloudnative-pg.github.io/charts
```

2. We then opt in for a single namespace deployment.

```bash
helm upgrade --install cnpg \
  --namespace cnpg-system \
  --create-namespace \
  --set config.clusterWide=false \
  cnpg/cloudnative-pg
```
> [!Note]
> Now we will have a Cloud native pg operator brain as a deployment. 

3. We need to create a user for keycloak and onedev

```bash
kubectl create secret generic keycloak-test-user \
  --from-literal=username=keycloak_test \
  --from-literal=password=keycloak_test -n cnpg-system

kubectl create secret generic onedev-test-user \
  --from-literal=username=onedev_test \
  --from-literal=password=onedev_test -n cnpg-system
```

4. We then create the database cluster after creating both users

```yaml
# the cluster pg-cluster.yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: single-replica-db
  namespace: cnpg-system
spec:
  instances: 1
  storage:
    size: 1Gi
  managed:
    roles:
      - name: keycloak_test
        ensure: present
        login: true
        passwordSecret:
          name: keycloak-user-password
      - name: onedev-test
        ensure: present
        login: true
        passwordSecret:
          name: onedev-test
```

5. Then we create the pg bouncer pooler for connections

```yaml
# the pooler pg-bouncer-pooler.yaml

apiVersion: postgresql.cnpg.io/v1
kind: Pooler
metadata:
  name: pgbouncer-pooler
  namespace: cnpg-system
spec:
  cluster:
    name: single-replica-db
  instances: 1
  type: rw # Connects to the read-write (primary) instance
  pgbouncer:
    poolMode: transaction # common modes are session, transaction, statement
    # You can add custom pgbouncer settings here
    parameters:
      max_client_conn: "1000"
      default_pool_size: "20"
```

6. After it is deployed, we can obtain the required super user from the secrets within the namespace

```bash
kubectl get secrets -n cnpg-system
```

> [!Note]
> Sample table from running the command

|Name|Type|Data|Age|
|---|---|---|---|
|cnpg-ca-secret                  |Opaque                     |2      |28m|
|cnpg-webhook-cert               |kubernetes.io/tls          |2      |28m|
|sh.helm.release.v1.cnpg.v1      |helm.sh/release.v1         |1      |28m|
|single-replica-db-app           |kubernetes.io/basic-auth   |11     |11m|
|single-replica-db-ca            |Opaque                     |2      |11m|
|single-replica-db-pooler        |kubernetes.io/tls          |2      |11m|
|single-replica-db-replication   |kubernetes.io/tls          |2      |11m|
|single-replica-db-server        |kubernetes.io/tls          |2      |11m|



> [!Note]
> We need only this one as this is the super user

|Name|Type|Data|Age|
|---|---|---|---|
|single-replica-db-app           |kubernetes.io/basic-auth   |11     |11m|

7. Apply the Database CRDS for keycloak and onedev

```bash
# ./dbs/keycloak-db.yaml
kubectl apply -f keycloak-db.yaml -n cnpg-system

# ./dbs/onedev-db.yaml
kubectl apply -f onedev-db.yaml -n cnpg-system
```

### We have successfully deployed a mock cluster with 2 DBs for keycloak and onedev in the test environment

# Part 2: How to deploy and create databases on the PG Native cluster the Kubernetes NATIVE way

> [!Note]
> Example used is KEYCLOAK test db creation

1. Create the keycloak test user password for the db as a K8's secret

```bash
# ./users/secret.sh
kubectl create secret generic keycloak-test-user \
  --from-literal=username=keycloak_test \
  --from-literal=password=keycloak_test
```

2. Create the role for the user in the cluster

```yaml
# ./roles/keycloak-test-role.yaml
apiVersion: postgresql.cnpg.io/v1
kind: Role
metadata:
  name: keycloak-test-role
spec:
  cluster:
    name: single-replica-db  # Ensure this matches your Cluster name from 'kubectl get cluster'
  name: keycloak_test
  login: true
  passwordSecret:
    name: keycloak-test-user
```

3. Finally create the db as a Database resource

```yaml
# ./dbs/keycloak-db.yaml
apiVersion: postgresql.cnpg.io/v1
kind: Database
metadata:
  name: keycloak-test-db
spec:
  name: keycloak_test
  owner: keycloak_test
  cluster:
    name: single-replica-db
```

4. Apply the files to the cluster

```bash
kubectl apply -f ./keycloak-test-role.yaml -n cnpg-system

kubectl apply -f ./keycloak-db.yaml -n cnpg-system
```


