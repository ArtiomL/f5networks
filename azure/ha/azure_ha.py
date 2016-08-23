#!/usr/bin/env python
# F5 Networks - Azure HA
# https://github.com/ArtiomL/f5networks
# Artiom Lichtenstein
# v0.9.6, 23/08/2016

from argparse import ArgumentParser
import atexit
from datetime import timedelta
import json
import os
import requests
from signal import SIGKILL
import socket
from subprocess import call
import sys
from time import time

__author__ = 'Artiom Lichtenstein'
__license__ = 'MIT'
__version__ = '0.9.6'

# PID file
strPFile = ''

# Log level to /var/log/ltm
intLogLevel = 0
strLogMethod = 'log'
strLogID = '[-v%s-160823-] %s - ' % (__version__, os.path.basename(sys.argv[0]))

# Logger command
strLogger = 'logger -p local0.'

# Azure RM REST API
class clsAREA(object):
	def __init__(self):
		self.strCFile = '/shared/tmp/scripts/azure/azure_ha.json'
		self.strMgmtHost = 'https://management.azure.com/'
		self.strAPIVer = '?api-version=2016-03-30'

	def funAbsURL(self):
		return self.strMgmtHost, self.strSubID, self.strRGName, self.strAPIVer

	def funURI(self, strMidURI):
		return self.strMgmtHost + strMidURI + self.strAPIVer

	def funBear(self):
		return { 'Authorization': 'Bearer %s' % self.strBearer }

	def funSwapNICs(self):
		# Use temp (short name) list (lst[0] = nicF5A, lst[1] = nicF5B)
		lst = self.lstF5NICs
		# If old NIC ends with B, reverse the list to replace B with A. Otherwise replace A with B
		if self.strCurNICURI.endswith(lst[1]):
			lst.reverse()
		funLog(2, 'Old NIC: %s, New NIC: %s' % (lst[0], lst[1]))
		return self.funURI(self.strCurNICURI.replace(lst[0], lst[1]))

objAREA = clsAREA()

# Exit codes
class clsExCodes(object):
	def __init__(self):
		self.rip = 6
		self.armAuth = 4

objExCodes = clsExCodes()


def funLog(intMesLevel, strMessage, strSeverity = 'info'):
	if intLogLevel >= intMesLevel:
		if strLogMethod == 'stdout':
			print strMessage
		else:
			lstCmd = (strLogger + strSeverity).split(' ')
			lstCmd.append(strLogID + strMessage)
			call(lstCmd)


def funARMAuth():
	# Azure RM OAuth2
	global objAREA
	# Read external config file
	if not os.path.isfile(objAREA.strCFile):
		funLog(1, 'Credentials file: %s is missing. (use azure_ad_app.ps1?)' % objAREA.strCFile, 'err')
		return 3

	try:
		# Open the credentials file
		with open(objAREA.strCFile, 'r') as f:
			diCreds = json.load(f)
		# Read and store subscription and resource group
		objAREA.strSubID = diCreds['subID']
		objAREA.strRGName = diCreds['rgName']
		# Read and store F5 VMs' NICs
		objAREA.lstF5NICs = [diCreds['nicF5A'], diCreds['nicF5B']]
		# Current epoch time
		intEpNow = int(time())
		# Check if Bearer token exists (in credentials file) and whether it can be reused (expiration with 1 minute time skew)
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
		funLog(1, 'Invalid credentials file: %s' % objAREA.strCFile, 'err')
		funLog(2, repr(e), 'err')
		return 2

	# Generate new Bearer token
	diPayload = { 'grant_type': 'client_credentials', 'client_id': strAppID, 'client_secret': strPass, 'resource': objAREA.strMgmtHost }
	try:
		objHResp = requests.post(url=strEndPt, data=diPayload)
		diAuth = json.loads(objHResp.content)
		if 'access_token' in diAuth.keys():
			# Successfully received new token
			objAREA.strBearer = diAuth['access_token']
			# Write the new token and its expiration epoch into the credentials file
			diCreds['bearer'] = objAREA.strBearer.encode('base64')
			diCreds['expiresOn'] = diAuth['expires_on']
			with open(objAREA.strCFile, 'w') as f:
				f.write(json.dumps(diCreds, sort_keys=True, indent=4, separators=(',', ': ')))
			return 0

	except requests.exceptions.RequestException as e:
		funLog(2, repr(e), 'err')
	return 1


