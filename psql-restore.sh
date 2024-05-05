#!/bin/bash

source $(dirname $0)/.env

#gunzip $1

#docker cp $(dirname $1)/$(basename $1 .gz) MyJoplinPostgres:/db.sql
#docker cp $(dirname $1)/$(basename $1 .gz) MyJoplinPostgres:/db.dump

#echo "Copying backup $1 into container"
#docker cp $1 MyJoplinPostgres:/db.dump.gz

echo "Restoring backup $1 into Postgres"

docker exec MyJoplinPostgres pg_restore -U ${POSTGRES_USER} -d ${POSTGRES_DATABASE} --no-owner --single-transaction /backup/$1

echo "End."
