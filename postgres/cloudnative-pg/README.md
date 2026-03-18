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

3. We now need to deploy a postgres cluster with a pg_bouncer pooler instance.

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
```

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

4. After it is deployed, we can obtain the required username passwords from the secrets within the namespace

```bash
kubectl get secrets -n cnpg-system
```

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
> We need only this one

|Name|Type|Data|Age|
|---|---|---|---|
|single-replica-db-app           |kubernetes.io/basic-auth   |11     |11m|
