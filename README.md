# backup-utils

A collection of shell backup utilities.

## Examples

Add a daily cronjob to backup parts of this site. Create `/etc/cron.daily/backup` as:

```bash
#!/bin/bash

export BACKUP_ROOT=/var/local/backups

# All logs are directed to syslog under local0 facility

/root/bin/backup-dir.sh -s /etc -s /var/www

/root/bin/backup-db.sh
```

Add a cronjob to fire after daily backups have been created (e.g 1h after the time cron.daily is scanned). Create `/etc/cron.d/exp-latest-backup` as:

```crontab
# A crontab fragment to export latest backups 

25 7   * * *   root    /root/bin/exp-latest-backup.sh
```
