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
