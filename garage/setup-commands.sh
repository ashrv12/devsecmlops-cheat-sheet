# after deploying the helm chart run this command in garage-0
oc exec -it garage-0 -- /garage status

# then we can assign our pvc capacity to our node instance

# Defaulted container "garage" out of: garage, garage-init (init)
# 2026-03-10T23:56:54.239525Z  INFO garage_net::netapp: Connected to 127.0.0.1:3901, negotiating handshake...
# 2026-03-10T23:56:54.281091Z  INFO garage_net::netapp: Connection established to 7246c30da15ef692
# ==== HEALTHY NODES ====
# ID                Hostname  Address            Tags  Zone  Capacity          DataAvail  Version
# 7246c30da15ef692  garage-0  10.128.1.189:3901              NO ROLE ASSIGNED             v2.2.0

oc exec -it garage-0 -- /garage layout assign 7246c30da15ef692 --capacity 150G --zone default

# after assigning a layout we can apply it so it starts using that layout
oc exec -it garage-0 -- /garage layout apply --version 1

# Create a new key specifically for Tempo
oc exec -it garage-0 -- /garage key create tempo-key

# Defaulted container "garage" out of: garage, garage-init (init)
# 2026-03-11T00:35:43.811426Z  INFO garage_net::netapp: Connected to 127.0.0.1:3901, negotiating handshake...
# 2026-03-11T00:35:43.853092Z  INFO garage_net::netapp: Connection established to 74fafd3d79087d5a
# ==== ACCESS KEY INFORMATION ====
# Key ID:              GK66990c6e8e4dab1ca8aa4fc2
# Key name:            tempo-key
# Secret key:          c39269a867c4a3143a663e17e8c03e48ca84c817fcab106be5751775fac3757f
# Created:             2026-03-11 00:35:43.853 +00:00
# Validity:            valid
# Expiration:          never
#
# Can create buckets:  false
#
# ==== BUCKETS FOR THIS KEY ====
# Permissions  ID  Global aliases  Local aliases

# 1. Create the bucket
oc exec -it garage-0 -- /garage bucket create tempo-traces

# 2. Assign the key to the bucket with full permissions
oc exec -it garage-0 -- /garage bucket allow tempo-traces --read --write --key tempo-key

# Defaulted container "garage" out of: garage, garage-init (init)
# 2026-03-11T00:36:40.944377Z  INFO garage_net::netapp: Connected to 127.0.0.1:3901, negotiating handshake...
# 2026-03-11T00:36:40.987092Z  INFO garage_net::netapp: Connection established to 74fafd3d79087d5a
# ==== BUCKET INFORMATION ====
# Bucket:          8071ac70f40529691406f6d24afa271cfd8d9b1405f0e7dc7f39d0f3a62cc4e6
# Created:         2026-03-11 00:36:24.195 +00:00
#
# Size:            0 B (0 B)
# Objects:         0
#
# Website access:  false
#
# Global alias:    tempo-traces
#
# ==== KEYS FOR THIS BUCKET ====
# Permissions  Access key                             Local aliases
# RW           GK66990c6e8e4dab1ca8aa4fc2  tempo-key


