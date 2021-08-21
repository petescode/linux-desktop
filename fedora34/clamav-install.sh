#!/bin/bash
: '
Notes:
    - This for if you ever want to try and implement ClamAV one day

    - The setup was so complicated and documentation so non-streamlined that this is as far as I got

    - I believe at this point you would just need to create a cronjob for the clamd service to scan

    - Also clamd reportedly takes up about 1Gb RAM at all times

    - Probably better not to use it at all and instead just use clamscan on a cron

DEVEL:
    https://docs.clamav.net/manual/Usage/Configuration.html
    this from 2016 but may identify a bug:
    https://www.ctrl.blog/entry/how-to-periodic-clamav-scan.html

    Standard package is clamav
    clamav-update package install the freshclam.conf file
    clamd package installs the daemon version (for auto-running scans)
    https://docs.clamav.net/manual/Installing/Packages.html#epel-fedora-rhel-and-centos
    https://docs.clamav.net/manual/Installing/Add-clamav-user.html#create-a-service-user-account-and-group

    References are to /etc/clamd.conf but it wont exist - you have to create a symbolic link from /etc/clamd.d/scan.conf to /etc/clamd.conf
'

dnf install cronie clamav clamav-update clamd

##### ClamAV setup
freshclam && freshclam

# create the service account
# https://docs.clamav.net/manual/Installing/Add-clamav-user.html
groupadd clamav
useradd --gid clamav --shell /bin/false --comment "Clam Antivirus" clamav

ln --symbolic /etc/clamd.d/scan.conf /etc/clamd.conf

# create freshclam log
# https://docs.clamav.net/manual/Usage/Configuration.html#freshclamconf
touch /var/log/freshclam.log
chmod 600 /var/log/freshclam.log
chown clamav /var/log/freshclam.log
sed -i 's|#UpdateLogFile /var/log/freshclam.log|UpdateLogFile /var/log/freshclam.log|g' /etc/freshclam.conf
sed -i 's|#LogFileMaxSize 2M|LogFileMaxSize 1G|g' /etc/freshclam.conf

# create clamd log
touch /var/log/clamd.scan
chmod 600 /var/log/clamd.scan
chown clamav /var/log/clamd.scan

# logging settings for clamd scanner
#sed -i 's|#LogFile /var/log/clamd.scan|LogFile /var/log/clamd.scan|g' /etc/clamd.conf
#sed -i 's|#LogTime yes|LogTime yes|g' /etc/clamd.conf
#sed -i 's|#LogFileMaxSize 2M|LogFileMaxSize 1G|g' /etc/clamd.conf
#sed -i 's|#ExtendedDetectionInfo yes|ExtendedDetectionInfo yes|g' /etc/clamd.conf

sed -e 's|^#LocalSocket |LocalSocket |g' \
    -e 's|^#LocalSocketGroup.*|LocalSocketGroup clamscan|g' \
    -e 's|^#LocalSocketMode |LocalSocketMode |g' \
    -e 's|^#FixStaleSocket |FixStaleSocket |g' \
    -e 's|^#ExcludePath |ExcludePath |g' \
    -e 's|#LogFile /var/log/clamd.scan|LogFile /var/log/clamd.scan|g' \
    -e 's|#LogTime yes|LogTime yes|g' \
    -e 's|#LogFileMaxSize 2M|LogFileMaxSize 1G|g' \
    -e 's|#ExtendedDetectionInfo yes|ExtendedDetectionInfo yes|g' \
    -i /etc/clamd.conf

# https://docs.clamav.net/manual/Installing/Add-clamav-user.html#after-installation-make-the-service-account-own-the-database-directory
chown --recursive clamav:clamav /usr/local/share/clamav
chown --recursive clamav:clamav /var/lib/clamav

# install freshclam update cron
# https://docs.clamav.net/manual/Usage/Configuration.html#freshclamconf
echo "3 * * * *   /usr/bin/freshclam --quiet" > newcron
crontab -u clamav newcron

# install clamd scanning cron


# SELinux settings
setsebool -P antivirus_can_scan_system 1
sudo setsebool -P clamd_use_jit 1