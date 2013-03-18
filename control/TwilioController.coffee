request = require "request"

class TwilioController
	constructor: (@User, @Account, @Twilio)->

	init: ()=>
		phone = @Twilio.getPhoneNumber('+18019214403')
		phone.setup ()=>
			phone.on 'incomingSms', (reqParams, res)=>
				console.log('Received incoming SMS with text: ' + reqParams.Body);
				console.log('From: ' + reqParams.From);

	receivedSMS: (req, res)=>
		phone = req.body.From
		text = req.body.Body
		return res.send "OK" if text not "bid anyway"
		console.log "Sent Bid Anyway: " + phone

	sendSMS: ()=>
		options =
			url: "https://api.twilio.com/2010-04-01/Accounts/AC3aad8128a04ead0544baf2870e36b7ac/SMS/Messages.json"
			json: data

	addTwilioListeners: (user)=>
		phone = @Twilio.getPhoneNumber('+1' + user.phone)
		phone.setup ()=>
			phone.on 'incomingSms', (reqParams, res)=>
				console.log('Received incoming SMS with text: ' + reqParams.Body);
				console.log('From: ' + reqParams.From);

module.exports = TwilioController