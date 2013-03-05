mongoose = require 'mongoose'
Schema = mongoose.Schema

# User Model
module.exports = (db) ->

  UserSchema = new Schema {
    username: String,
    password: String,
    foursquareId: String,
    flowershopId: String
  }


  # Get All Users for a group
  UserSchema.statics.addAccount = (foursquareId, username, cb) ->
    @findOne({"username": username}).exec (err, user)->
      user.foursquareId = foursquareId
      user.save()
      cb()

  UserSchema.statics.findOrCreateWithShop = (data, cb)->
    @findOne({"username": data.username}).exec (err, user) ->
      return cb {error: "Database Error"} if err?
      if not user?
        userData = {username: data.username, password: data.password, flowershopId: "#{data.shop._id}"}
        user = new User userData
        user.save (err) ->
          return cb(null, user ,true)
      else
        cb null, user, false

  # Get a user by id
  UserSchema.statics.findOrCreate = (data, cb) ->
    @findOne({"username": data.username}).exec (err, user) ->
      return cb {error: "Database Error"} if err?
      if not user?
        user = new User data
        user.save (err) ->
          return cb(null, user ,true)
      else
        cb null, user, false

    # Get a user by id
  UserSchema.statics.findWithUsername = (data, cb) ->
    @findOne({"username": data.username}).exec (err, user) ->
      return cb {error: "Database Error"} if err?
      if not user?
        return cb({err: "failed to login"}, null)
      else if user.password != data.password
        return cb {err: "Invalid Password"}, null
      return cb null, user


  User = db.model "User", UserSchema