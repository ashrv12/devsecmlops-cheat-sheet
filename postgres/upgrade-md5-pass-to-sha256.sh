
# 1. Enter the DB
docker compose exec postgres psql -U ${POSTGRES_USER}

# 2. Re-set the password (this triggers the new encryption)
ALTER USER your_username WITH PASSWORD 'your_strong_password';
