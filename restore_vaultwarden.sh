#!/bin/bash
# Restore script for Vaultwarden
# Usage: ./restore_vaultwarden.sh [BACKUP_LABEL]

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}=== Vaultwarden Database Restore ===${NC}"
echo

# Show available backups
echo "Available backups:"
docker exec vaultwarden-postgres pgbackrest info --stanza=vaultwarden
echo

# Get backup label from argument or prompt
if [ -z "$1" ]; then
    echo -e "${YELLOW}Available backup labels:${NC}"
    docker exec vaultwarden-postgres pgbackrest info --stanza=vaultwarden | grep "full backup:" | awk '{print "  " $NF}'
    echo
    read -p "Enter backup label to restore (from list above): " BACKUP_LABEL
else
    BACKUP_LABEL="$1"
fi

if [ -z "$BACKUP_LABEL" ]; then
    echo -e "${RED}No backup label provided. Exiting.${NC}"
    exit 1
fi

# Confirm restore
echo -e "${RED}WARNING: This will overwrite your current database!${NC}"
read -p "Are you sure you want to restore backup '$BACKUP_LABEL'? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Restore cancelled."
    exit 0
fi

echo "Stopping services..."
docker compose stop vaultwarden
docker compose stop postgres

echo "Clearing existing data..."
docker run --rm -v vaultwarden_postgres_data:/data alpine sh -c "rm -rf /data/*"

echo "Restoring from backup: $BACKUP_LABEL"
docker run --rm \
  -v vaultwarden_postgres_data:/var/lib/postgresql/data \
  -v vaultwarden_pgbackrest_repo:/var/lib/pgbackrest \
  -v $(pwd)/pgbackrest/config/pgbackrest.conf:/etc/pgbackrest.conf:ro \
  vaultwarden-postgres \
  pgbackrest --stanza=vaultwarden restore --set="$BACKUP_LABEL"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Restore completed successfully!${NC}"
    
    echo "Starting services..."
    docker compose start postgres
    sleep 10
    docker compose start vaultwarden
    
    echo -e "${GREEN}✓ Vaultwarden has been restored!${NC}"
    
    # Show restored data stats
    sleep 5
    USER_COUNT=$(docker exec vaultwarden-postgres psql -U vaultwarden vaultwarden -t -c "SELECT COUNT(*) FROM users;" 2>/dev/null | xargs)
    CIPHER_COUNT=$(docker exec vaultwarden-postgres psql -U vaultwarden vaultwarden -t -c "SELECT COUNT(*) FROM ciphers;" 2>/dev/null | xargs)
    echo -e "${GREEN}Restored database: $USER_COUNT users, $CIPHER_COUNT ciphers${NC}"
else
    echo -e "${RED}✗ Restore failed!${NC}"
    exit 1
fi
