# MyJoplin

A production-ready [Joplin Server](https://joplinapp.org/) deployment using Docker Compose with PostgreSQL backend and Traefik reverse proxy integration for SSL/TLS termination.

## Overview

This project provides:
- **Joplin Server**: Custom Docker image (`d4void/joplin`) built from official Joplin source
- **PostgreSQL**: Database backend for storing notes and user data
- **Traefik Integration**: Automatic HTTPS with Let's Encrypt certificates
- **Backup & Restore**: Scripts for PostgreSQL dumps with [Plakar](https://plakar.io/) snapshot support

## Architecture

```
                    ┌─────────────────┐
                    │    Traefik      │
                    │  (MyTraefikNet) │
                    └────────┬────────┘
                             │ HTTPS :443
                             ▼
┌────────────────────────────────────────────┐
│              MyJoplin Stack                │
│                                            │
│  ┌─────────────┐      ┌─────────────────┐  │
│  │ joplin_app  │◄────►│    joplin_db    │  │
│  │  (Server)   │      │  (PostgreSQL)   │  │
│  └─────────────┘      └─────────────────┘  │
│        MyJoplinNet (internal)              │
└────────────────────────────────────────────┘
```

## Prerequisites

- Docker and Docker Compose
- [MyTraefik](https://github.com/D4void/MyTraefik) project deployed (provides `MyTraefikNet` network)
- [MyDockerApps](https://github.com/D4void/MyDockerApps) - Unified Docker Compose orchestrator
- [Plakar](https://plakar.io/) - Plakar installed. Backup tool used for snapshots
- [plakarbackup](https://github.com/D4void/plakarbackup) - My Bash wrapper script for plakar
- DNS A record pointing to your server for `JOPLIN_FQDN`

## Quick Start

### 1. Configure Environment

```bash
cp env.example .env
chmod 600 .env
```

Edit `.env` and configure at minimum:
- `JOPLIN_FQDN`: Your domain (e.g., `joplin.example.com`)
- `APP_BASE_URL`: Full HTTPS URL (e.g., `https://joplin.example.com`)
- `POSTGRES_PASSWORD`: Strong database password
- `DB_VOL` / `DB_BACKUP_VOL`: Host paths for data persistence

### 2. Initialize Volume Directories

```bash
sudo ./init-voldir.sh
```

This creates the required directories with proper ownership:
- `${DB_VOL}` (uid:gid 70:70, chmod 700) - PostgreSQL data
- `${DB_BACKUP_VOL}` (chmod 750) - Backup staging

### 3. Build Custom Image (Optional)

If you want to build the Joplin image yourself, edit build.sh and run it:

```bash
./build.sh
```

This downloads Joplin source for version `${JOPLIN_TAG}`, builds `d4void/joplin:${JOPLIN_TAG}`, and pushes to Docker Hub. (Change to your dockerhub repository and modify docker compose file accordingly)

### 4. Deploy

**Recommended**: Use [MyDockerApps](https://github.com/D4void/MyDockerApps) orchestrator to manage Traefik dependency:

```bash
cd ../MyDockerApps
docker compose up -d
```

This ensures Traefik starts first and creates the `MyTraefikNet` network before Joplin services attempt to connect.

**Alternative** (standalone, requires MyTraefik already running):

```bash
docker compose up -d
```

Access Joplin Server at `https://${JOPLIN_FQDN}`

## Local Development (Without Traefik)

For local testing without the Traefik reverse proxy, use the dedicated local configuration:

### Local Configuration Files

| File | Description |
|------|-------------|
| `docker-compose-local.yml` | Compose file without Traefik labels and dependencies |
| `.env.local` | Environment configured for localhost access |

### Key Differences from Production

| Aspect | Production | Local |
|--------|------------|-------|
| Traefik dependency | Required | None |
| HTTPS/TLS | Via Traefik + Let's Encrypt | None (HTTP only) |
| Access URL | `https://${JOPLIN_FQDN}` | `http://localhost:22300` |
| Port exposure | Via Traefik routing | Direct port mapping |
| External network | `MyTraefikNet` | None |

### Local Deployment

```bash
# Deploy locally
docker compose -f docker-compose-local.yml --env-file .env.local up -d

# View logs
docker compose -f docker-compose-local.yml --env-file .env.local logs -f

# Stop
docker compose -f docker-compose-local.yml --env-file .env.local down
```

Access Joplin Server at `http://localhost:22300`

> **Note**: The local setup exposes port `22300` directly on the host. This is suitable for development/testing only, not for production use.

## Configuration Reference

### Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `JOPLIN_TAG` | Joplin Server version | `3.5.12` |
| `POSTGRES_TAG` | PostgreSQL image tag | `16.11-alpine3.22` |
| `JOPLIN_FQDN` | Domain for Traefik routing | `joplin.example.com` |
| `APP_BASE_URL` | Public URL (must match FQDN) | `https://joplin.example.com` |
| `JOPLIN_PORT` | Internal container port | `22300` |
| `DB_VOL` | PostgreSQL data path | `/opt/MyJoplinPostgres` |
| `DB_BACKUP_VOL` | Backup directory path | `/opt/MyJoplinPostgresBackup` |

### Email Configuration (Optional)

Enable email notifications for user registration and password resets:

| Variable | Description |
|----------|-------------|
| `MAILER_ENABLED` | Set to `1` to enable |
| `MAILER_HOST` | SMTP server hostname |
| `MAILER_PORT` | SMTP port (typically `587`) |
| `MAILER_SECURITY` | `starttls` or `tls` |
| `MAILER_AUTH_USER` | SMTP username |
| `MAILER_AUTH_PASSWORD` | SMTP password |
| `MAILER_NOREPLY_NAME` | Sender display name |
| `MAILER_NOREPLY_EMAIL` | Sender email address |

## Backup & Restore

### Backup

```bash
./joplin-backup.sh
```

This script:
1. Stops the Joplin application container
2. Creates a compressed PostgreSQL dump (`pg_dump --format=custom --compress=6`)
3. Restarts the Joplin application
4. Creates a Plakar snapshot of the dump
5. Cleans up local dump files

**Dependency**: Requires [plakarbackup.sh](https://github.com/D4void/plakarbackup) installed at the path specified in `PLAKAR` variable.

### Restore from Plakar Snapshot

```bash
# Step 1: Restore dump from Plakar to backup volume
./plakar-restore.sh <repository_name> ${DB_BACKUP_VOL} <snapshot_id>

# Step 2: Restore database from dump
./joplin-restore.sh <dump_file_name>
```

### Direct Database Restore

If you have a dump file available:

```bash
# Ensure database is empty first
docker compose down
sudo rm -rf ${DB_VOL}/*
docker compose up joplin_db -d

# Restore
./joplin-restore.sh mydatabase_dump_2025-01-15_10h30m00.dump
```

### PostgreSQL Major Version Upgrade

1. Create a backup with `./joplin-backup.sh`
2. Stop all services: `docker compose down`
3. Update `POSTGRES_TAG` in `.env` to new major version
4. Delete existing data: `sudo rm -rf ${DB_VOL}/*`
5. Start only database: `docker compose up joplin_db -d`
6. Restore dump: `./joplin-restore.sh <dump_file>`
7. Start all services: `docker compose up -d`

## Integration with MyDockerApps

This project is included in the [MyDockerApps](https://github.com/D4void/MyDockerApps) orchestrator:

```bash
# From MyDockerApps directory
./services.sh joplin up    # Start Joplin services
./services.sh joplin down  # Stop Joplin services
```

## Network Configuration

### Internal Network
- `MyJoplinNet`: Internal network for `joplin_app` ↔ `joplin_db` communication

### External Network  
- `MyTraefikNet`: Connection to Traefik reverse proxy (must exist before deployment)

## Traefik Labels

The `joplin_app` service uses these Traefik labels:
- Routes HTTPS traffic via `Host()` rule
- TLS termination with `certresolver=mytlschallenge` (Let's Encrypt)
- Security middleware from `security@file` (HSTS, security headers)
- Load balancer configured for internal port `${JOPLIN_PORT}`

## Troubleshooting

### APP_BASE_URL Mismatch
If Joplin generates incorrect URLs, ensure `APP_BASE_URL` exactly matches `https://${JOPLIN_FQDN}`.

### View Logs
```bash
docker compose logs -f joplin_app
docker compose logs -f joplin_db
```

## File Structure

```
MyJoplin/
├── docker-compose.yml        # Production service definitions (with Traefik)
├── docker-compose-local.yml  # Local dev/test (without Traefik)
├── env.example               # Production environment template
├── .env                      # Your production config (git-ignored)
├── .env.local                # Local dev/test config
├── build.sh                  # Builds custom Joplin image
├── init-voldir.sh            # Creates volume directories
├── joplin-backup.sh          # Backup with Plakar integration
├── joplin-restore.sh         # Database restore script
├── plakar-restore.sh         # Plakar snapshot restoration
├── LICENSE                   # MIT License
└── README.md                 # This file
```

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

## Related Projects

- [MyTraefik](https://github.com/D4void/MyTraefik) - Traefik reverse proxy configuration
- [MyDockerApps](https://github.com/D4void/MyDockerApps) - Unified Docker Compose orchestrator
- [Joplin](https://github.com/laurent22/joplin) - Official Joplin repository
- [Joplin help](https://joplinapp.org/help/) - Joplin help
- [Plakar](https://plakar.io/) - Backup tool used for snapshots
- [plakarbackup](https://github.com/D4void/plakarbackup) - Bash wrapper script for plakar


---

*This README was initially generated with AI assistance.*