#!/bin/bash
# Script to restore a pg_dump of a PostgreSQL Joplin database running in a docker container
# The dump is accessible via the volume mounted on /backup
#
# Depends on: plakar-restore.sh (to restore a dump from a Plakar snapshot)
# Ref
# https://plakar.io/
# https://github.com/D4void/plakarbackup.git
#
# This script can be used to manage major version upgrades of PostgreSQL
# by restoring a dump created with pg_dump from the old version into a new container
# running the new PostgreSQL version.
# 1. backup 2. stop all services 3. rm -rf ${DB_VOL}/* 4. modify tag version 5. restart only db 6. restore 7. start joplin

source $(dirname $0)/.env

# Vérification des paramètres
if [[ -z "$1" ]]; then
    echo "Usage: $0 <dump_file_path>"
    echo ""
    echo "Expected parameter: Full path to the PostgreSQL dump file"
    echo ""
    exit 1
fi

DUMP_PATH=$1

if [[ -f "$DUMP_PATH" ]]; then
    read -p "Are you sure you want to restore ${POSTGRES_DATABASE} with dump $DUMP_PATH ? " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        echo "Stop Joplin App"
        docker container stop MyJoplinApp

        echo "Restoring backup $DUMP_PATH into PostgreSQL"
        docker exec MyJoplinPostgres pg_restore -U ${POSTGRES_USER} -d ${POSTGRES_DATABASE} --no-owner --single-transaction /backup/$(basename $DUMP_PATH)

        echo "Start Joplin App"
        docker container start MyJoplinApp
    fi
else
    echo "$1 doesn't exist!"
fi

echo "End."