#!/bin/bash
# Simple startup script for Vaultwarden

cd /home/babajide/vaultwarden

echo "Starting Vaultwarden services..."

# Check if we need to rebuild (only if Dockerfile changed)
if [ "$1" = "--rebuild" ]; then
    echo "Rebuilding PostgreSQL image..."
    docker compose build --no-cache postgres
fi

# Start services
docker compose up -d

# Wait for services to be ready
echo "Waiting for services to start..."
sleep 5

# Show status
docker compose ps

echo ""
echo "Vaultwarden should be available at: http://localhost:8080"
echo "To view logs: docker compose logs -f"
