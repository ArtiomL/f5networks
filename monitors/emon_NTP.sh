#!/bin/bash
# F5 Networks - External Monitor: NTP
# https://github.com/ArtiomL/f5networks
# Artiom Lichtenstein
# v1.3, 17/07/2016

# Remove IPv6/IPv4 compatibility prefix (LTM passes addresses in IPv6 format)
IP=`echo ${1} | sed 's/::ffff://'`

PIDFILE="/var/run/`basename ${0}`.${IP}_${PORT}.pid"
# Kill the last instance of this monitor if hung and log current PID
if [ -f $PIDFILE ]; then
	logger -p local0.error "emon_NTP - Previous instance runtime exceeded. Killing for ${IP}."
	kill -9 `cat $PIDFILE` > /dev/null 2>&1
fi
echo "$$" > $PIDFILE

ntpdate -q $IP > /dev/null 2>&1

if [ $? -eq 0 ]; then
	rm -f $PIDFILE
	# Any standard output stops the script from running. Clean up any temporary files before the standard output operation
	echo "UP"
	exit 0
fi

rm -f $PIDFILE
exit 1
