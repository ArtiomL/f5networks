/*
	F5 Networks - Node.js: GraphQL Schema Validation
	https://github.com/ArtiomL/f5networks
	Artiom Lichtenstein
	v1.0.2, 18/10/2017
*/

'use strict';

// Log level to /var/log/ltm
var intLogLevel = 0;
var strLogID = '[-v1.0.2-171018-]';

function funLog(intMesLevel, strMessage, strMethod, objError) {
	if (intLogLevel >= intMesLevel) {
		console[strMethod !== undefined ? strMethod : 'log'](strLogID, strMessage, objError !== undefined ? objError : '');
	}
}

// Constants
var objErrorCodes = {
	intInputVal: 108,
	intGQLVal: 99,
	intNO: 0
};

// Import the Node.js modules
var objGQL = require('graphql');
var objF5 = require('f5-nodejs');

// Construct a schema, using the GraphQL schema language
var objSchema = objGQL.buildSchema(`
	type Monkey {
		id: ID!
		firstName: String
		lastName: String
		isAlive: Boolean
		age: Float
	}
	type Query {
		getMonkey(id: ID!): Monkey
	}
`);

// Pseudo-database
var objMonkeyDB = {
	1: {
		id: 1,
		firstName: 'Tyler',
		lastName: 'Durden',
		isAlive: false,
		age: 32.1
	},
	2: {
		id: 2,
		firstName: 'Marla',
		lastName: 'Singer',
		isAlive: true,
		age: 34.5
	}
};

// The root provides a resolver function for each API endpoint
var objRoot = {
	getMonkey: function ({id}) {
		return objMonkeyDB[id];
	}
};

// Create a new RPC server for listening to TCL iRule calls
var objILX = new objF5.ILXServer();

// v8 performance workaround: define functions outside the try / catch statements
function funJParse(strJPayload) {
	return JSON.parse(strJPayload).query;
}

// Add a method that expects a JSON payload and returns the validation result
objILX.addMethod('ilxmet_GRAPHQL_SV', function(objArgs, objResponse) {
	funLog(2, 'ilxmet_GRAPHQL_SV method invoked with arguments:', 'info', objArgs.params());
	var strPayload = objArgs.params()[0];
	try {
		var objQuery = funJParse(strPayload);
	}
	catch(e) {
		objResponse.reply([objErrorCodes.intInputVal, e.message]);
		funLog(1, 'Invalid GraphQL query:', 'error', e.message);
		return;
	}
	objGQL.graphql(objSchema, objQuery, objRoot).then((objGQLRes) => {
		var strJSONRes = JSON.stringify(objGQLRes);
		if (!objGQLRes.errors) {
			objResponse.reply([objErrorCodes.intNO, strJSONRes]);
		}
		else {
			objResponse.reply([objErrorCodes.intGQLVal, strJSONRes]);
			funLog(1, 'GraphQL query error:', 'error', strJSONRes);
		}
	}); //.graphql
});	//.addMethod

// Start listening for ILX::call and ILX::notify events
objILX.listen();

funLog(2, 'Running index.js, RPC server started.');
