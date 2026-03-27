GET /_cat/indices?v

GET /_cat/indices?v&s=pri.store.size:desc&h=index,pri.store.size,docs.count


PUT /_snapshot/pvc_backup
{
  "type": "fs",
  "settings": {
    "location": "/usr/share/elasticsearch/backup"
  }
}

PUT /_snapshot/pvc_backup/test_backup_01?wait_for_completion=true
{
  "indices": "m-bi-main-service-2025.12 ",
  "ignore_unavailable": true,
  "include_global_state": false
}


GET /_snapshot/pvc_backup/test_backup_01/_status

DELETE /_snapshot/pvc_backup/test_backup_01

POST /_snapshot/pvc_backup/test_backup_01/_restore
{
  "indices": "m-retail-integration-cam-service-2026.03",
  "rename_pattern": "(.+)",
  "rename_replacement": "restored_$1"
}