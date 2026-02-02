#!/bin/bash
# Script to make a compressed dump of a Postgres Joplin database running in a Docker container
# The dump is dropped via a volume mounted on /backup
# Then a plakar snapshot of the dump is created
#
# Ref
# https://plakar.io/
# https://github.com/D4void/plakarbackup.git

source $(dirname $0)/.env

# Check if plakar script exists
if [[ ! -f "$PLAKAR" ]]; then
    echo "Error: plakarbackup.sh script not found at ${PLAKAR}"
    echo "Please install plakarbackup.sh or update the PLAKAR variable with the correct path"
    exit 1
fi

BACKUPDUMPFILE="${POSTGRES_DATABASE}_dump_$(date +"%Y-%m-%d_%Hh%Mm%S").dump"
LOGFILE="${DB_BACKUP_VOL}/$(basename "$0" .sh)-$(date '+%Y_%m_%d-%Hh%M').log"


############################################################
# FUNCTIONS
############################################################

__error() {
	__log "$1"
	set +o pipefail
	exit 1
}

__log() {
	echo $(date '+%Y/%m/%d-%Hh%Mm%Ss:') "$1" | tee -a $LOGFILE
}

############################################################
# MAIN
############################################################

set -o pipefail 1

__log "Stop Joplin App"
docker container stop MyJoplinApp
if [[ $? -ne 0 ]]; then
	__error "/!\\ Error stopping Joplin App." 1
fi

__log "Backuping Postgres ${POSTGRES_DATABASE} database"
docker exec MyJoplinPostgres pg_dump --format=custom --compress=6 -U ${POSTGRES_USER} ${POSTGRES_DATABASE} -f /backup/${BACKUPDUMPFILE}
if [[ $? -ne 0 ]]; then
	__error "/!\\ Error backing up Postgres database." 1
fi

__log "Start Joplin App"
docker container start MyJoplinApp
if [[ $? -ne 0 ]]; then
	__error "/!\\ Error starting Joplin App." 1
fi

# Plakar snapshot of the dump
__log "Create plakar snapshot of Postgres dump"
$PLAKAR ${OPTS:-} ${REPONAME} ${DB_BACKUP_VOL}/
if [[ $? -ne 0 ]]; then
    rm -f ${DB_BACKUP_VOL}/*.dump
    __error "/!\\ Error creating plakar snapshot." 1
fi
rm -f ${DB_BACKUP_VOL}/*

echo "End of Joplin backup."

set +o pipefail
exit 0