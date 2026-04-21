#!/bin/bash
# Change to the PostgreSQL data directory
cd /var/lib/postgresql/data
# Execute pgBackRest with the correct path
exec /usr/bin/pgbackrest --stanza=vaultwarden --pg1-path=/var/lib/postgresql/data archive-push "$1"
