/*
	F5 Networks - Node.js: WebSocket JSON Schema Validation
	https://github.com/ArtiomL/f5networks
	Artiom Lichtenstein
	v1.0.1, 02/06/2017
*/

'use strict';

// Log level to /var/log/ltm
var intLogLevel = 0;
var strLogID = '[-v1.0.1-170602-]';

function funLog(intMesLevel, strMessage, strMethod, objError) {
	if (intLogLevel >= intMesLevel) {
		console[strMethod !== undefined ? strMethod : 'log'](strLogID, strMessage, objError !== undefined ? objError : '');
	}
}

// Constants
var objErrorCodes = {
	intZLib : 109,
	intInputVal : 108,
	intJSONVal : 99,
	intNO : 0
};

// Import the Node.js modules
var objF5 = require('f5-nodejs');
var funAJV = require('ajv');
var objFS = require('fs');
var objZLib = require('zlib');

// Create a new RPC server for listening to TCL iRule calls
var objILX = new objF5.ILXServer();

// Create a new validator object and compile the schema
var objAJV = new funAJV();
var objSchema = JSON.parse(objFS.readFileSync('schema.json', 'utf8'));
var funValidate = objAJV.compile(objSchema);

// Add a method that expects JSON payload and type as arguments, and returns the validation result
objILX.addMethod('ilxmet_WS_JSON_SV', function(objArgs, objResponse) {
	funLog(2, 'ilxmet_WS_JSON_SV Method Invoked with Arguments:', 'info', objArgs.params());
	var strPayload = objArgs.params()[0];
	if (objArgs.params()[1] === 2) {
		// GZIP
		var objBuffer = new Buffer(strPayload, 'ascii');
		try {
			strPayload = objZLib.inflateSync(objBuffer).toString();
			funLog(2, 'Decompressed Payload:', 'info', strPayload);
		}
		catch(e) {
			objResponse.reply([objErrorCodes.intZLib, e.message]);
			funLog(1, 'ZLib Error:', 'error', e.message);
			return;
		}
	}
	try {
		var objJSON = JSON.parse(strPayload);
	}
	catch(e) {
		objResponse.reply([objErrorCodes.intInputVal, e.message]);
		funLog(1, 'Invalid JSON:', 'error', e.message);
		return;
	}
	if (funValidate(objJSON)) {
		objResponse.reply([objErrorCodes.intNO, 'OK']);
	}
	else {
		objResponse.reply([objErrorCodes.intJSONVal, funValidate.errors]);
		funLog(1, 'Schema Validation Failed:', 'error', funValidate.errors);
	}
});	//.addMethod

// Start listening for ILX::call and ILX::notify events
objILX.listen();

funLog(2, 'Running index.js, RPC Server Started.');
