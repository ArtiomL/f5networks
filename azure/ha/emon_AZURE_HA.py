#!/usr/bin/python
# F5 Networks - External Monitor: Azure HA
# https://github.com/ArtiomL/f5networks
# Artiom Lichtenstein
# v0.9.1, 16/08/2016

from datetime import timedelta
import json
import os
import requests
from signal import SIGKILL
import socket
from subprocess import call
import sys
from time import time

# Log level to /var/log/ltm
intLogLevel = 2
strLogID = '[-v0.9.1-160816-] emon_AZURE_HA.py - '

# Azure RM REST API
class clsAREA:
	def __init__(self):
		self.strCFile = '/shared/tmp/scripts/azure/azure_ha.json'
		self.strMgmtURI = 'https://management.azure.com/'
		self.strAPIVer = '?api-version=2016-03-30'

	def funAbsURL(self):
		return self.strMgmtURI, self.strSubID, self.strRGName, self.strAPIVer

	def funURI(self, strMidURI):
		return self.strMgmtURI + strMidURI + self.strAPIVer

	def funBear(self):
		return { 'Authorization': 'Bearer %s' % self.strBearer }

objAREA = clsAREA()

# Logger command
strLogger = 'logger -p local0.info '

# Exit codes
class clsExCodes:
	def __init__(self):
		self.args = 8
		self.armAuth = 4

objExCodes = clsExCodes()


def funLog(intMesLevel, strMessage):
	if intLogLevel >= intMesLevel:
		lstCmd = strLogger.split(' ')
		lstCmd.append(strLogID + strMessage)
		call(lstCmd)


def funARMAuth():
	# Azure RM OAuth2
	global objAREA
	# Read external config file
	if not os.path.isfile(objAREA.strCFile):
		funLog(1, 'Credentials file: %s is missing!' % objAREA.strCFile)
		return 3

	try:
		# Open credentials file
		with open(objAREA.strCFile, 'r') as f:
			diCreds = json.load(f)
		# Read subscription and resource group
		objAREA.strSubID = diCreds['subID']
		objAREA.strRGName = diCreds['rgName']
		# Current epoch time
		intEpNow = int(time())
		# Check if Bearer token exists and can be reused
		if (set(('bearer', 'expiresOn')) <= set(diCreds) and int(diCreds['expiresOn']) - 60 > intEpNow):
			objAREA.strBearer = diCreds['bearer'].decode('base64')
			funLog(2, 'Reusing existing Bearer, it expires in %s' % str(timedelta(seconds=int(diCreds['expiresOn']) - intEpNow)))
			return 0

		# Read additional config parameters
		strTenantID = diCreds['tenantID']
		strAppID = diCreds['appID']
		strPass = diCreds['pass'].decode('base64')
		strEndPt = 'https://login.microsoftonline.com/%s/oauth2/token' % strTenantID
	except Exception as e:
		funLog(1, 'Invalid credentials file: %s' % objAREA.strCFile)
		return 2

	# Generate Bearer token
	objPayload = { 'grant_type': 'client_credentials', 'client_id': strAppID, 'client_secret': strPass, 'resource': objAREA.strMgmtURI }
	try:
		objAuthResp = requests.post(url=strEndPt, data=objPayload)
		dicAJSON = json.loads(objAuthResp.content)
		if 'access_token' in dicAJSON.keys():
			objAREA.strBearer = dicAJSON['access_token']
			diCreds['bearer'] = dicAJSON['access_token'].encode('base64')
			diCreds['expiresOn'] = dicAJSON['expires_on']
			with open(objAREA.strCFile, 'w') as f:
				f.write(json.dumps(diCreds, sort_keys=True, indent=4, separators=(',', ': ')))
			return 0

	except requests.exceptions.RequestException as e:
		funLog(2, str(e))
	return 1


def funLocIP(strRemIP):
	# Get local private IP
	objUDP = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
	# The .connect method doesn't generate any real network traffic for UDP (socket.SOCK_DGRAM)
	objUDP.connect((strRemIP, 0))
	return objUDP.getsockname()[0]


def funCurState(strLocIP, strPeerIP):
	# Get current ARM state for the local machine
	funLog(2, 'Current local private IP: %s, Resource Group: %s' % (strLocIP, objAREA.strRGName))
	# Construct loadBalancers URL
	strURL = '%ssubscriptions/%s/resourceGroups/%s/providers/Microsoft.Network/loadBalancers%s' % objAREA.funAbsURL()
	try:
		# Get LBAZ JSON
		objStatResp = requests.get(strURL, headers = objAREA.funBear())
		# Extract backend IP ID ([1:] at the end removes the first "/" char)
		strBEIPURI = json.loads(objStatResp.content)['value'][0]['properties']['backendAddressPools'][0]['properties']['backendIPConfigurations'][0]['id'][1:]
		# Get backend IP JSON
		objStatResp = requests.get(objAREA.funURI(strBEIPURI), headers = objAREA.funBear())
		# Extract private IP address
		strARMIP = json.loads(objStatResp.content)['properties']['privateIPAddress']
		funLog(2, 'Current private IP in Azure RM: %s' % strARMIP)
		if strARMIP == strLocIP:
			# This machine is already Active
			funLog(1, 'Current state: Active')
			return 'Active'

		elif strARMIP == strPeerIP:
			# The dead peer is listed as Active - failover required
			return 'Standby'

	except Exception as e:
		funLog(2, str(e))
	funLog(1, 'Current state: Unknown')
	return 'Unknown'


def funFailover():
	funLog(1, 'Azure failover...')


def main():
	funLog(1, '=' * 62)
	if len(sys.argv) < 3:
		funLog(1, 'Not enough arguments!')
		sys.exit(objExCodes.args)

	# Remove IPv6/IPv4 compatibility prefix (LTM passes addresses in IPv6 format)
	strRIP = sys.argv[1].strip(':f')
	strRPort = sys.argv[2]
	# PID file
	strPFile = '_'.join(['/var/run/', os.path.basename(sys.argv[0]), strRIP, strRPort + '.pid'])
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

	# Health monitor
	try:
		objResp = requests.head(''.join(['https://', strRIP, ':', strRPort]), verify = False)
		if objResp.status_code == 200:
			os.unlink(strPFile)
			# Any standard output stops the script from running. Clean up any temporary files before the standard output operation
			funLog(2, 'Peer: %s is up.' % strRIP)
			print 'UP'
			sys.exit()

	except requests.exceptions.RequestException as e:
		funLog(2, str(e))

	# Peer down, ARM action required
	funLog(1, 'Peer down, ARM action required.')
	if funARMAuth() != 0:
		funLog(1, 'ARM Auth Error!')
		os.unlink(strPFile)
		sys.exit(objExCodes.armAuth)

	# ARM Auth OK
	funLog(2, 'ARM Bearer: %s' % objAREA.strBearer)

	if funCurState(funLocIP(strRIP), strRIP) == 'Standby':
		funLog(1, 'We\'re Standby in ARM, Active peer down. Trying to failover...')
		funFailover()

	os.unlink(strPFile)
	sys.exit(1)

if __name__ == '__main__':
	main()
