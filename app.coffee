express = require 'express'
fs = require 'fs'
MemoryStore = require('express').session.MemoryStore
Mongoose = require 'mongoose'

UserModel = require './model/User'
AccountModel = require './model/Account'
DeliveryModel = require './model/Account'
passport = require 'passport'
LocalStrategy = require('passport-local').Strategy
FoursquareStrategy = require('passport-foursquare').Strategy

event = require('events')
EventEmitter = new event.EventEmitter()
request = require "request"
https = require('https')

DB = process.env.DB || 'mongodb://localhost:27017/shop'
db = Mongoose.createConnection DB
User = UserModel db
Account = AccountModel db
Delivery = DeliveryModel db

EventController = require('./control/EventController')(EventEmitter)


UserControl = require('./control/users')
UserController = new UserControl User, Account, EventController

TwilioModel = require('twilio').Client
#TwimlModel = require('twilio').Twiml
#sys = require 'sys'
TwilioClient = new TwilioModel('AC3aad8128a04ead0544baf2870e36b7ac', '53d12dbdf59880bb77d68aa2390fb186', 'ec2-184-72-144-249.compute-1.amazonaws.com')
TwilioControl = require('./control/TwilioController')
TwilioController = new TwilioControl(User, Account, TwilioClient, EventController)
DeliveryController = require('./control/DeliveryController')(Delivery, Account, User, EventController, TwilioController)

mongomate = require('mongomate')('mongodb://localhost')


DEV = false

if DEV
	FOURSQUARE_CLIENT_ID = "KSWWRPJI53P5LBXLXU2US0KHPDSPCFJKBINFF110OGI5SPAV"
	FOURSQUARE_CLIENT_SECRET = "HS0J4HEKNI4QANL2SNCE0G54GGSPJFSW5450J0410MZCNF1W"
	CALLBACK_URL = "https://127.0.0.1:3000/auth/foursquare/callback"
	PORT = 3000
else
	FOURSQUARE_CLIENT_ID = "KSWWRPJI53P5LBXLXU2US0KHPDSPCFJKBINFF110OGI5SPAV"
	FOURSQUARE_CLIENT_SECRET = "HS0J4HEKNI4QANL2SNCE0G54GGSPJFSW5450J0410MZCNF1W"
	CALLBACK_URL = "https://ec2-184-72-144-249.compute-1.amazonaws.com/auth/foursquare/callback"
	PORT = 443


FOURSQUARE_INFO = {
										"clientID": FOURSQUARE_CLIENT_ID, 
										"clientSecret": FOURSQUARE_CLIENT_SECRET, 
										"callbackURL": CALLBACK_URL
									}

exports.createServer = ->
	privateKey = fs.readFileSync('./cert/server.key').toString();
	certificate = fs.readFileSync('./cert/server.crt').toString(); 

	app = express()

	server = https.createServer({key: privateKey, cert: certificate}, app).listen PORT, ()->
		console.log "Running Foursquare Service on port: " + PORT
	
	passport.serializeUser (account, done) ->
		done null, account.foursquareId

	
	passport.deserializeUser (id, done) ->
		Account.findById id, (err, user) ->
			done null, user

	
	passport.use new FoursquareStrategy FOURSQUARE_INFO, (accessToken, refreshToken, profile, done) ->
		process.nextTick ()->
			accountData = {foursquareId: profile.id, name: profile.name, gender: profile.gender, emails: profile.emails, token: accessToken, photo: profile._json.response.user.photo, homeCity: profile._json.response.user.homeCity}
			Account.findOrCreate accountData, done
	

	app.configure ->
		app.use(express.cookieParser())
		app.use(express.bodyParser())
		app.use(express.methodOverride())
		app.use(express.session({ secret: 'driversite' }))
		app.use(passport.initialize())
		app.use(passport.session())
		app.use('/db', mongomate);
		
		app.set('view engine', 'jade')
		app.use(app.router)
		app.use(express.static(__dirname + "/public"))
		app.set('views', __dirname + '/public')
		app.use('/javascript', express.static(__dirname + "/public/javascript"))


	app.get '/', (req, res)->
		res.redirect '/login'

	app.get '/profile/:user_id', (req, res)->
		UserController.renderProfile req, res

	app.get "/profiles", (req, res)->
		return UserController.renderProfileList req, res

	app.get "/login", (req, res)->
		return res.render('login', {title: "Login"})


	app.get "/logout", (req, res)->
		return UserController.logout req, res

	app.post "/login", (req, res)->
		return UserController.login req, res

	app.post "/create/driver", (req, res)->
		return UserController.create req, res

	app.get "/login/foursquare", (req, res) ->
		return UserController.loginFoursquare req, res

	app.get "/logout/foursquare", (req, res) ->
		req.session.destroy()
		return res.redirect '/login/foursquare'

	app.get '/users/:user_id/register/uri', (req, res)->
		UserController.registerEventUrl req, res
		UserController.renderProfile req, res

	app.post '/users/:user_id/event', (req, res)->
		EventController.handleEvent req, res
		return res.send "OK"

	app.get '/users/:user_id/delivery/:delivery_id/complete', (req, res)->
		UserController.completeDelivery req, res

	EventEmitter.on "rfq:delivery_ready", (body)=>
		DeliveryController.emitDelivery body

	EventEmitter.on 'rfq:bid_awarded', (body)=>
		UserController.bidAwarded body

	app.get '/auth/foursquare', passport.authenticate('foursquare')


	app.post '/twilio', (req, res)=>
		TwilioController.receivedSMS req, res


	app.post '/users/:foursquareId/bid', (req, res)=>
		UserController.updateBid req, res

	app.post '/foursquare/event', (req, res)=>
		UserController.updateUserLocation req, res

	app.get '/auth/foursquare/callback', passport.authenticate('foursquare', { failureRedirect: '/' }), (req, res) ->
		return UserController.authCallback req, res

	# final return of app object
	app

if module == require.main
	app = exports.createServer()
	app.listen 80
	TwilioController.init()

	

ensureAuthenticated = (req, res, next)->
	ensureUserAuthenticated req, res, ()->
		ensureFoursquareAuthenticated req, res, next

ensureUserAuthenticated = (req, res, next)->
	return next() if req.session?.user?
	res.redirect '/login'

ensureFoursquareAuthenticated = (req, res, next)->
	console.log JSON.stringify req.user
	return next() if req.session?.account?
	res.redirect '/login/foursquare'
