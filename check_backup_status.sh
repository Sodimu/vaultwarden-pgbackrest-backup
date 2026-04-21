#!/bin/bash
# Check backup status for Vaultwarden

echo "========================================="
echo "   Vaultwarden Backup Status Report"
echo "========================================="
echo ""

# Show current database stats
echo "📊 CURRENT DATABASE STATS:"
echo "------------------------"
docker exec vaultwarden-postgres psql -U vaultwarden vaultwarden -c "SELECT COUNT(*) as users FROM users;"
docker exec vaultwarden-postgres psql -U vaultwarden vaultwarden -c "SELECT COUNT(*) as ciphers FROM ciphers;"
docker exec vaultwarden-postgres psql -U vaultwarden vaultwarden -c "SELECT COUNT(*) as organizations FROM organizations;"
echo ""

# Show backup information
echo "💾 BACKUP INFORMATION:"
echo "--------------------"
docker exec vaultwarden-postgres pgbackrest info --stanza=vaultwarden
echo ""

# Show most recent backup log
echo "📋 MOST RECENT BACKUP LOG:"
echo "------------------------"
LAST_LOG=$(ls -t logs/backup_*.log 2>/dev/null | head -1)
if [ -n "$LAST_LOG" ]; then
    echo "Log file: $LAST_LOG"
    echo "Last backup run:"
    tail -5 "$LAST_LOG"
else
    echo "No backup logs found in logs/ directory"
fi
echo ""

# Check archive status
echo "📦 WAL ARCHIVE STATUS:"
echo "--------------------"
docker exec vaultwarden-postgres psql -U vaultwarden vaultwarden -c "SELECT archived_count, failed_count FROM pg_stat_archiver;"
echo ""

# Check disk usage of backup repository
echo "💿 BACKUP REPOSITORY SIZE:"
echo "------------------------"
docker run --rm -v vaultwarden_pgbackrest_repo:/repo alpine du -sh /repo 2>/dev/null
echo ""

# Check when next backup is scheduled
echo "⏰ NEXT SCHEDULED BACKUP:"
echo "-----------------------"
NEXT_BACKUP=$(crontab -l 2>/dev/null | grep "backup_vaultwarden.sh" | grep -v "^#" | head -1)
if [ -n "$NEXT_BACKUP" ]; then
    echo "Cron schedule: $NEXT_BACKUP"
    echo "Next run: Daily at 2:00 AM"
else
    echo "No automatic backup schedule found in crontab"
fi
echo ""

# Health check summary
echo "✅ HEALTH CHECK SUMMARY:"
echo "----------------------"
if docker ps | grep -q vaultwarden-postgres; then
    echo "✓ PostgreSQL container: RUNNING"
else
    echo "✗ PostgreSQL container: STOPPED"
fi

if docker ps | grep -q vaultwarden; then
    echo "✓ Vaultwarden container: RUNNING"
else
    echo "✗ Vaultwarden container: STOPPED"
fi

# Check if backup exists
if docker exec vaultwarden-postgres pgbackrest info --stanza=vaultwarden 2>/dev/null | grep -q "full backup"; then
    echo "✓ Backup exists: YES"
else
    echo "✗ Backup exists: NO"
fi

echo ""
echo "========================================="
echo "            End of Report"
echo "========================================="
