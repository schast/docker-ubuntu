#!/usr/bin/env bash

function execAndcheckForError {
    local CMD="${*}"
    ${CMD}
    local RTC="${?}"
    if [ "${RTC}" != "0"  ]; then
        echo "[ERROR]: an error occured on command (${CMD}), returncode (${RTC})"
        exit ${RTC}
    fi
}


# fix docker issue #1024
execAndcheckForError "dpkg-divert --local --rename --add /sbin/initctl"
execAndcheckForError "ln -sf /bin/true /sbin/initctl"

# https://bugs.launchpad.net/launchpad/+bug/974584
execAndcheckForError "dpkg-divert --local --rename --add /usr/bin/ischroot"
execAndcheckForError "ln -sf /bin/true /usr/bin/ischroot"

# enable multiverse repository
sed -i 's/^#\s*\(deb.*multiverse\)$/\1/g' /etc/apt/sources.list

# update package list
execAndcheckForError "apt-get -y update"

# do a update on all installed packages
#execAndcheckForError "apt-get -y --no-install-recommends dist-upgrade"
execAndcheckForError "apt-get -y dist-upgrade"

# installing required packages
execAndcheckForError "apt-get install -y --no-install-recommends wget curl ca-certificates vim python3 syslog-ng syslog-ng-core supervisor cron logrotate tzdata"

# syslog-ng: can't access /proc/kmsg. https://groups.google.com/forum/#!topic/docker-user/446yoB0Vx6w
sed -i -E 's/^(\s*)system\(\);/\1unix-stream("\/dev\/log");/' /etc/syslog-ng/syslog-ng.conf


# clean up after
execAndcheckForError "apt-get -y clean"
execAndcheckForError "apt-get -y autoremove"
execAndcheckForError "rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*"

execAndcheckForError "mkdir -p /etc/my_runonce"
execAndcheckForError "mkdir -p /etc/my_runalways"
execAndcheckForError "mkdir -p /etc/container_environment"
execAndcheckForError "mkdir -p /etc/workaround-docker-2267"

# setup logfile to be writable by all
execAndcheckForError "touch /var/log/startup.log"
execAndcheckForError "chmod 666 /var/log/startup.log"


