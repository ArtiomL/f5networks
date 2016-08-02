#!/usr/bin/python
# F5 Networks - External Monitor: Azure HA
# https://github.com/ArtiomL/f5networks
# Artiom Lichtenstein
# v0.3, 02/08/2016

import os
import requests
from signal import SIGKILL
from subprocess import call
import sys

# Log level to /var/log/ltm
intLogLevel = 2
strLogID = '[-v0.3.160802-] emon_AZURE_HA.py - '

# Logger command
strLogger = 'logger -p local0.error '

def funLog(intMesLevel, strMessage):
	if intLogLevel >= intMesLevel:
		call((strLogger + strLogID + strMessage).split(' '))

class clsExCodes:
	args = 4

if len(sys.argv) < 4:
	funLog(1, 'Not enough arguments, ILX / Node.js VS IP is missing?')
	sys.exit(clsExCodes.args)

# Remove IPv6/IPv4 compatibility prefix (LTM passes addresses in IPv6 format)
strIP = sys.argv[1].strip(':f')
strPort = sys.argv[2]
# ILX / Node.js VS IP
strIPNjs = sys.argv[3]
# PID file
strPFile = '_'.join(['/var/run/', os.path.basename(sys.argv[0]), strIP, strPort + '.pid'])
# PID
strPID = str(os.getpid())

funLog(2, strPFile + ' ' + strPID)

# Kill the last instance of this monitor if hung
if os.path.isfile(strPFile):
	try:
		os.kill(int(file(strPFile, 'r').read()), SIGKILL)
		funLog(1, 'Killed the last hung instance of this monitor.')
	except OSError:
		pass

# Record current PID
file(strPFile, 'w').write(str(os.getpid()))

try:
	objResp = requests.head(''.join(['https://', strIP, ':', strPort]), verify = False)
except requests.exceptions.RequestException as e:
	funLog(1, str(e))
	sys.exit(3)

if objResp.status_code == 200:
	os.unlink(strPFile)
	# Any standard output stops the script from running. Clean up any temporary files before the standard output operation
	print 'UP'
	sys.exit()
else:
	try:
		objResp = requests.head('http://' + strIPNjs)
	except requests.exceptions.RequestException as e:
		# log e
		sys.exit(2)

os.unlink(strPFile)
sys.exit(1)
