module.exports = (Delivery, Account, User, EventController)=>
	emitDelivery: (body)=>
		User.findById body.user_id, (err, user)=>
			Account.findById user.foursquareId, (err, account)=>
				miles = distanceMiles body.lat, body.lon, account.pos[1], account.pos[0]

				radius = body.radius

				if radius < miles
					#Ask for bid
					console.log "Too far away, sending text.  Distance: " + miles + " Radius: " + radius
					return
				else
					#Auto Bid
					console.log "Sending bid_available.  Distance: " + miles + " Radius: " + radius
					data = {}
					data.bid = 5.50
					data.driverUri = "http://localhost/users/" + body.user_id + "/event"
					data.delivery_id = body.delivery_id
					data.driverName = account.name.givenName + " " + account.name.familyName

					EventController.sendExternalEvent body.uri, "rfq", "bid_available", data



distanceMiles = (lat1, lon1, lat2, lon2)=>
	earthRadius = 6371;

	decimals = 5;

	dLat = (lat1 - lat2) * Math.PI / 180
	dLon = (lon1 - lon2) * Math.PI / 180
	lat1 = lat1 * Math.PI / 180
	lat2 = lat2 * Math.PI / 180


	a = Math.sin(dLat / 2) * Math.sin(dLat / 2) + Math.sin(dLon / 2) * Math.sin(dLon / 2) * Math.cos(lat1) * Math.cos(lat2)
	c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
	d = earthRadius * c
	kilometers = Math.round(d * Math.pow(10, decimals)) / Math.pow(10, decimals)
	miles = kilometers * 0.621371


