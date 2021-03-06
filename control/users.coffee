request = require "request"

module.exports = (User, Account, EventController) =>
	
	renderProfile: (req, res)=>
		console.log 'Endpoint: Profile'
		Account.findById req.params.user_id, (err, user)=>
			User.findByFoursquareId user.foursquareId, (use_err, use)=>
				if use_err or not use?.deliveries?
					deliver = []
				else
					deliver = use.deliveries

				console.log deliver

				limit = 1
				if req.session?.account? && req.params.user_id == req.session.account.foursquareId
					limit = 10
				options = 
					url: 'https://api.foursquare.com' + '/v2/users/'+req.params.user_id+'/checkins?oauth_token='+user.token+'&limit=' + limit
					json: true
				request options, (error, response, body)=>
					return res.render 'profile', {phone: req.session.user.phone, checkins: body.response.checkins.items, user: user, title: "Profile", logged_in: limit == 10, user_id: req.params.user_id, deliveries: deliver}

	registerEventUrl: (req, res)=>
		url = "http://localhost:3040/event"
		data = {uri: "http://localhost/users/" + req.session.user._id + "/event", name: req.session.user.username}
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

		if req.session?.account?
			delete req.session.account
		#req.session.destroy()
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
			res.redirect '/profile/' + req.params.foursquareId

	completeDelivery: (req, res)=>
		url = "http://localhost:3040/event"
		data = {delivery_id: req.params.delivery_id, driverUri: "http://localhost/users/" + req.session.user._id + "/event"}
		EventController.sendExternalEvent url, "delivery", "complete", data

		url = "http://localhost:3080/event"
		EventController.sendExternalEvent url, "delivery", "complete", data

		res.redirect "/profile/" + req.params.user_id

	bidAwarded: (body)=>
		bid = body.bids[0]
		user_id = bid.driverUri.substring("http://localhost/users/".length, bid.driverUri.indexOf("/event"))
		User.addDelivery user_id, {price: bid.bid, due: body.deliveryTime, delivery_id: body.delivery_id, address: body.address}, (err)=>
			return console.log err if err
			console.log "Succeeded?"


	updateUserLocation: (req, res)=>
		user = JSON.parse req.body.user
		checkin = JSON.parse req.body.checkin
		options =
			lon: checkin.venue.location.lng
			lat: checkin.venue.location.lat
			foursquareId: checkin.user.id
			name: checkin.venue.name 
		Account.updateUserLocation options, (err)=>
			res.send "OK"

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


