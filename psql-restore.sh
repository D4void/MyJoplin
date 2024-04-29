#!/bin/bash

source .env

gunzip $1

docker cp $(basename $1 .gz) MyJoplinPostgres:/db.sql

docker exec -it MyJoplinPostgres pg_restore ${POSTGRES_USER} -d ${POSTGRES_DATABASE} --no-owner -1 /db.sql
