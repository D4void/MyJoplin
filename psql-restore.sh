#!/bin/bash

source .env

gunzip $1

#docker cp $(dirname $1)/$(basename $1 .gz) MyJoplinPostgres:/db.sql
docker cp $(dirname $1)/$(basename $1 .gz) MyJoplinPostgres:/db.dump

#docker exec -it MyJoplinPostgres cat /db.sql |psql -U ${POSTGRES_USER} -d ${POSTGRES_DATABASE}
docker exec -it MyJoplinPostgres pg_restore -U ${POSTGRES_USER} -d ${POSTGRES_DATABASE} --no-owner --single-transaction /db.dump
