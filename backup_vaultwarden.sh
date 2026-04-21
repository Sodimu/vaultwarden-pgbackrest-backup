#!/bin/bash
# Production backup script for Vaultwarden
# This uses pgBackRest which is already configured
# The --type=full backup uses PostgreSQL's native backup API
# This ensures consistency without stopping the database
# WAL archiving ensures point-in-time recovery

LOG_DIR="/home/babajide/vaultwarden/logs"
LOG_FILE="${LOG_DIR}/backup_$(date +%Y%m%d).log"
BACKUP_DIR="/home/babajide/vaultwarden/backups"

# Create directories if they don't exist
mkdir -p "$LOG_DIR"
mkdir -p "$BACKUP_DIR"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "========== Starting Vaultwarden Backup =========="

# Check if containers are running
if ! docker ps | grep -q vaultwarden-postgres; then
    log "ERROR: PostgreSQL container is not running!"
    exit 1
fi

# Get user count before backup (for verification)
USER_COUNT=$(docker exec vaultwarden-postgres psql -U vaultwarden vaultwarden -t -c "SELECT COUNT(*) FROM users;" 2>/dev/null | xargs)
CIPHER_COUNT=$(docker exec vaultwarden-postgres psql -U vaultwarden vaultwarden -t -c "SELECT COUNT(*) FROM ciphers;" 2>/dev/null | xargs)

log "Current database stats - Users: $USER_COUNT, Ciphers: $CIPHER_COUNT"

# Run full backup
log "Starting pgBackRest full backup..."
BACKUP_OUTPUT=$(docker exec vaultwarden-postgres pgbackrest --stanza=vaultwarden --type=full backup 2>&1)
BACKUP_EXIT=$?

if [ $BACKUP_EXIT -eq 0 ]; then
    # Extract backup label from output
    BACKUP_LABEL=$(echo "$BACKUP_OUTPUT" | grep "new backup label" | awk '{print $NF}')
    log "✓ Backup completed successfully - Label: $BACKUP_LABEL"
    
    # Get backup size
    BACKUP_SIZE=$(docker exec vaultwarden-postgres pgbackrest info --stanza=vaultwarden --output=json 2>/dev/null | grep -o '"size":[0-9]*' | tail -1 | grep -o '[0-9]*')
    if [ -n "$BACKUP_SIZE" ]; then
        BACKUP_SIZE_MB=$((BACKUP_SIZE / 1024 / 1024))
        log "Backup size: ${BACKUP_SIZE_MB}MB"
    fi
    
    # Expire old backups (keep last 2)
    log "Expiring old backups..."
    docker exec vaultwarden-postgres pgbackrest --stanza=vaultwarden expire >> "$LOG_FILE" 2>&1
    
    # Export repository metadata for disaster recovery
    docker exec vaultwarden-postgres pgbackrest info --stanza=vaultwarden > "${BACKUP_DIR}/backup_info_$(date +%Y%m%d).txt" 2>&1
    
    log "✓ Backup process completed successfully"
else
    log "✗ BACKUP FAILED with exit code: $BACKUP_EXIT"
    log "Error output: $BACKUP_OUTPUT"
    exit 1
fi

log "========== Backup Finished =========="
echo "" >> "$LOG_FILE"

# Clean up old files (older than 30 days)
find "$LOG_DIR" -name "backup_*.log" -mtime +30 -delete 2>/dev/null
find "$BACKUP_DIR" -name "backup_info_*.txt" -mtime +30 -delete 2>/dev/null
