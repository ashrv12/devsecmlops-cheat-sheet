
# first run
docker compose exec postgres_backup /backup.sh

# second
# Check your ./backups folder; you should see a new .sql.gz file.

# ---------------------------

# example situation on how to utilize your backup files that was being saved daily to backup a corrupted postgres instance
# If your database is corrupted and you need to restore from last night's file (e.g., backup_2023.01.01.sql.gz):

# WARNING, this will overwrite the current data in the postgres instance
# 1. Stop the application accessing the DB to prevent write conflicts
docker compose stop postgres

# 2. Unzip the backup and pipe it directly into the database container
gunzip < ./backups/last_night_backup.sql.gz | docker compose exec -T postgres psql -U admin_user -d my_production_db

# 3. Restart your app
docker compose start postgres

# ---------------------------

# If you want to store your backups offsite using aws s3 (REQUIRES CLI AWS COMMAND LOGGED IN)
# Add to host crontab (crontab -e)
# Syncs your local backup folder to S3 every hour
0 * * * * aws s3 sync /path/to/your/project/backups s3://my-company-db-backups/ --delete