#!/bin/bash

source .env

docker exec -it MyJoplinPostgres pg_dump -U ${POSTGRES_USER} ${POSTGRES_DATABASE} | gzip -9 > ./${POSTGRES_DATABASE}_dump_$(date +"%Y-%m-%d_%Hh%Mm%S").sql.gz
