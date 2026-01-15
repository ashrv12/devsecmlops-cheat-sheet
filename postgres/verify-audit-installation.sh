# VERIFICATION SHELL

docker compose exec postgres psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "SELECT * FROM pg_available_extensions WHERE name = 'pgaudit';"