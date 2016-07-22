'use strict';

// Import the Node.js modules
var objF5 = require('f5-nodejs');
var funHTTP = require('request');
var funStr = require('string');

// Create a new RPC server for listening to TCL iRule calls
var objILX = new objF5.ILXServer();

// Add a method that expects the client IP as an argument and returns an error code
objILX.addMethod('ilxmet_IPREP', function(objArgs, objResponse) {
	console.log('Method Invoked, Arguments:', objArgs.params());
	var intErrCode = 1;
	funHTTP('http://10.100.115.102/geo?' + objArgs.params()[0], { timeout : 2000 }, function (objError, objHResp, strHBody) {
		if (objError) {
			console.error("HTTP Connection Failed:", JSON.stringify(objError));
			objResponse.reply([intErrCode, "Connection Failed!"]);
			return;
		}
		if (objHResp.statusCode == 200) {
			var strIPResult = funStr(strHBody).between('<span class="iprep">','</span>').s;
			console.log('IP Reputation Result: ' + strIPResult);
			if (strIPResult === 'Good') {
				intErrCode = 0;
			}
			objResponse.reply([intErrCode, "Reputation was Good!"]);
		}
	});	//funHTTP
}); //.addMethod

// Start listening for ILX::call events
objILX.listen();
console.log('Running index.js, RPC Server Started.');
