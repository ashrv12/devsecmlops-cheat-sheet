# Filter logs to see only the audit entries
docker compose logs -f postgres | grep "AUDIT"

# sample
# 2026-01-15 14:00:01 UTC [123] admin@my_db AUDIT: SESSION,1,1,DDL,CREATE TABLE,,,CREATE TABLE sensitive_data (...),<not logged>