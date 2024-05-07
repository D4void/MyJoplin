#!/bin/bash
# Script pour restaurer un dump pg_dump d'une base Postgres Joplin en container docker
# Le dump est accesible via le volume monté sur /backup

source $(dirname $0)/.env

if [[ ! -f "$1" ]]; then
    echo "Restoring backup $1 into Postgres"
    docker exec MyJoplinPostgres pg_restore -U ${POSTGRES_USER} -d ${POSTGRES_DATABASE} --no-owner --single-transaction /backup/$1
else
    echo "$1 doesn't exist!"
fi

echo "End."