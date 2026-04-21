#!/bin/bash
# Check backup health

LOG_FILE="/home/babajide/vaultwarden/logs/health_check.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== Backup Health Check ==="

# Check if containers are running
if ! docker ps | grep -q vaultwarden-postgres; then
    log "ERROR: PostgreSQL container not running!"
    exit 1
fi

# Get last backup info
LAST_BACKUP=$(docker exec vaultwarden-postgres pgbackrest info --stanza=vaultwarden --output=json 2>/dev/null | grep -o '"timestamp":{"start":[0-9]*' | tail -1 | grep -o '[0-9]*$')
CURRENT_TIME=$(date +%s)

if [ -n "$LAST_BACKUP" ]; then
    AGE_HOURS=$(( ($CURRENT_TIME - $LAST_BACKUP) / 3600 ))
    log "Last backup age: $AGE_HOURS hours"
    
    if [ $AGE_HOURS -gt 48 ]; then
        log "WARNING: Last backup is older than 48 hours!"
    else
        log "✓ Backup age is OK"
    fi
else
    log "WARNING: No backups found!"
fi

# Check archive status
ARCHIVE_FAILED=$(docker exec vaultwarden-postgres psql -U vaultwarden vaultwarden -t -c "SELECT failed_count FROM pg_stat_archiver;" 2>/dev/null | xargs)
if [ -n "$ARCHIVE_FAILED" ] && [ "$ARCHIVE_FAILED" -gt 0 ]; then
    log "WARNING: $ARCHIVE_FAILED archive failures detected"
else
    log "✓ Archive status OK"
fi

# Get database stats
USER_COUNT=$(docker exec vaultwarden-postgres psql -U vaultwarden vaultwarden -t -c "SELECT COUNT(*) FROM users;" 2>/dev/null | xargs)
log "Current users: $USER_COUNT"

log "Health check completed"
echo ""
