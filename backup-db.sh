#!/bin/bash

ROTATION_SIZE=3
NAME='backup-db.sh'

test -z "${BACKUP_ROOT}" && BACKUP_ROOT="/var/local/backups"

#
# Helper functions
#

rotate_and_backup()
{
    # The command that actually carries out the backup. It is expected to write its
    # output directly to stdout
    local backup_command=${1}
    
    # The directory to store backups under.
    local backup_dir=${2}
    
    # The filename prefix
    local fname=${3} 
    
    # Rotate 
    for ((i=${ROTATION_SIZE}; i>0; i--))
    do
        let j=i-1
        test -f "${backup_dir}/${fname}.${j}" && mv "${backup_dir}/${fname}.${j}" "${backup_dir}/${fname}.${i}"
    done

    # Backup
    eval ${backup_command} > "${backup_dir}/${fname}.0"
}

backup_mysql_databases()
{
    logger -t ${NAME} -s -p 'local0.info' "Backing-up MySQL databases"
    sudo mysqldump -A -l
}

backup_postgres_databases()
{
    logger -t ${NAME} -s -p 'local0.info' "Backing-up PostgreSQL databases"
    sudo -u postgres pg_dumpall
}

#
# Main
#

# Determine source and destination

if test -d "${BACKUP_ROOT}" 
then 
    logger -t ${NAME} -s -p 'local0.info' "Using BACKUP_ROOT: ${BACKUP_ROOT}";
else
    logger -t ${NAME} -s -p 'local0.error' "Cannot use BACKUP_ROOT: Not a directory!";
    exit 1;
fi;

backup_dir=
while getopts "b:" option
do
     case ${option} in
         b)
             backup_dir=${BACKUP_ROOT}"/"${OPTARG}
             ;;
         ?)
             echo "Unknown option: ${option}"
             exit 1
             ;;
     esac
done

if test -z "${backup_dir}"
then
    backup_dir=${BACKUP_ROOT}"/"${HOSTNAME}"/db"
fi;

mkdir -p ${backup_dir}
backup_dir=$(cd ${backup_dir} && pwd)

logger -t ${NAME} -s -p 'local0.info' "Using backup_dir: ${backup_dir}";

# Dump

# TODO: 
# Find a better way to determine if database servers are actually running (assume a debian-based system)

mysql_running=$(ps aux| grep -e '/usr/\(bin\|sbin\)/mysqld'| grep -v -e grep)
if test -n "${mysql_running}" 
then
    rotate_and_backup backup_mysql_databases ${backup_dir} 'mysqldump.sql'
fi

postgres_running=$(ps aux| grep -e '/usr/lib/postgresql/[89].[1-9]/bin/postgres'| grep -v -e grep)
if test -n "${postgres_running}" 
then
    rotate_and_backup backup_postgres_databases ${backup_dir} 'pgdump.sql'
fi


