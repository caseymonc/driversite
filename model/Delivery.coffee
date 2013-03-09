mongoose = require 'mongoose'
Schema = mongoose.Schema
ObjectId = require('mongoose').Types.ObjectId

# Delivery Model
module.exports = (db) ->

	DeliverySchema = new Schema({
		flowerShopId: String,
		address: String,
		pickupTime: Date,
		deliveryTime: Date
	}, { collection : 'driver_deliveries' })

	DeliverySchema.statics.get = (flowerShopId, cb)->
		@find({"flowerShopId": flowerShopId}).exec cb

	DeliverySchema.statics.addBid = (delivery_id, data, cb)->
		delivery_id = new ObjectId(delivery_id)
		@findOne({"_id": delivery_id}).exec (err, delivery)=>
			return cb err if err?
			return cb {failed: true} if not delivery?
			foundBid = false
			delivery.bids = [] if not delivery.bids?
			for bid in delivery.bids
				if bid.driverUri is data.driverUri
					bid.driverName = data.driverName
					bid.bid = data.bid
					foundBid = true
			if not foundBid
				console.log "Added Bid: " + data
				delivery.bids.push(data)
				console.log delivery

			delivery.save (err)=>
				return cb err if err?
				cb null, delivery

	Delivery = db.model "Delivery", DeliverySchema