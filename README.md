# 🛡️ Vaultwarden PostgreSQL Backup Solution with pgBackRest

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Docker](https://img.shields.io/badge/docker-compose-blue)](https://www.docker.com/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-blue)](https://www.postgresql.org/)
[![pgBackRest](https://img.shields.io/badge/pgBackRest-2.58-green)](https://pgbackrest.org/)

## 📋 Overview

Production-ready backup solution for Vaultwarden's PostgreSQL database using **pgBackRest**. Implements automated hot backups with point-in-time recovery capability.

### Features

- ✅ **Hot backups** - Database stays online during backups
- ✅ **Automated** - Daily backups via cron (2:00 AM)
- ✅ **Consistent** - WAL archiving ensures data integrity  
- ✅ **Tested** - Verified backup & restore functionality
- ✅ **Docker-native** - Custom PostgreSQL image with pgBackRest
- ✅ **Monitoring** - Health checks and email alerts

## 🏗️ Architecture
┌─────────────────────────────────────────────────────┐
│ Docker Compose │
├─────────────────────────────────────────────────────┤
│ ┌──────────────┐ ┌──────────────┐ ┌────────────┐ │
│ │ Vaultwarden │ │ PostgreSQL │ │ Cloudflared│ │
│ │ (Rocket) │ │ (Custom) │ │ (Tunnel) │ │
│ └──────┬───────┘ └──────┬───────┘ └────────────┘ │
│ │ │ │
│ ▼ ▼ │
│ ┌──────────────────────────────────────────────┐ │
│ │ pgBackRest Backup Repository │ │
│ │ (Docker Volume) │ │
│ └──────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────┘


## 🚀 Quick Start

### Prerequisites

- Docker & Docker Compose
- Linux environment (Ubuntu/Debian)

### Installation

```bash
# Clone repository
git clone https://github.com/Sodimu/vaultwarden-pgbackrest-backup.git
cd vaultwarden-pgbackrest-backup

# Build custom PostgreSQL image with pgBackRest
docker compose build --no-cache postgres

# Start all services
docker compose up -d

# Verify backup system is working
./check_backup_status.sh

📊 Backup Management
Manual Backup
./backup_vaultwarden.sh

Restore Database
./restore_vaultwarden.sh
# Follow interactive prompts to select backup label

View Backup Status
# Show all backups
docker exec vaultwarden-postgres pgbackrest info --stanza=vaultwarden

# Detailed status report
./check_backup_status.sh


Automation
Cron job configured for daily backups:
# Daily backup at 2:00 AM
0 2 * * * /home/babajide/vaultwarden/backup_vaultwarden.sh

# Daily health check at 8:00 AM
0 8 * * * /home/babajide/vaultwarden/check_backup_health.sh


📁 Project Structure
vaultwarden-pgbackrest-backup/
├── backup_vaultwarden.sh              # Main backup script
├── restore_vaultwarden.sh             # Interactive restore script
├── check_backup_status.sh             # Health check & status
├── check_backup_health.sh             # Monitoring script
├── start_vaultwarden.sh               # Service startup
├── stop_vaultwarden.sh                # Service shutdown
├── docker-compose.yml                 # Service orchestration
├── Dockerfile.postgres                # Custom PostgreSQL image
├── pgbackrest/
│   ├── config/
│   │   └── pgbackrest.conf            # Backup configuration
│   └── postgres-config/
│       └── postgresql.conf            # PostgreSQL with WAL archiving
└── logs/                              # Backup logs directory


Testing Results
Test	Result
Backup while database active	✅ Passed
Restore to point-in-time	✅ Passed
Data consistency after restore	✅ Passed
Automated cron execution	✅ Passed
WAL archiving	✅ Passed


🔧 Troubleshooting
Backup fails with "archive_command"
Ensure PostgreSQL has correct working directory in docker-compose.yml:
working_dir: /var/lib/postgresql/data

Restore fails with "backup set latest is not valid"
Use specific backup label instead of 'latest':
# List available backups
docker exec vaultwarden-postgres pgbackrest info --stanza=vaultwarden

# Restore with specific label
./restore_vaultwarden.sh 20260420-184754F

📈 Monitoring
Daily health check at 8:00 AM

Email alerts on backup failures (configurable)

Archive status monitoring via pg_stat_archiver

🔐 Security Considerations
Backup repository stored in isolated Docker volume

WAL archiving with point-in-time recovery

Retention policy: last 2 full backups kept

Configuration files excluded from version control (use .example files)

📝 License
MIT License - See LICENSE file

👨‍💻 Author
Babajide Sodimu

GitHub: @Sodimu

LinkedIn: www.linkedin.com/in/babajide-sodimu-5a2b8990

🙏 Acknowledgments
pgBackRest - Reliable PostgreSQL backup and restore

Vaultwarden - Unofficial Bitwarden server

Bitwarden - Password management inspiration

📧 Contact
For questions or suggestions, please open an issue on GitHub.

