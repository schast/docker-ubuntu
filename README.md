## Docker Ubuntu Image with a working init process and syslog
 [![Docker Hub; schast/docker-ubuntu](https://img.shields.io/badge/dockerhub-schast%2Fubuntu-green.svg)](https://registry.hub.docker.com/u/schast/ubuntu)
 [![](https://badge.imagelayers.io/schast/ubuntu:14.04.svg)](https://imagelayers.io/?images=schast/ubuntu:14.04 'Get your own badge on imagelayers.io')

This is a Ubuntu docker image with a working init process and syslog

### Why use this image

The unix process ID 1 is the process to receive the SIGTERM signal when you execute a

	docker stop <container ID>

if the container has the command `CMD ["bash"]` then bash process will get the SIGTERM signal and terminate.
All other processes running on the system will just stop without the possibility to shutdown correclty

### my_init init script

In this container i have a scipt that handles the init process an uses the [supervisor system](http://supervisord.org/index.html) to start
the daemons to run and also catch signals (SIGTERM) to shutdown all processes started by supervisord. This is a modified version of
an init script made by Phusion. I've modified it to use supervisor in stead of runit. There are also two directories to run scripts
before any daemon is started.

#### Run script once /etc/my_runonce

All executable in this directory is run at start, after completion the script is removed from the directory

#### Run script every start /etc/my_runalways

All executable in this directory is run at every start of the container, ie, at `docker run` and `docker start`

#### Permanent output to docker log when starting container

Each time the container is started the content of the file /tmp/startup.log is displayed so if your startup scripts generate
vital information to be shown please add that information to that file. This information can be retrieved anytime by
executing `docker logs <container id>`

### cron daemon

In many cases there are som need of things happening att given intervalls, default no cron processs is started
in the standard ubuntu image. In this image cron is running together with logrotate to stop the logdfiles to be
to big on log running containers.

### syslog-ng

No all services works without a syslog daemon, if you don't have one running those messages is lost in space,
all messages sent via the syslog daemon is saved in /var/log/syslog

### Docker fixes

Also there are fixed (besideds the init process) assosiated with running ubuntu inside a docker container.

### New commands autostarted by supervisord

To add other processes to run automaticly, add a file ending with .conf  in /etc/supervisor/conf.d/
with a layout like this (/etc/supervisor/conf.d/myprogram.conf)

	[program:myprogram]
	command=/usr/bin/myprogram

`myprogram` is the name of this process when working with supervisctl.

Output logs std and error is found in /var/log/supervisor/ and the files begins with the <defined name><-stdout|-stderr>superervisor*.log

For more settings please consult the [manual FOR supervisor](http://supervisord.org/configuration.html#program-x-section-settings)

#### starting commands from /etc/init.d/ or commands that detach with my_service

The supervisor process assumes that a command that ends has stopped so if the command detach it will try to restart it. To work around this
problem I have written an extra command to be used for these commands. First you have to make a normal start/stop command and place it in
the /etc/init.d that starts the program with

	/etc/init.d/command start or
	service command start

and stops with

        /etc/init.d/command stop or
        service command stop

Configure the configure-file (/etc/supervisor/conf.d/myprogram.conf)

	[program:myprogram]
	command=/sbin/my_service myprogram

There is an optional parameter, to run a script after a service has start, e.g to run the script /usr/local/bin/postproc.sh av myprogram is started

        [program:myprogram]
        command=/sbin/my_service myprogram /usr/local/bin/postproc.sh

### Output information to docker logs

The console output is owned by the my_init process so any output from commands woun't show in the docker log. To send a text from any command, either
at startup och during run, append the output to the file /var/log/startup.log, e.g sending specific text to log

	echo "Application is finished" >> /var/log/startup.log

or output from script

	/usr/local/bin/myscript >> /var/log/startlog.log


	> docker run -d --name ubuntu schast/ubuntu
	> docker logs ubuntu
	*** open logfile
	*** Run files in /etc/my_runonce/
	*** Run files in /etc/my_runalways/
	*** Running /etc/rc.local...
	*** Booting supervisor daemon...
	*** Supervisor started as PID 9
	2015-08-04 11:34:06,763 CRIT Set uid to user 0
	*** Started processes via Supervisor......
	crond                            RUNNING    pid 13, uptime 0:00:04
	syslog-ng                        RUNNING    pid 12, uptime 0:00:04

	> docker exec ubuntu sh -c 'echo "Testmessage to log" >> /var/log/startup.log'
	> docker logs ubuntu
        *** open logfile
        *** Run files in /etc/my_runonce/
        *** Run files in /etc/my_runalways/
        *** Running /etc/rc.local...
        *** Booting supervisor daemon...
        *** Supervisor started as PID 9
        2015-08-04 11:34:06,763 CRIT Set uid to user 0
        *** Started processes via Supervisor......
        crond                            RUNNING    pid 13, uptime 0:00:04
        syslog-ng                        RUNNING    pid 12, uptime 0:00:04

	*** Log: Testmessage to log
        >
### Added som normaly used commands

There are a number of commands that most uses and adds to their build, in this build I've added som commonly used packages

Extra included packages are

- wget
- curl
- ca-certificates
- vim
- python3

### Installation

Test the container and remove on exit:

	docker run --rm --name ubuntuTest --memory="768m" schast/docker-ubuntu:14.04

	docker run -ti schast/ubuntu
	*** open logfile
	*** Run files in /etc/my_runonce/
	*** Run files in /etc/my_runalways/
	*** Running /etc/rc.local...
	*** Booting supervisor daemon...
	*** Supervisor started as PID 8
	2016-01-04 18:25:30,618 CRIT Set uid to user 0
	*** Started processes via Supervisor......
	crond                            RUNNING    pid 12, uptime 0:00:04
	syslog-ng                        RUNNING    pid 11, uptime 0:00:04

pressing a CTRL-C in that window or running `docker stop <container ID/Name>` will generate the following output

	*** Shutting down supervisor daemon (PID 8)...
	*** Killing all processes...

Connect to running container:

	docker exec -it <container ID/Name> /bin/bash


Run container as a daemon:

	docker run -d --name myUbuntu --hostname myHostname.myDomain \
		--memory="768m" \
		schast/docker-ubuntu:14.04


you can the restart that container with

	docker start <container ID/Name>


### Build own Image

	git clone https://github.com/schast/docker-ubuntu.git docker-ubuntu.git
	cd docker-ubuntu.git
	docker build --force-rm -f Dockerfile_14.04 -t YourName/docker-ubuntu:14.04 .


### TAGs

This image contains following versions of Ubuntu (schast/ubuntu:<tag>):
- latest -  this gives the latest LTS version (14.04)
- 14.04  -  this gives the 14.04 LTS version
- 15.10  -  this gives the 15.10 version
- 16.04  -  this gives the 16.04 LTS version (beta)


### Forked from
[nimmis/docker-ubuntu](https://github.com/nimmis/docker-ubuntu/)

[phusion/baseimage-docker](https://github.com/phusion/baseimage-docker)



