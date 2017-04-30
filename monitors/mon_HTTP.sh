#!/bin/bash
# F5 Networks - Monitor: HTTP
# https://github.com/ArtiomL/f5networks
# Artiom Lichtenstein
# v1.0, 30/04/2017

tmsh
load /sys config from-terminal merge
# Enter configuration. Press CTRL-D to submit or CTRL-C to cancel.
ltm monitor http mon_HTTP {
	adaptive disabled
	defaults-from http
	destination *:*
	interval 5
	ip-dscp 0
	recv "200 OK"
	recv-disable none
	send "HEAD /monitor.php HTTP/1.1\r\nHost: www.example.com\r\nCache-Control: no-cache\r\nPragma: no-cache\r\nConnection: close\r\n\r\n"
	time-until-up 0
	timeout 16
}
