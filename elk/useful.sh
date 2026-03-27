# get the elastic user password
kubectl get secret elasticsearch-sample-es-elastic-user -o jsonpath='{.data.elastic}' | base64 -d

# get all indices
curl -k -u elastic:password -X GET "https://localhost:9200/_cat/indices?v"

# register the new backup path
curl -k -u elastic:password -X PUT "https://localhost:9200/_snapshot/pvc_backup" -H 'Content-Type: application/json' -d'
> {
>   "type": "fs",
>   "settings": {
>     "location": "/usr/share/elasticsearch/backup"
>   }
> }'

# RESPONSE
# {"acknowledged":true}

# Save the selected indices as test_backup_01 like a tar file at the previously registered fs file path pvc_backup
curl -k -u elastic:password -X PUT "https://localhost:9200/_snapshot/pvc_backup/test_backup_01?wait_for_completion=true" -H 'Content-Type: application/json' -d'
{
  "indices": "retail-integration-cam-service-2026.03",
  "ignore_unavailable": true,
  "include_global_state": false
}'

# restores the elk index, remember to specify test_backup_01 or the name of the backup, remember to add the previously registered fs file path
curl -k -u elastic:password -X POST /_snapshot/pvc_backup/test_backup_01/_restore
{
  "indices": "retail-integration-cam-service-2026.03",
  "rename_pattern": "(.+)",
  "rename_replacement": "restored_$1"
}

# spec:
#   nodeSets:
#   - name: default
#     count: 1
#     config:
#       # This enables the snapshot feature for this path
#       path.repo: ["/usr/share/elasticsearch/backup"]
#     podTemplate:
#       spec:
#         containers:
#         - name: elasticsearch
#           volumeMounts:
#           - name: elastic-backup-volume
#             mountPath: /usr/share/elasticsearch/backup
#         volumes:
#         - name: elastic-backup-volume
#           persistentVolumeClaim:
#             # REPLACE THIS with the actual name of your existing PVC
#             claimName: your-existing-pvc-name

