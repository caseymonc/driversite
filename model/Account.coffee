mongoose = require 'mongoose'
Schema = mongoose.Schema

# User Model
module.exports = (db) ->

  AccountSchema = new Schema({
    foursquareId: {type: String, required:true, unique: true},
    name: {familyName: String, givenName: String},
    gender: String,
    emails: [{value: String}],
    user_id: String,
    token: String,
    photo: String,
    homeCity: String,
    uri: String,
    pos: {type: [Number], index: '2d'},
    locationName: String
  }, { collection : 'driver_accounts' })


  AccountSchema.statics.getAllRegisteredDrivers = (cb) ->
    @find({uri: {$ne: null}}).exec cb

  AccountSchema.statics.getAllAccounts = (cb) ->
    @find().exec cb

  AccountSchema.statics.updateUserLocation = (options, cb)->
    @update {foursquareId : options.foursquareId}, {pos : [options.lon, options.lat], posName : options.name}, cb

  # Get All Users for a group
  AccountSchema.statics.findById = (id, cb) ->
    @findOne({"foursquareId": id}).exec cb


  # Get a user by id
  AccountSchema.statics.findOrCreate = (data, cb) ->
    @findOne({"foursquareId": data.foursquareId}).exec (err, account) ->
      return cb {error: "Database Error"} if err?
      if not account?
        account = new Account data
        account.save (err) ->
          return cb(null, account)
      else
        cb null, account



  Account = db.model "Account", AccountSchema