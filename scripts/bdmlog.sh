#!/bin/bash
# F5 Networks - bd Memory Logger
# https://github.com/ArtiomL/f5networks
# Artiom Lichtenstein
# v1.0.0, 26/10/2017

strTop=$(top -cbn1 | grep '[.]/bd ' | awk '{print $6}')
strLog=$(cat /ts/log/bd.log | grep RSS | tail -n1)

logger -p local0.info "bdmlog.sh - top RES: [$strTop], bd.log: $strLog"
