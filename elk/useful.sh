kubectl get secret elasticsearch-sample-es-elastic-user -o jsonpath='{.data.elastic}' | base64 -d


curl -k -u elastic:password -X PUT "https://localhost:9200/_snapshot/pvc_backup" -H 'Content-Type: application/json' -d'
> {
>   "type": "fs",
>   "settings": {
>     "location": "/usr/share/elasticsearch/backup"
>   }
> }'
{"acknowledged":true}

curl -k -u elastic:3jTTiywu1D0xqmBg2PclS2ok -X PUT "https://localhost:9200/_snapshot/pvc_backup/test_backup_01?wait_for_completion=true" -H 'Content-Type: application/json' -d'
{
  "indices": "index_1,index_2",
  "ignore_unavailable": true,
  "include_global_state": false
}'