request = require "request"

module.exports = (EventEmitter) =>
	sendExternalEvent: (url, domain, name, data)=>
		console.log "Emit Event"
		console.log "Url: " + url
		console.log "domain: " + domain
		console.log "name: " + name
		console.log "data: " + JSON.stringify data

		data = {}

		data._domain = domain
		data._name = name

		options =
			url: url
			json: data

		request.post options, (e, r, body)=>
			return;

	handleEvent: (req, res)=>
		data = req.body
		domain = data._domain
		name = data._name

		if domain? && name?
			EventEmitter.emit domain + ":" + name, data
			console.log "Emit Event: " + domain + ":" + name
