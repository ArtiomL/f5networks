/*
	F5 Networks - Node.js: Slack Bot Client
	https://github.com/ArtiomL/f5networks
	Artiom Lichtenstein
	v1.0.1, 25/10/2017
*/

'use strict';

// Log level
var intLogLevel = 0;
var strLogID = '[-v1.0.1-171025-]';

function funLog(intMesLevel, strMessage, strMethod, objError) {
	if (intLogLevel >= intMesLevel) {
		console[strMethod !== undefined ? strMethod : 'log'](strLogID, strMessage, objError !== undefined ? objError : '');
	}
}

// Import the Node.js modules
var objShell = require('shelljs');
var funRtmClient = require('@slack/client').RtmClient;
var objRtmEvents = require('@slack/client').RTM_EVENTS;
var objClientEvents = require('@slack/client').CLIENT_EVENTS;

var strBotToken = process.env.SLACK_BOT_TOKEN || '';
var objRtm = new funRtmClient(strBotToken);

// Constants
var strPool = 'pool_HTTPS_Debian';
var strNode = 'node_ADCT';


objRtm.on(objClientEvents.RTM.AUTHENTICATED, function(objStartData) {
	funLog(1, 'Logged in as ' + objStartData.self.name);
});

objRtm.on(objRtmEvents.MESSAGE, function(objMessage) {
	var arrMsgText = objMessage.text.toLowerCase().split(' ');
	switch(arrMsgText[0]) {
		case 'hello':
			objRtm.sendMessage('Hello <@' + objMessage.user + '>!', objMessage.channel);
			break;
		case 'status':
			var strStdout = objShell.exec('tmsh show /ltm pool ' + strPool + ' members', {silent: true}).grep('State\|Ltm::Pool').stdout;
			objRtm.sendMessage('```' + strStdout + '```', objMessage.channel);
			break;
		case 'ena':
			if (objShell.exec('tmsh modify /ltm pool ' + strPool + ' members modify { ' + strNode + arrMsgText[1] + ':https { session user-enabled state user-up } }', {silent: true}).code === 0) {
				objRtm.sendMessage(':thumbsup:', objMessage.channel);
			}
			break;
		case 'dis':
			if (objShell.exec('tmsh modify /ltm pool ' + strPool + ' members modify { ' + strNode + arrMsgText[1] + ':https { session user-disabled state user-down } }', {silent: true}).code === 0) {
				objRtm.sendMessage(':thumbsup:', objMessage.channel);
			}
			break;
		case 'tmsh':
			var strStdout = objShell.exec(objMessage.text, {silent: true}).stdout;
			objRtm.sendMessage('```' + strStdout + '```', objMessage.channel);
			break;
	}
});

objRtm.start();
