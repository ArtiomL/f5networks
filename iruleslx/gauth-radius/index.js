/*
	F5 Networks - Node.js: Google Authenticator OTP over RADIUS
	https://github.com/ArtiomL/f5networks
	Artiom Lichtenstein
	v1.5, 12/09/2016
*/

'use strict';

// Log level to /var/log/ltm
var intLogLevel = 2;
var strLogID = '[-v1.5-160912-]';

function funLog(intMesLevel, strMessage, strMethod, objError) {
	if (intLogLevel >= intMesLevel) {
		console[strMethod !== undefined ? strMethod : 'log'](strLogID, strMessage, objError !== undefined ? objError : '');
	}
}

// Constants
var strRadSecret = 'Muchs3cr3tW0w!';
var objLDAPars = {
	strURL : 'ldaps://10.1.1.12',
	intTimeout : 2000,
	strUser : 'CN=LDAP,CN=Users,DC=PaperStSoap,DC=com',
	strPass : 'M@yh3m12$xX~!',
	strBase : 'CN=Users,DC=PaperStSoap,DC=com',
	strAttr : 'pager'
};
var objErrorCodes = {
	intInputVal : 108,
	LDAP : {
		intConnect : 36,
		intTimeout : 35,
		intBind : 34,
		intSeaFail : 33,
		intSearch : 32,
		intUsAttr : 31
	},
	intNO : 0
};

// Import the Node.js modules
var objF5 = require('f5-nodejs');
var objRadius = require('radius');
var objValidator = require('validator');
var objLDAP = require('ldapjs');
var obj2FA = require('speakeasy');

// Create a new RPC server for listening to TCL iRule calls
var objILX = new objF5.ILXServer();

// Add a method that expects the RADIUS payload as an argument, and returns the RADIUS response
objILX.addMethod('ilxmet_GRADIUS', function(objArgs, objResponse) {
	funLog(2, 'ilxmet_GRADIUS Method Invoked with Arguments:', 'info', objArgs.params());
	// RADIUS
	var objBuffer = new Buffer(objArgs.params()[0], 'hex');
	var objRadDecoded = objRadius.decode({ packet: objBuffer, secret: strRadSecret });
	var strUser = objRadDecoded.attributes['User-Name'];
	var strToken = objRadDecoded.attributes['User-Password'];
	funLog(1, 'RADIUS Code: ' + objRadDecoded.code + ' User: ' + strUser + ' Token: ' + strToken);

	// Input Validation
	if ( !(objValidator.isAlpha(strUser, 'en-US') && objValidator.isNumeric(strToken) && strToken.length === 6) ) {
		funLog(1, 'Input Validation Error.', 'error');
		objResponse.reply([objErrorCodes.intInputVal, 'Input Validation Error.']);
		return;
	}

	// LDAP Connect
	var objLDAPClient = objLDAP.createClient({
		url : objLDAPars.strURL,
		connectTimeout : objLDAPars.intTimeout,
		tlsOptions : {
			rejectUnauthorized : false
		}
	});

	// LDAP Connect Error Handling
	objLDAPClient.on('error', function(objError) {
		funLog(2, 'LDAP Connect Exception:', 'error', JSON.stringify(objError));
		objResponse.reply([objErrorCodes.LDAP.intConnect, 'LDAP Connect Exception.']);
		objLDAPClient.destroy();
	});

	objLDAPClient.on('connectTimeout', function(objError) {
		funLog(2, 'LDAP Connect Timeout:', 'error', JSON.stringify(objError));
		objResponse.reply([objErrorCodes.LDAP.intTimeout, 'LDAP Connect Timeout.']);
		objLDAPClient.destroy();
	});

	objLDAPClient.on('connect', function() {
		// LDAP Bind
		objLDAPClient.bind(objLDAPars.strUser, objLDAPars.strPass, function(objError) {
			if (objError) {
				funLog(2, 'LDAP Bind Failed:', 'error', JSON.stringify(objError));
				objResponse.reply([objErrorCodes.LDAP.intBind, 'LDAP Bind Failed.']);
				objLDAPClient.destroy();
				return;
			}
			
			// LDAP Search
			var objLSOptions = {
				filter : '(sAMAccountName=' + strUser + ')',
				scope : 'sub',
				attributes : objLDAPars.strAttr
			};

			objLDAPClient.search(objLDAPars.strBase, objLSOptions, function(objError, objLSResp) {
				if (objError) {
					funLog(2, 'LDAP Search Failed:', 'error', JSON.stringify(objError));
					objResponse.reply([objErrorCodes.LDAP.intSeaFail, 'LDAP Search Failed.']);
					objLDAPClient.destroy();
					return;
				}

				objLSResp.on('error', function(objError) {
					funLog(2, 'LDAP Search Error:', 'error', JSON.stringify(objError));
					objResponse.reply([objErrorCodes.LDAP.intSearch, 'LDAP Search Error.']);
					objLDAPClient.destroy();
				});

				var boolSecretFound = false;

				objLSResp.on('searchEntry', function(objLEntry) {
					var strGASecret = objLEntry.object[objLDAPars.strAttr];
					funLog(1, 'LDAP Found GA Secret: ' + strGASecret);
					if (strGASecret !== undefined) {
						boolSecretFound = true;
						// TOTP
						var boolTokenVerify = obj2FA.totp.verify({
							secret: strGASecret,
							encoding: 'base32',
							token: strToken
						});
						var strRadCode ='Access-Reject';
						if (boolTokenVerify) {
							strRadCode = 'Access-Accept';
						}
						funLog(1, 'RADIUS Response Code: ' + strRadCode);
						var objRadReply = objRadius.encode_response({
							packet: objRadDecoded,
							code: strRadCode,
							secret: strRadSecret
						});
						objResponse.reply([objErrorCodes.intNO, objRadReply.toString('hex')]);
					}
				});	//searchEntry

				objLSResp.on('end', function(objEResult) {
					if (objEResult.status === 0 && !boolSecretFound) {
						funLog(1, 'User or Attribute Not Found.', 'error');
						objResponse.reply([objErrorCodes.LDAP.intUsAttr, 'User or Attribute Not Found.']);
						objLDAPClient.destroy();
					}
				});

			});	//.search
		});	//.bind
	});	//.on 'connect'
	objLDAPClient.unbind();
});	//.addMethod

// Start listening for ILX::call and ILX::notify events
objILX.listen();

funLog(2, 'Running index.js, RPC Server Started.');
