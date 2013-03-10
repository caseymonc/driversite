module.exports = (Delivery)=>
	emitDelivery: (body)=>
		data = {}
		data.address = body.address
		data.pickupTime = body.pickupTime
		data.deliveryTime = body.deliveryTime
		