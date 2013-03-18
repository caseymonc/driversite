request = require "request"

module.exports = (User, Account, EventController) =>
	
	renderProfile: (req, res)=>
		console.log 'Endpoint: Profile'
		Account.findById req.params.user_id, (err, user)=>
			limit = 1
			if req.session?.account? && req.params.user_id == req.session.account.foursquareId
				limit = 10
			options = 
				url: 'https://api.foursquare.com' + '/v2/users/'+req.params.user_id+'/checkins?oauth_token='+user.token+'&limit=' + limit
				json: true
			request options, (error, response, body)=>
				return res.render 'profile', {phone: req.session.user.phone, checkins: body.response.checkins.items, user: user, title: "Profile", logged_in: limit == 10, user_id: req.params.user_id}

	registerEventUrl: (req, res)=>
		url = "http://localhost:3080/event"
		data = {uri: req.protocol + "://" + req.get('host') + "/users/" + req.session.user._id + "/event"}
		EventController.sendExternalEvent url, "rfq", "driver_ready", data

	create: (req, res)=>
		return res.redirect "/" unless (req.body.username? and req.body.password)
		data = {username: req.body.username, password: req.body.password, phone: req.body.phone}
		User.findOrCreate data, (err, user, created)=>
			return res.redirect '/' if err? or not user? or user.password != req.body.password
			req.session.user = user
			if created or not user.foursquareId?
				return res.redirect '/login/foursquare'
			Account.findById user.foursquareId, (err, account)=>
				if err? or not account?
					return res.redirect '/login/foursquare' 
				req.session.account = account
				return res.redirect '/profile/' + account.foursquareId

	login: (req, res)=>
		return res.redirect "/" unless (req.body.username? and req.body.password)
		data = {username: req.body.username}
		User.findOne data, (err, user)=>
			return res.redirect '/' if err? or not user? or user.password != req.body.password
			req.session.user = user
			if not user.foursquareId?
				return res.redirect '/login/foursquare'
			Account.findById user.foursquareId, (err, account)=>
				if err? or not account?
					return res.redirect '/login/foursquare' 
				req.session.account = account
				return res.redirect '/profile/' + account.foursquareId

	renderProfileList: (req, res)=>
		console.log 'Endpoint: Profile List'
		Account.getAllAccounts (err, accounts)=>
			logged_in = false
			if req.session?.account?
				logged_in = true
			return res.render('profiles', {users: accounts, title: "Users", logged_in: logged_in})

	logout: (req, res)=>
		console.log 'Endpoint: Logout'
		if req.session?.user?
			delete req.session.user
		req.session.destroy()
		return res.redirect '/login'

	loginFoursquare: (req, res)=>
		console.log 'Endpoint: Login Foursquare'
		ensureUserAuthenticated req, res, ()=>
			return res.redirect '/profile/' + req.user.foursquareId if req.session?.account?
			return res.render('login_foursquare', {title: "Foursquare Login"})

	authCallback: (req, res)=>
		console.log 'Endpoint: Auth Callback'
		req.session.account = req.user
		req.session.user.foursquareId = req.user.foursquareId
		User.addAccount req.user.foursquareId, req.session.user.username, ()=>
			return res.redirect '/profile/' + req.user.foursquareId

	updateBid: (req, res)=>
		Account.updateUserBid req.body.bid, req.params.foursquareId, (err)=>
			res.send "OK"


	updateUserLocation: (req, res)=>
		user = JSON.parse req.body.user
		checkin = JSON.parse req.body.checkin
		options =
			lon: checkin.venue.location.lng
			lat: checkin.venue.location.lat
			foursquareId: checkin.user.id
			name: checkin.venue.name 
		Account.updateUserLocation options, (err)=>
			res.redirect '/profile/' + req.user.foursquareId

ensureDriverAuthenticated = (req, res, next)->
	ensureUserAuthenticated req, res, ()->
		ensureFoursquareAuthenticated req, res, next

ensureUserAuthenticated = (req, res, next)->
	console.log 'Try Auth Login'
	return next() if req.session?.user?
	res.redirect '/login'

ensureFoursquareAuthenticated = (req, res, next)->	
	console.log 'Try Auth Foursquare'
	return next() if req.session?.account?
	res.redirect '/login/foursquare'


