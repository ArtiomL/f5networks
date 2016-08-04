#!/usr/bin/python
# F5 Networks - External Monitor: Azure HA
# https://github.com/ArtiomL/f5networks
# Artiom Lichtenstein
# v0.5, 05/08/2016

import json
import os
import requests
from signal import SIGKILL
from subprocess import call
import sys

# Log level to /var/log/ltm
intLogLevel = 2
strLogID = '[-v0.5.160805-] emon_AZURE_HA.py - '

# Azure RM REST Auth
class clsAA:
	strCFile = '/shared/tmp/azure/azure_ha.json'
	strMgmtURI = 'https://management.azure.com/'

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
	global clsAA
	if not os.path.isfile(clsAA.strCFile):
		funLog(1, 'Credentials file: %s is missing!' % clsAA.strCFile)
		return 3

	try:
		with open(clsAA.strCFile, 'r') as f:
			diCreds = json.load(f)
		clsAA.strSubID = diCreds['subID']
		strTenantID = diCreds['tenantID']
		strAppID = diCreds['appID']
		strPass = diCreds['pass']
		strEndPt = 'https://login.microsoftonline.com/%s/oauth2/token' % strTenantID
	except Exception as e:
		funLog(1, 'Invalid credentials file: %s' % clsAA.strCFile)
		return 2

	objPayload = { 'grant_type': 'client_credentials', 'client_id': strAppID, 'client_secret': strPass, 'resource': clsAA.strMgmtURI }
	try:
		objAuthResp = requests.post(url=strEndPt, data=objPayload)
		dicAJSON = json.loads(objAuthResp.content)
		if 'access_token' in dicAJSON.keys():
			clsAA.strBearer = dicAJSON['access_token']
			return 0

	except requests.exceptions.RequestException as e:
		funLog(2, str(e))
	return 1

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

	funLog(2, 'PIDFile: %s, PID: %s' % (strPFile, strPID))

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
			funLog(2, 'Peer: %s is up.' % strIP)
			print 'UP'
			sys.exit()

	except requests.exceptions.RequestException as e:
		funLog(2, str(e))

	# Peer down, ARM action needed
	if funARMAuth() != 0:
		funLog(1, 'ARM Auth Error!')
		os.unlink(strPFile)
		sys.exit(clsExCodes.intArmAuth)

	funLog(2, 'ARM Bearer: %s' % clsAA.strBearer)

	funCurState()
	funFailover()

	os.unlink(strPFile)
	sys.exit(1)

if __name__ == '__main__':
	main()
