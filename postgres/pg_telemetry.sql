--- This file is for creating the monitoring user
--- don't give the monitoring user super user access
--- instead there is a built in role in postgres


-- Create the dedicated monitoring user
CREATE USER pg_exporter WITH PASSWORD 'your_secure_password';

-- Grant the modern 'pg_monitor' role (covers stats, counts, and health)
GRANT pg_monitor TO pg_exporter;

-- Required for pg_stat_statements if you want query-level metrics
GRANT SELECT ON pg_stat_statements TO pg_exporter;

