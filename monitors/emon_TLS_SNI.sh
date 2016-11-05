#!/bin/bash
# F5 Networks - External Monitor: TLS SNI
# https://github.com/ArtiomL/f5networks
# Artiom Lichtenstein
# v1.3, 05/11/2016

# This monitor expects the following
# Variables:
# 	HOST - the hostname of the SNI-enabled site
# 	URI  - the request URI
# 	RECV - the expected response
# Arguments:
# 	${3} - a unique ID for a distinctive PID filename (e.g. pool name)

# remove IPv6/IPv4 compatibility prefix (LTM passes addresses in IPv6 format)
IP=`echo ${1} | sed 's/::ffff://'`
PORT=${2}
EMUID=${3}

PIDFILE="/var/run/`basename ${0}`.${IP}_${PORT}_${EMUID}.pid"
# kill the last instance of this monitor if hung and log current PID
if [ -f $PIDFILE ]; then
	logger -p local0.error "emon_TLS_SNI - Previous instance runtime exceeded. Killing ${IP} ${PORT} ${EMUID} for SNI: $HOST"
	kill -9 `cat $PIDFILE` > /dev/null 2>&1
fi
echo "$$" > $PIDFILE

# send the request and check for the expected response
curl-apd -s -k -1 -i -X HEAD --resolve $HOST:$PORT:$IP https://$HOST$URI -H "Connection: close" -m 3 | grep "$RECV" > /dev/null 2>&1

if [ $? -eq 0 ]; then
	rm -f $PIDFILE
	# Any standard output stops the script from running. Clean up any temporary files before the standard output operation
	echo "UP"
	exit 0
fi

rm -f $PIDFILE
exit 1
