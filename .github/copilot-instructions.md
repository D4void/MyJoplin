# MyJoplin - AI Coding Agent Instructions

## Project Overview
This is a production Joplin Server deployment using Docker Compose with a custom-built image (`d4void/joplin`) from official Joplin source. The setup integrates with an external Traefik reverse proxy (MyTraefik project) for SSL termination and routing.

## Architecture & Services

### Service Stack
- **joplin_app**: Main Joplin Server application container (custom image built from official source)
- **joplin_db**: PostgreSQL 16.2 database backend
- **External dependency**: Traefik reverse proxy (MyTraefikNet network)

### Network Architecture
- **MyJoplinNet**: Internal network for joplin_app ↔ joplin_db communication
- **MyTraefikNet**: External network connecting to Traefik reverse proxy (must exist before deployment)
- Container depends on Traefik being available for proper routing

### Volume Strategy
Uses bind mounts (not Docker volumes) to specific host paths:
- `${DB_VOL}` → PostgreSQL data (`/var/lib/postgresql/data`)
- `${DB_BACKUP_VOL}` → Backup staging directory (`/backup` inside postgres container)

## Critical Developer Workflows

### Initial Setup
1. Copy `env.example` to `.env` and configure all variables (especially `JOPLIN_FQDN` and `APP_BASE_URL`)
2. Ensure `MyTraefikNet` Docker network exists (from MyTraefik project deployment)
3. Deploy: `docker compose up -d`

**Important**: `APP_BASE_URL` must match the full HTTPS URL Traefik routes to (`https://${JOPLIN_FQDN}`)

### Building Custom Image
The project builds Joplin Server from official source rather than using pre-built images:

```bash
./build.sh  # Downloads Joplin v${JOPLIN_TAG} source, builds, and pushes to Docker Hub
```

**Build workflow**:
1. Downloads `https://github.com/laurent22/joplin/archive/refs/tags/v${JOPLIN_TAG}.tar.gz`
2. Extracts and navigates to source directory
3. Builds using `Dockerfile.server` from official Joplin repository
4. Tags as `d4void/joplin:${JOPLIN_TAG}` and pushes to Docker Hub
5. Cleans up temporary files

### Backup Workflow
`./psql-backup.sh` creates compressed PostgreSQL dumps:
- Dumps database using `pg_dump --format=custom --compress=6`
- Saves to `${DB_BACKUP_VOL}` with timestamped filename (`${POSTGRES_DATABASE}_dump_YYYY-MM-DD_HHhMMmSS.dump`)
- Custom format allows selective restore and parallel restore capabilities

### Restore Workflow
`./psql-restore.sh <backup_file>`:
- Takes filename argument (relative to `/backup` inside container)
- Prompts for confirmation before restoring
- Uses `pg_restore --no-owner --single-transaction` for atomic restore
- Backup file must exist in `${DB_BACKUP_VOL}` directory

**Critical**: Restore is destructive; always verify backup file before confirming

## Project-Specific Conventions

### Environment Variables
- `JOPLIN_TAG`: Pin exact version (e.g., `3.3.13`), never use `latest`
- `JOPLIN_PORT`: Internal container port (typically `22300`) - referenced in Traefik loadbalancer labels
- `JOPLIN_FQDN`: Domain name for Traefik routing (e.g., `myjoplin.domain.fr`)
- `APP_BASE_URL`: Must be full HTTPS URL matching `JOPLIN_FQDN` for proper Joplin operation
- `POSTGRES_*`: Standard PostgreSQL connection credentials

### Traefik Integration
Uses Traefik labels with standard pattern:
- Routes HTTP traffic via `Host()` rule to `${JOPLIN_FQDN}`
- Terminates TLS with `certresolver=mytlschallenge` (Let's Encrypt via Traefik)
- Applies `security@file` middleware from Traefik's dynamic config (HSTS, security headers)
- Explicitly sets `loadbalancer.server.port=${JOPLIN_PORT}` and `scheme=http`
- Container attaches to both internal (`joplinnet`) and external (`MyTraefikNet`) networks

### Email Configuration
Joplin Server supports email notifications (user registration, password reset):
- Set `MAILER_ENABLED=1` to enable
- Requires SMTP configuration (`MAILER_HOST`, `MAILER_PORT`, `MAILER_SECURITY=starttls`)
- Uses authenticated SMTP (`MAILER_AUTH_USER`, `MAILER_AUTH_PASSWORD`)

## Integration Points
- **External**: Traefik reverse proxy on MyTraefikNet (must exist before deployment)
- **Orchestrator**: Can be included in MyDockerApps project via `services.sh joplin up/down`
- **DNS**: External DNS A record for `${JOPLIN_FQDN}` must point to server IP

## Key Files Reference
- [docker-compose.yml](docker-compose.yml): Service definition with Traefik labels and PostgreSQL setup
- [env.example](env.example): Template with all required environment variables including mailer settings
- [build.sh](build.sh): Downloads Joplin source and builds custom Docker image
- [psql-backup.sh](psql-backup.sh): PostgreSQL dump creation with custom format
- [psql-restore.sh](psql-restore.sh): Interactive PostgreSQL restore with confirmation

## Common Pitfalls
- **APP_BASE_URL mismatch**: Must be `https://${JOPLIN_FQDN}` exactly, or Joplin will generate incorrect URLs
- **Missing MyTraefikNet**: Container will fail to start if external network doesn't exist
- **Port confusion**: `JOPLIN_PORT` is internal container port; Traefik handles external 443 routing
- **Backup restore**: Always use custom format dumps (`.dump` extension), not plain SQL
