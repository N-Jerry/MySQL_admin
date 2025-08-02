#!/bin/bash
# restore.sh - Restores MySQL ecommerce_db or specific table from a compressed backup
# Configuration
DB_NAME="ecommerce_db"
LOG_FILE="/var/log/mysql_restore.log"
TEMP_SQL="/tmp/restore_$DB_NAME.sql"
# Logging function
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}
# Check arguments
if [ $# -lt 1 ]; then
  echo "Usage: $0 <backup_file> [table_name]"
  exit 1
fi
BACKUP_FILE="$1"
TABLE_NAME="$2"
# Check if login path exists
mysql_config_editor print --login-path=backup > /dev/null 2>&1
if [ $? -ne 0 ]; then
  log "Login path 'backup' not found. Run: mysql_config_editor set --login-path=backup --host=localhost --user=backup_user --password"
  exit 1
fi
# Validate backup file
if [ ! -f "$BACKUP_FILE" ]; then
  log "Backup file $BACKUP_FILE does not exist"
  exit 1
fi
# Decompress backup
log "Decompressing $BACKUP_FILE to $TEMP_SQL"
gunzip -c "$BACKUP_FILE" > "$TEMP_SQL"
if [ $? -ne 0 ]; then
  log "Failed to decompress $BACKUP_FILE"
  rm -f "$TEMP_SQL"
  exit 1
fi
# Restore database or table
if [ -z "$TABLE_NAME" ]; then
  log "Restoring full database $DB_NAME from $BACKUP_FILE"
  mysql --login-path=backup -e "CREATE DATABASE IF NOT EXISTS $DB_NAME"
  mysql --login-path=backup "$DB_NAME" < "$TEMP_SQL"
else
  log "Restoring table $TABLE_NAME from $BACKUP_FILE"
  mysql --login-path=backup "$DB_NAME" -e "SET FOREIGN_KEY_CHECKS=0; DROP TABLE IF EXISTS $TABLE_NAME;"
  mysql --login-path=backup "$DB_NAME" < "$TEMP_SQL"
  mysql --login-path=backup "$DB_NAME" -e "SET FOREIGN_KEY_CHECKS=1;"
fi

if [ $? -eq 0 ]; then
  log "Restore successful for $DB_NAME (Table: ${TABLE_NAME:-Full DB})"
else
  log "Restore failed for $DB_NAME (Table: ${TABLE_NAME:-Full DB})"
  rm -f "$TEMP_SQL"
  exit 1
fi

# Clean up
rm -f "$TEMP_SQL"
log "Cleaned up temporary file $TEMP_SQL"
