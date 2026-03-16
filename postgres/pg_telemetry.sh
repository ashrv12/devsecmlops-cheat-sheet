# When deploying the pg_exporter remember to link the db link
# to the postgres using the monitoring role and user

export DATA_SOURCE_NAME="postgresql://pg_exporter:your_secure_password@<NODE_IP>:5432/postgres?sslmode=disable"
./postgres_exporter