def funRunAuth():
	# Run and check funARMAuth() exit code
	if funARMAuth() != 0:
		funLog(1, 'ARM Auth Error!', 'err')
		sys.exit(objExCodes.armAuth)

	# ARM Auth OK
	funLog(3, 'ARM Bearer: %s' % objAREA.strBearer)
	return 0


def funLocIP(strRemIP):
	# Get local private IP
	objUDP = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
	# The .connect method doesn't generate any real network traffic for UDP (socket.SOCK_DGRAM)
	objUDP.connect((strRemIP, 0))
	return objUDP.getsockname()[0]


def funCurState(strLocIP = '127.0.0.1', strPeerIP = '127.0.0.1'):
	# Get current ARM state for the local machine
	global objAREA
	funLog(2, 'Current local private IP: %s, Resource Group: %s' % (strLocIP, objAREA.strRGName))
	# Construct loadBalancers URL
	strLBURL = '%ssubscriptions/%s/resourceGroups/%s/providers/Microsoft.Network/loadBalancers%s' % objAREA.funAbsURL()
	diHeaders = objAREA.funBear()
	try:
		# Get LBAZ JSON
		objHResp = requests.get(strLBURL, headers = diHeaders)
		# Store the backend pool JSON (for funFailover)
		objAREA.diBEPool = json.loads(objHResp.content)['value'][0]['properties']['backendAddressPools']
		# Extract backend IP ID ([1:] at the end removes the first "/" char)
		strBEIPURI = objAREA.diBEPool[0]['properties']['backendIPConfigurations'][0]['id'][1:]
		# Store the URI for NIC currently in the backend pool (for funFailover)
		objAREA.strCurNICURI = strBEIPURI.split('/ipConfigurations')[0]
		# Get backend IP JSON
		objHResp = requests.get(objAREA.funURI(strBEIPURI), headers = diHeaders)
		# Extract private IP address
		strARMIP = json.loads(objHResp.content)['properties']['privateIPAddress']
		funLog(2, 'Current private IP in Azure RM: %s' % strARMIP)
		if strARMIP == strLocIP:
			# This machine is already Active
			funLog(1, 'Current state: Active')
			return 'Active'

		elif strARMIP == strPeerIP:
			# The dead peer is listed as Active - failover required
			return 'Standby'

	except Exception as e:
		funLog(2, repr(e), 'err')
	funLog(1, 'Current state: Unknown', 'warning')
	return 'Unknown'


def funOpStatus(objHResp):
	# Check Azure Async Operation status
	strStatus = 'InProgress'
	# The Azure-AsyncOperation header has the full operation URL
	strOpURL = objHResp.headers['Azure-AsyncOperation']
	funLog(2, 'ARM Async Operation, x-ms-request-id: %s' % objHResp.headers['x-ms-request-id'])
	funLog(3, 'Op URL: %s' % strOpURL)
	diHeaders = objAREA.funBear()
	funLog(2, 'ARM Async Operation Status: %s' % strStatus)
	while strStatus == 'InProgress':
		try:
			strStatus = json.loads(requests.get(strOpURL, headers = diHeaders).content)['status']
		except Exception as e:
			funLog(2, repr(e), 'err')
			break
	funLog(1, strStatus)
	return strStatus


def funFailover():
	diHeaders = objAREA.funBear()
	try:
		strOldNICURL = objAREA.funURI(objAREA.strCurNICURI)
	except AttributeError as e:
		funLog(1, 'No NICs in the Backend Pool!', 'warning')
		funLog(2, repr(e), 'err')
		return 3

	strNewNICURL = objAREA.funSwapNICs()
	try:
		# Get the JSON of the NIC currently in the backend pool
		objHResp = requests.get(strOldNICURL, headers = diHeaders)
		diOldNIC = json.loads(objHResp.content)
		# Remove the LB backend pool from that JSON
		diOldNIC['properties']['ipConfigurations'][0]['properties']['loadBalancerBackendAddressPools'] = []
		# Get the JSON of the new NIC to be added to the backend pool
		objHResp = requests.get(strNewNICURL, headers = diHeaders)
		diNewNIC = json.loads(objHResp.content)
		# Remove the existing backend IP ID from the LB backend pool JSON (stored in funCurState)
		objAREA.diBEPool[0]['properties']['backendIPConfigurations'] = []
		# Add the LB backend pool to the new NIC JSON
		diNewNIC['properties']['ipConfigurations'][0]['properties']['loadBalancerBackendAddressPools'] = objAREA.diBEPool
		# Add Content-Type to HTTP headers
		diHeaders['Content-Type'] = 'application/json'
		# Update the new NIC (add it to the backend pool)
		objHResp = requests.put(strNewNICURL, headers = diHeaders, data = json.dumps(diNewNIC))
		funLog(1, 'Adding the new NIC to LBAZ BE Pool...')
		if funOpStatus(objHResp) != 'Succeeded':
			return 2

		# Update the old NIC (remove it from the backend pool)
		objHResp = requests.put(strOldNICURL, headers = diHeaders, data = json.dumps(diOldNIC))
		funLog(1, 'Removing the old NIC from LBAZ BE Pool... ')
		if funOpStatus(objHResp) == 'Succeeded':
			return 0

	except Exception as e:
		funLog(2, repr(e), 'err')
	return 1


