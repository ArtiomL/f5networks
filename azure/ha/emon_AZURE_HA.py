#!/usr/bin/python
# F5 Networks - External Monitor: Azure HA
# https://github.com/ArtiomL/f5networks
# Artiom Lichtenstein
# v0.4, 04/08/2016

import json
import os
import requests
from signal import SIGKILL
from subprocess import call
import sys

# Log level to /var/log/ltm
intLogLevel = 2
strLogID = '[-v0.4.160804-] emon_AZURE_HA.py - '

# Azure RM Auth
strSubs = '<Subscription ID>'
strTenantID = '<TenantID>'
strAppID = '<App ID>'
strPass = '<Password>'
strTokenEP = 'https://login.microsoftonline.com/%s/oauth2/token' % strTenantID
strMgmtURI = 'https://management.azure.com/'
strBearer = ''

# Logger command
strLogger = 'logger -p local0.error '

class clsExCodes:
	intArgs = 8
	intArmAuth = 4

def funLog(intMesLevel, strMessage):
	if intLogLevel >= intMesLevel:
		lstCmd = strLogger.split(' ')
		lstCmd.append(strLogID + strMessage)
		call(lstCmd)

def funARMAuth():
	objPayload = { 'grant_type': 'client_credentials', 'client_id': strAppID, 'client_secret': strPass, 'resource': strMgmtURI }
	try:
		objAuthResp = requests.post(url=strTokenEP, data=objPayload)
		dicAJSON = json.loads(objAuthResp.content)
		if 'access_token' in dicAJSON.keys():
			return dicAJSON['access_token']
	except requests.exceptions.RequestException as e:
		funLog(2, str(e))
	return 'BearERROR'

def funCurState():
	funLog(1, 'Current local state: ')

def funFailover():
	funLog(1, 'Azure failover...')

def main():
	if len(sys.argv) < 3:
		funLog(1, 'Not enough arguments!')
		sys.exit(clsExCodes.intArgs)

	# Remove IPv6/IPv4 compatibility prefix (LTM passes addresses in IPv6 format)
	strIP = sys.argv[1].strip(':f')
	strPort = sys.argv[2]
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

	# Health Monitor
	try:
		objResp = requests.head(''.join(['https://', strIP, ':', strPort]), verify = False)
		if objResp.status_code == 200:
			os.unlink(strPFile)
			# Any standard output stops the script from running. Clean up any temporary files before the standard output operation
			funLog(2, 'Peer: ' + strIP + ' is up.' )
			print 'UP'
			sys.exit()
	except requests.exceptions.RequestException as e:
		funLog(2, str(e))

	# Peer down, ARM action needed
	global strBearer
	strBearer = funARMAuth()
	funLog(2, 'ARM Bearer: ' + strBearer)
	if strBearer == 'BearERROR':
		funLog(1, 'ARM Auth Error!')
		sys.exit(clsExCodes.intArmAuth)

	funCurState()
	funFailover()

	os.unlink(strPFile)
	sys.exit(1)

if __name__ == '__main__':
	main()
