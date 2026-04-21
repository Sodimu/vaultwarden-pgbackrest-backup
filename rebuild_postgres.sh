#!/bin/bash
# Rebuild PostgreSQL with pgBackRest and start services

echo "=== Rebuilding PostgreSQL with pgBackRest ==="

# Stop all services
echo "Stopping services..."
docker compose down

# Rebuild PostgreSQL image without cache
echo "Building custom PostgreSQL image with pgBackRest..."
docker compose build --no-cache postgres

# Start all services
echo "Starting services..."
docker compose up -d

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
sleep 15

# Check if pgBackRest is installed
echo "Verifying pgBackRest installation..."
docker exec vaultwarden-postgres pgbackrest --version

# Check stanza status
echo "Checking pgBackRest stanza..."
docker exec vaultwarden-postgres pgbackrest info --stanza=vaultwarden

echo "=== Rebuild complete ==="
echo "PostgreSQL is running with pgBackRest support"
