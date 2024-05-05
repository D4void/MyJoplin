#!/bin/bash

source $(dirname $0)/.env

backupfile="${POSTGRES_DATABASE}_dump_$(date +"%Y-%m-%d_%Hh%Mm%S").dump"
#docker exec -it MyJoplinPostgres pg_dump -U ${POSTGRES_USER} ${POSTGRES_DATABASE} | gzip -9 > ./${POSTGRES_DATABASE}_dump_$(date +"%Y-%m-%d_%Hh%Mm%S").sql.gz

echo "Backuping Postgres ${POSTGRES_DATABASE} database"

docker exec MyJoplinPostgres pg_dump --format=custom --compress=6 -U ${POSTGRES_USER} ${POSTGRES_DATABASE} -f /backup/${backupfile}

#echo "Copy backup from container"

#docker cp MyJoplinPostgres:/${backupfile} .

echo "End."

#docker_command="PGPASSWORD=${POSTGRES_PASSWORD} pg_dump --format=custom --compress=9 -h MyJoplinPostgres \
#-U ${POSTGRES_USER} ${POSTGRES_DATABASE} \
#-f /backup/${POSTGRES_DATABASE}_dump_$(date +"%Y-%m-%d_%Hh%Mm%S").dump.gz"
#docker run --rm -it --network MyJoplinNet -v .:/backup postgres:16.2-alpine3.19 -c "$docker_command"