request = require "request"

class TwilioController
	constructor: (@User, @Account, @Twilio, @EventController)->


	init: ()=>
		@phone = @Twilio.getPhoneNumber('+18019214403')
		@phone.setup ()=>
			@phone.on 'incomingSms', (reqParams, res)=>
				console.log('Received incoming SMS with text: ' + reqParams.Body);
				console.log('From: ' + reqParams.From);
				@receivedSMS reqParams, res

	receivedSMS: (req, res)=>
		phone = req.From
		text = req.Body
		return res.send "OK" if text != "bid anyway"
		len = phone.length
		phone = phone.substring(len - 10) if phone.length > 10
		@User.findByNumber phone, (err, user)=>
			return res.send err if err?
			return res.send "Not Found" if not user?
			return res.send "No Delivery" if not user?.lastDelivery?
			return res.send "No Delivery ID" if not user?.lastDelivery?.delivery_id?
			return res.send "No Delivery URI" if not user?.lastDelivery?.uri?
			
			@Account.findById user.foursquareId, (err, account)=>
				data = {}
				data.bid = account.bid
				data.driverUri = "http://localhost/users/" + account.foursquareId + "/event"
				data.delivery_id = user.lastDelivery.delivery_id
				data.driverName = account.name.givenName + " " + account.name.familyName

				@EventController.sendExternalEvent user.lastDelivery.uri, "rfq", "bid_available", data

	sendSMS: (number, message)=>
		console.log message
		@phone.sendSms number, message, '+18019214403', error, success

error = (data)=>
	console.log data
	return

success = (data)=>
	console.log data
	return


module.exports = TwilioController