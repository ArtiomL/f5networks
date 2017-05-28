/*
	F5 Networks - Node.js: WebSocket JSON Schema Validation
	https://github.com/ArtiomL/f5networks
	Artiom Lichtenstein
	v1.0.0, 27/05/2017
*/

'use strict';

// Log level to /var/log/ltm
var intLogLevel = 2;
var strLogID = '[-v1.0.0-170527-]';

function funLog(intMesLevel, strMessage, strMethod, objError) {
	if (intLogLevel >= intMesLevel) {
		console[strMethod !== undefined ? strMethod : 'log'](strLogID, strMessage, objError !== undefined ? objError : '');
	}
}

// Constants
var objErrorCodes = {
	intInputVal : 108,
	intJSONVal : 99,
	intNO : 0
};

// Import the Node.js modules
var objF5 = require('f5-nodejs');
var funAJV = require('ajv');
var objFS = require('fs');

// Create a new RPC server for listening to TCL iRule calls
var objILX = new objF5.ILXServer();

// Create a new validator object and compile the schema
var objAJV = new funAJV();
var objSchema = JSON.parse(objFS.readFileSync('schema.json', 'utf8'));
var funValidate = objAJV.compile(objSchema);

// Add a method that expects JSON payload as an argument, and returns the validation result
objILX.addMethod('ilxmet_WS_JSON_SV', function(objArgs, objResponse) {
	funLog(2, 'ilxmet_WS_JSON_SV Method Invoked with Arguments:', 'info', objArgs.params());
	try {
		var objJSON = JSON.parse(objArgs.params()[0]);
	}
	catch(e) {
		objResponse.reply([objErrorCodes.intInputVal, e.message]);
		return;
	}
	var boolValid = funValidate(objJSON);
	if (boolValid) {
		objResponse.reply([objErrorCodes.intNO, 'OK']);
	}
	else {
		objResponse.reply([objErrorCodes.intJSONVal, funValidate.errors]);
	}
});	//.addMethod

// Start listening for ILX::call and ILX::notify events
objILX.listen();

funLog(2, 'Running index.js, RPC Server Started.');