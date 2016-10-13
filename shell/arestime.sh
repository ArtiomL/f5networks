#!/bin/bash
# F5 Networks - Auto-Restart ntpd
# https://github.com/ArtiomL/f5networks
# Artiom Lichtenstein
# v1.2, 30/07/2016

str_NTPD_STATUS=`tmsh show /sys service ntpd | awk '{print $NF}' | cut -d'.' -f1`
if [ "$str_NTPD_STATUS"  != "running" ]; then
	str_TO_LOG=`tmsh restart /sys service ntpd`
	logger -p local0.info "arestime.sh - $str_TO_LOG"
fi
