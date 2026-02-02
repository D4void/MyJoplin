#!/bin/bash
# Script to init docker volumes host directories, set uid/gid and rights
# 

source .env

if [[ ! -d ${DB_VOL}  ]]; then

    mkdir -p ${DB_VOL}
    chown 70:70 ${DB_VOL}
    chmod 700 ${DB_VOL}

fi

if [[ ! -d ${DB_BACKUP_VOL}  ]]; then

    mkdir -p ${DB_BACKUP_VOL}
    chmod 777 ${DB_BACKUP_VOL}
fi
