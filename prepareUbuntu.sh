#!/usr/bin/env bash

#FIXME: write runcmd function and check RTC of each command


# fix docker issue #1024
dpkg-divert --local --rename --add /sbin/initctl
ln -sf /bin/true /sbin/initctl

# https://bugs.launchpad.net/launchpad/+bug/974584
dpkg-divert --local --rename --add /usr/bin/ischroot
ln -sf /bin/true /usr/bin/ischroot

# enable multiverse repository
sed -i 's/^#\s*\(deb.*multiverse\)$/\1/g' /etc/apt/sources.list

# update package list
apt-get -y update

# do a update on all installed packages
apt-get -y --no-install-recommends dist-upgrade

# installing required packages
apt-get install -y --no-install-recommends wget curl ca-certificates vim python3 syslog-ng syslog-ng-core supervisor cron logrotate


# syslog-ng: can't access /proc/kmsg. https://groups.google.com/forum/#!topic/docker-user/446yoB0Vx6w
sed -i -E 's/^(\s*)system\(\);/\1unix-stream("\/dev\/log");/' /etc/syslog-ng/syslog-ng.conf


# clean up after
apt-get -y clean
apt-get -y autoremove
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

    
mkdir /etc/my_runonce
mkdir /etc/my_runalways
mkdir /etc/container_environment
mkdir /etc/workaround-docker-2267

# setup logfile to be writable by all
touch /var/log/startup.log
chmod 666 /var/log/startup.log


