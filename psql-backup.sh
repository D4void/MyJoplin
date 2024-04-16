#!/bin/bash
# Script to make a compressed dump of a Postgres Joplin database running in a Docker container
# The dump is dropped via a volume mounted on /backup

source $(dirname $0)/.env

backupfile="${POSTGRES_DATABASE}_dump_$(date +"%Y-%m-%d_%Hh%Mm%S").dump"
echo "Backuping Postgres ${POSTGRES_DATABASE} database"
docker exec MyJoplinPostgres pg_dump --format=custom --compress=6 -U ${POSTGRES_USER} ${POSTGRES_DATABASE} -f /backup/${backupfile}
echo "End."
