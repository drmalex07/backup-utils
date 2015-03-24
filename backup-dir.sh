#!/bin/bash

# ----------------------------------------------------------------------
# A rotating-directory snapshot utility
# ----------------------------------------------------------------------

ROTATION_SIZE=5
NAME="$(basename $0)"

#
# Parse command-line
#

test -z "${BACKUP_ROOT}" && BACKUP_ROOT="/var/local/backups"

if test -d "${BACKUP_ROOT}" 
then 
    logger -t ${NAME} -s -p 'local0.info' "Using BACKUP_ROOT: ${BACKUP_ROOT}";
else
    logger -t ${NAME} -s -p 'local0.error' "Cannot use BACKUP_ROOT: Not a directory!";
    exit 1;
fi;

source_dir=
backup_dir=

rsync_flags='rlpt'

while getopts "s:b:o" option
do
     case ${option} in
         s)
             if test -d ${OPTARG} ; 
             then
                 # Concantenate to existing sources (no spaces allowed!)
                 source_dir="$(cd ${OPTARG} && pwd) ${source_dir}"
             else 
                 logger -t ${NAME} -s -p 'local0.error' "Cannot use source (${OPTARG})"
                 exit 1; 
             fi;
             ;;
         b)
             backup_dir=${BACKUP_ROOT}"/"${OPTARG}
             ;;
         o)  
             [[ ! $rsync_flags =~ 'o' ]] && rsync_flags="${rsync_flags}og"
             ;;
         ?)
             echo "Unknown option: ${option}"
             exit 1
             ;;
     esac
done

if test -z "${source_dir}"
then
    echo "Usage:${NAME} [-o] [-s <source-dir>]* [-b <target-dir>]"
    echo "  -o: preserve ownership (group+owner)"
    echo "  -s: provide a source directory"
    echo "  -b: provide a (relative to BACKUP_ROOT) target directory"
    exit 0
else
    logger -t ${NAME} -s -p 'local0.info' "Using source(s): ${source_dir}"; 
fi;

if test -z "${backup_dir}"
then
    backup_dir=${BACKUP_ROOT}"/"${HOSTNAME}"/files"
fi;

mkdir -p ${backup_dir}
backup_dir="$(cd ${backup_dir} && pwd)"

logger -t ${NAME} -s -p 'local0.info' "Using backup_dir: ${backup_dir}"; 

rsync_opts="-${rsync_flags} -vhi --delete"
logger -t ${NAME} -s -p 'local0.info' "Using rsync options: ${rsync_opts}"; 

#
# Rotate snapshots and backup
#

# Step 1: Delete the oldest snapshot, if it exists:

i=${ROTATION_SIZE}
if test -d ${backup_dir}/snap.${i}  
then
    rm -rf ${backup_dir}/snap.${i};
fi ;

# Step 2: Shift the middle snapshot(s) back by one, if they exist

for ((i=${ROTATION_SIZE}; i>1; i--))
do
    let j=i-1
    if test -d ${backup_dir}/snap.${j} 
    then
        mv ${backup_dir}/snap.${j} ${backup_dir}/snap.${i} ;
    fi
done

# Step 3: Make a hard-link-only copy of the latest snapshot, if exists
if test -d ${backup_dir}/snap.0 
then
    cp -al ${backup_dir}/snap.0 ${backup_dir}/snap.1 ;
fi;

# Step 4: Rsync from the system into the latest snapshot (notice that
# rsync behaves like cp --remove-destination by default, so the destination
# is unlinked first.  If it were not so, this would copy over the other
# snapshot(s) too!
rsync ${rsync_opts} ${source_dir} ${backup_dir}/snap.0 ;

# Step 5: Update the mtime of snap.0 to reflect the snapshot time
touch ${backup_dir}/snap.0 ;

