#!/bin/bash
# Script pour faire un un dump compressé d'une base Postgres Joplin en container docker
# Le dump est déposé via un volume monté sur /backup

source $(dirname $0)/.env

backupfile="${POSTGRES_DATABASE}_dump_$(date +"%Y-%m-%d_%Hh%Mm%S").dump"
echo "Backuping Postgres ${POSTGRES_DATABASE} database"
docker exec MyJoplinPostgres pg_dump --format=custom --compress=6 -U ${POSTGRES_USER} ${POSTGRES_DATABASE} -f /backup/${backupfile}
echo "End."
