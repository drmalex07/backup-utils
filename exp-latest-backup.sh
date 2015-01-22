#!/bin/bash

# Archive our latest backup snapshot and copy it to a folder 
# exported via rsyncd.
# Require: p7zip-full

# Assume a backup directory structure as follows:
#  - <BACKUP_ROOT>/<hostname>/files/snap.<index>
#  - <BACKUP_ROOT>/<hostname>/db/pgdump.sql.<index>
#  - <BACKUP_ROOT>/<hostname>/db/mysqldump.sql.<index>

NAME='exp-latest-backup.sh'

if test -f "${SECRET_FILE}"
then
    logger -t ${NAME} -s -p 'local0.info' "Reading secret from ${SECRET_FILE}"
else
    logger -t ${NAME} -s -p 'local0.error' "Cannot find a secret to protect exported archives"
    exit 1
fi

test -z "${BACKUP_ROOT}" && BACKUP_ROOT=/var/local/backups 
logger -t ${NAME} -s -p 'local0.info' "Using backups from ${BACKUP_ROOT}"

test -z "${BACKUP_EXPORT_ROOT}" && BACKUP_EXPORT_ROOT=/var/local/exports/backups
logger -t ${NAME} -s -p 'local0.info' "Exporting backup archive to ${BACKUP_EXPORT_ROOT}"

secret=$(cat ${SECRET_FILE})

cd ${BACKUP_ROOT}
for h in $(ls)
do
    sources="${h}/files/snap.0 ${h}/db/*.sql.0"
    archive="${BACKUP_EXPORT_ROOT}/${h}.tar.7z"
    archive1=$(mktemp --dry-run --suffix '.7z' "archive.${h}.XXXXXXXXX")
    # Create a new archive from latest backup snapshot
    tar cf - ${sources} | 7z a -bd -p"${secret}" -si ${archive1}
    if [ $? == 0 ]
    then
        # Created, replace existing archive (if exists)
        mv -v ${archive1} ${archive}
        logger -t ${NAME} -s -p 'local0.info' "Created an archive at ${archive}"
    else
        # Failed, keep the last valid snapshot
        logger -t ${NAME} -s -p 'local0.error' "Cannot create archive at ${archive}"
    fi
done

