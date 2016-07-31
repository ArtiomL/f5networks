#!/usr/bin/python
# External Monitor - Azure HA
# Artiom Lichtenstein
# v0.1, 31/07/2016

import os, signal, sys, requests

# Remove IPv6/IPv4 compatibility prefix (LTM passes addresses in IPv6 format)
strIP = sys.argv[1].strip(':f')
strPort = sys.argv[2]
# ILX / Node.js VS IP
strIPNjs = sys.argv[3]
# PID file
strPFile = '_'.join(['/var/run/', os.path.basename(sys.argv[0]), strIP, strPort + '.pid'])

# Kill the last instance of this monitor if hung
if os.path.isfile(strPFile):
	# ADD LOG HERE
	try:
		os.kill(int(file(strPFile, 'r').read()), signal.SIGKILL)
	except OSError:
		pass

# Record current PID
file(strPFile, 'w').write(str(os.getpid()))

try:
	objResp = requests.head(''.join(['https://', strIP, ':', strPort]), verify = False)
except requests.exceptions.RequestException as e:
	#log e
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
