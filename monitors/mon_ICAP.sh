#!/bin/bash
# F5 Networks - Monitor: ICAP
# https://github.com/ArtiomL/f5networks
# Artiom Lichtenstein
# v1.1, 21/07/2016

tmsh list /ltm monitor http mon_ICAP
ltm monitor http mon_ICAP {
	adaptive disabled
	defaults-from http
	destination *:*
	interval 5
	ip-dscp 0
	recv "ICAP/1.0 200 OK"
	send "OPTIONS icap://ICAPSRV ICAP/1.0\r\nConnection: close\r\n\r\n"
	time-until-up 0
	timeout 16
}
