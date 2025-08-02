#!/bin/bash
# backup.sh - Automates MySQL backup for ecommerce_db with compression, logging, and storage check
# Configuration
BACKUP_DIR="/var/backups/mysql"
DB_NAME="ecommerce_db"
LOG_FILE="/var/log/mysql_backup.log"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/$DB_NAME-$DATE.sql.gz"
MIN_DISK_SPACE_MB=100  # Minimum free disk space required (in MB)
# Ensure backup directory exists
mkdir -p "$BACKUP_DIR" || { echo "[$(date '+%Y-%m-%d %H:%M:%S')] Failed to create backup directory" >> "$LOG_FILE"; exit 1; }
# Logging function
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}
# Check if login path exists
mysql_config_editor print --login-path=backup > /dev/null 2>&1
if [ $? -ne 0 ]; then
  log "Login path 'backup' not found. Run: mysql_config_editor set --login-path=backup --host=localhost --user=backup_user --password"
  exit 1
fi
# Check available disk space
AVAILABLE_SPACE=$(df -m "$BACKUP_DIR" | tail -1 | awk '{print $4}')
if [ "$AVAILABLE_SPACE" -lt "$MIN_DISK_SPACE_MB" ]; then
  log "Insufficient disk space: $AVAILABLE_SPACE MB available, $MIN_DISK_SPACE_MB MB required"
  exit 1
fi
log "Disk space check passed: $AVAILABLE_SPACE MB available"
# Perform backup using mysqldump with login path
log "Starting backup for $DB_NAME"
mysqldump --login-path=backup --single-transaction --routines --triggers "$DB_NAME" | gzip > "$BACKUP_FILE"
if [ $? -eq 0 ]; then
  log "Backup successful: $BACKUP_FILE"
else
  log "Backup failed for $DB_NAME"
  exit 1
fi
# Check backup file integrity
if [ -s "$BACKUP_FILE" ]; then
  log "Backup file size: $(ls -lh "$BACKUP_FILE" | awk '{print $5}')"
else
  log "Backup file is empty or missing"
  exit 1
fi
# Retention: Delete backups older than 7 days
find "$BACKUP_DIR" -name "$DB_NAME-*.sql.gz" -mtime +7 -delete
log "Deleted backups older than 7 days"
