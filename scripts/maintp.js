#!/usr/bin/env node
/*
	F5 Networks - Node.js: BIG-IP Maintenance Portal
	https://github.com/ArtiomL/f5networks
	Artiom Lichtenstein
	v0.0.1, 25/04/2017
*/

'use strict';

// Import the Node.js modules
var objArgParser = require('argparse').ArgumentParser;
var funHTTPC = require('request');
var objHTTPS = require('https');
var objFS = require('fs');

// Constants
var objErrorCodes = {
	intNO : 0
};

// Console log level
var intLogLevel = 2;
var strLogID = '[-v0.0.1-170425-]';

function funLog(intMesLevel, strMessage, strMethod, objError) {
	if (intLogLevel >= intMesLevel) {
		console[strMethod !== undefined ? strMethod : 'log'](strLogID, strMessage, objError !== undefined ? objError : '');
	}
}


function funArgParser() {
	var objAParser = new objArgParser({
		version: 'v0.0.1',
		addHelp: true,
		description: 'F5 BIG-IP Maintenance Portal',
		epilog: 'https://github.com/ArtiomL/f5networks'
	});
	objAParser.addArgument(
		'-c',
		{ 
			help: 'SSL certificate',
			defaultValue: '/etc/ssl/certs/ssl-cert-snakeoil.pem',
			dest: 'cert'
		}
	);
	objAParser.addArgument(
		'-i',
		{ 
			help: 'BIG-IP iControl REST IP address',
			dest: 'ip'
		}
	);
	objAParser.addArgument(
		'-k',
		{ 
			help: 'SSL key',
			defaultValue: '/etc/ssl/private/ssl-cert-snakeoil.key',
			dest: 'key'
		}
	);
	objAParser.addArgument(
		'-l',
		{
			help: 'HTTP port to listen on',
			defaultValue: 443,
			type: 'int',
			dest: 'port'
		}
	);
	objAParser.addArgument(
		'-p',
		{
			help: 'iControl REST password',
			dest: 'pass'
		}
	);
	objAParser.addArgument(
		'-u',
		{
			help: 'iControl REST username',
			dest: 'user'
		}
	);
	return objAParser.parseArgs();
}


var objArgs = funArgParser();
var objHSOpt = {
	key: objFS.readFileSync(objArgs.key),
	cert: objFS.readFileSync(objArgs.cert)
};

// Create a new HTTPS server
var objHSrv = objHTTPS.createServer(objHSOpt);


objHSrv.listen(objArgs.port);
funLog(2, 'HTTP server started on port ' + objArgs.port.toString(), 'error');