def funArgParse():
	objArgParse = ArgumentParser(
		description = 'F5 High Availability in Microsoft Azure',
		epilog = 'https://github.com/ArtiomL/f5networks/tree/master/azure/ha')
	objArgParse.add_argument('-a', help ='test Azure RM authentication and exit', action = 'store_true', dest = 'auth')
	objArgParse.add_argument('-f', help ='force failover', action = 'store_true', dest = 'fail')
	objArgParse.add_argument('-l', help ='set log level (default: 0)', choices = [0, 1, 2, 3], type = int, dest = 'log')
	objArgParse.add_argument('-s', help ='log to stdout (instead of /var/log/ltm)', action = 'store_true', dest = 'sout')
	objArgParse.add_argument('-v', action ='version', version = '%(prog)s v' + __version__)
	objArgParse.add_argument('IP', help = 'peer IP address (required in monitor mode)', nargs = '?')
	objArgParse.add_argument('PORT', help = 'peer HTTPS port (default: 443)', type = int, nargs = '?', default = 443)
	return objArgParse.parse_args()


def main():
	global strLogMethod, intLogLevel, strPFile
	objArgs = funArgParse()
	if objArgs.sout or objArgs.auth:
		strLogMethod = 'stdout'
	if objArgs.log > 0:
		intLogLevel = objArgs.log
	if objArgs.auth:
		sys.exit(funRunAuth())

	if objArgs.fail:
		funRunAuth()
		funCurState()
		sys.exit(funFailover())

	funLog(1, '=' * 62)

	try:
		# Remove IPv6/IPv4 compatibility prefix (LTM passes addresses in IPv6 format)
		strRIP = objArgs.IP.strip(':f')
		# Verify first positional argument is a valid (peer) IP address
		socket.inet_pton(socket.AF_INET, strRIP)
	except (AttributeError, socket.error) as e:
		funLog(0, 'No valid peer IP!', 'err')
		funLog(2, repr(e), 'err')
		sys.exit(objExCodes.rip)

	# Verify second positional argument is a valid TCP port, set to 443 if missing
	strRPort = objArgs.PORT
	if not 0 < strRPort <= 65535:
		funLog(1, 'No valid peer TCP port, using 443', 'warning')
		strRPort = '443'

	# PID file
	strPFile = '_'.join(['/var/run/', os.path.basename(sys.argv[0]), strRIP, strRPort + '.pid'])
	# PID
	strPID = str(os.getpid())

	funLog(2, 'PIDFile: %s, PID: %s' % (strPFile, strPID))

	# Kill the last instance of this monitor if hung
	if os.path.isfile(strPFile):
		try:
			os.kill(int(file(strPFile, 'r').read()), SIGKILL)
			funLog(1, 'Killed the last hung instance of this monitor.', 'warning')
		except OSError:
			pass

	# Record current PID
	file(strPFile, 'w').write(str(os.getpid()))

	# Health monitor
	try:
		objHResp = requests.head(''.join(['https://', strRIP, ':', strRPort]), verify = False)
		if objHResp.status_code == 200:
			os.remove(strPFile)
			# Any standard output stops the script from running. Clean up any temporary files before the standard output operation
			funLog(2, 'Peer: %s is up.' % strRIP)
			print 'UP'
			sys.exit()

	except requests.exceptions.RequestException as e:
		funLog(2, repr(e), 'err')

	# Peer down, ARM action required
	funLog(1, 'Peer down, ARM action required.', 'warning')
	funRunAuth()

	if funCurState(funLocIP(strRIP), strRIP) == 'Standby':
		funLog(1, 'We\'re Standby in ARM, Active peer down. Trying to failover...', 'warning')
		funFailover()

	sys.exit(1)


@atexit.register
def funExit():
	try:
		os.remove(strPFile)
		funLog(2, 'PIDFile: %s removed on exit.' % strPFile)
	except OSError:
		pass
	funLog(1, 'Exiting...')


if __name__ == '__main__':
	main()
