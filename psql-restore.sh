#!/bin/bash
# Script to restore a pg_dump of a Postgres Joplin database running in a docker container
# The dump is accessible via the volume mounted on /backup

source $(dirname $0)/.env

if [[ -f "$1" ]]; then
    read -p "Are you sure you want to restore ${POSTGRES_DATABASE} with dump $1 ? " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        echo "Restoring backup $1 into Postgres"
        docker exec MyJoplinPostgres pg_restore -U ${POSTGRES_USER} -d ${POSTGRES_DATABASE} --no-owner --single-transaction /backup/$1
    fi
else
    echo "$1 doesn't exist!"
fi

echo "End."