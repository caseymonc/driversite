request = require "request"

class TwilioController
	constructor: (@User, @Account, @Twilio, @EventController)->


	init: ()=>
		@phone = @Twilio.getPhoneNumber('+18019214403')
		@phone.setup ()=>
			@phone.on 'incomingSms', (reqParams, res)=>
				console.log('Received incoming SMS with text: ' + reqParams.Body);
				console.log('From: ' + reqParams.From);

	receivedSMS: (req, res)=>
		phone = req.body.From
		text = req.body.Body
		return res.send "OK" if text != "bid anyway"
		len = phone.length
		phone = phone.subsstring(len - 10) if phone.length > 10
		User.findByNumber phone, (err, user)=>
			return res.send err if err?
			return res.send "Not Found" if not user?
			return res.send "No Delivery" if not user?.lastDelivery?
			
			Account.findById user.foursquareId, (err, account)=>
				data = {}
				data.bid = account.bid
				data.driverUri = "http://localhost/users/" + account.foursquareId + "/event"
				data.delivery_id = user.lastDelivery.delivery_id
				data.driverName = account.name.givenName + " " + account.name.familyName

				@EventController.sendExternalEvent user.lastDelivery.uri, "rfq", "bid_available", data

	sendSMS: (number, message)=>
		@phone.sendSms '+18019214403', number, message

module.exports = TwilioController