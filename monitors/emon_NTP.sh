#!/bin/bash
# External Monitor - NTP
# Artiom Lichtenstein
# v1.1, 20/01/2016

# remove IPv6/IPv4 compatibility prefix (LTM passes addresses in IPv6 format)
IP=`echo ${1} | sed 's/::ffff://'`

PIDFILE="/var/run/`basename ${0}`.${IP}_${PORT}.pid"
# kill of the last instance of this monitor if hung and log current pid
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
