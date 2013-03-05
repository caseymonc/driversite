request = require "request"

module.exports = () =>
	emitEvent: (url, domain, name, data)=>
		console.log "Emit Event"
		console.log "Url: " + url
		console.log "domain: " + domain
		console.log "name: " + name
		console.log "data: " + JSON.stringify data

		data._domain = domain
		data._name = name

		options =
			url: url
			json: data

		request.post options, (e, r, body)=>
			return;
