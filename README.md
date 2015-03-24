# backup-utils

A collection of rotate-style backup utilities:
 * `backup-dir.sh`: backup a snapshot of a directory
 * `backup-db.sh`: backup a snapshot of a MySQL/PostgreSQL database

The generated logs (from all scripts) are directed to syslog under` LOCAL0` facility.

## Examples

Add a daily cronjob to backup parts of this site. Create `/etc/cron.daily/backup` as:

```bash
#!/bin/bash

export BACKUP_ROOT=/var/local/backups

~root/bin/backup-dir.sh -s /etc -s /var/www -b ${HOSTNAME}/files

~root/bin/backup-db.sh -b ${HOSTNAME}/databases
```

Add a cronjob to fire after daily backups have been created (e.g 1h after the time cron.daily is scanned). Create `/etc/cron.d/exp-latest-backup` as:

```crontab
# A crontab fragment to export latest backups 

25 7   * * *   root    /root/bin/exp-latest-backup.sh
```
