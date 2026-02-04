#!/bin/bash
# Script to restore a pg_dump of a PostgreSQL Joplin database running in a docker container
# The dump file is accessible in the PostgreSQL container via the volume mounted on /backup
#
# Depends on: plakar-restore.sh (to restore a dump from a Plakar snapshot)
# Ref
# https://plakar.io/
# https://github.com/D4void/plakarbackup.git
#
# This script can be used to manage major version upgrades of PostgreSQL
#  by restoring a dump created with pg_dump from the old version into a new container
#  running the new PostgreSQL version.
#   1. Backup 
#   2. Stop all services 
#   3. Modify PostgreSQL image tag version
#   4. Erase all database data: rm -rf {DB_VOL}/*
#   5. Start only the database: "docker compose up joplin_db -d"
#   6. Restore with this script

source $(dirname $0)/.env

# Parameter validation
if [[ -z "$1" ]]; then
    echo "Usage: $0 <dump_file_name>"
    echo ""
    echo "Expected parameter: PostgreSQL dump filename located in ${DB_BACKUP_VOL}"
    echo ""
    exit 1
fi

DUMP_FILE=$(basename $1)

if [[ -f "$DB_BACKUP_VOL/$DUMP_FILE" ]]; then
    read -p "Is the Joplin database empty? " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo "/!\\ The database must be empty before proceeding with the restore."
        echo ""
        echo "Please follow these steps:"
        echo "  1. Stop all services: docker compose down"
        echo "  2. Delete volume data: rm -rf ${DB_VOL}/*"
        echo "  3. Restart only the database: docker compose up joplin_db -d"
        echo "  4. Re-run this restore script"
        echo ""
        exit 1
    fi

    read -p "Are you sure you want to restore ${POSTGRES_DATABASE} with dump $DUMP_FILE? " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        if [[ $(docker ps -q -f name=MyJoplinApp) ]]; then
            echo "Stopping Joplin App..."
            docker container stop MyJoplinApp
            if [[ $? -ne 0 ]]; then
                echo "/!\\ Error: Failed to stop MyJoplinApp"
                exit 1
            fi
        else
            echo "Joplin App is not running"
        fi

        echo "Restoring backup $DUMP_FILE into PostgreSQL"
        docker exec MyJoplinPostgres pg_restore -U ${POSTGRES_USER} -d ${POSTGRES_DATABASE} --no-owner --single-transaction /backup/$DUMP_FILE
        if [[ $? -ne 0 ]]; then
	        echo "/!\\ Error: Failed to restore PostgreSQL database"
            exit 1
        fi
    fi
else
    echo "Error: $1 does not exist in ${DB_BACKUP_VOL}!"
fi

echo "Restore completed."