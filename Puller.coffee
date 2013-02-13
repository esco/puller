_ = require 'underscore'
request = require 'request'
EventEmitter = require('events').EventEmitter
RateLimiter = require './RateLimiter'

class Puller extends EventEmitter

	constructor: (options) ->
		@fetches = 0
		@totalFetches = 0

		@rateLimiter = new RateLimiter @
		@rateLimiter.on 'token', @fetch

		@defaultRequestOptions =
			headers:
				"User-Agent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_1) AppleWebKit/537.17 (KHTML, like Gecko) Chrome/24.0.1312.57 Safari/537.17"
				"X-Requested-With":"XMLHttpRequest"
				"Content-type": "application/x-www-form-urlencoded; charset=utf-8"
			method: 'POST'
			form:
				params: {}
		@params = @defaultRequestOptions.form.params

		@on 'data', @onData if @onData
		@on 'complete', @onComplete if @onComplete

	addDefaultRequestOption: (k, v) =>
		if @defaultRequestOptions.hasOwnProperty(k) and _.isObject v
			_.extend @defaultRequestOptions[k] , v
		else
			@defaultRequestOptions[k] = v

	addDefaultParam: (k, v) =>
		if @params.hasOwnProperty(k) and _.isObject v
			_.extend @params[k], v
		else
			@params[k] = v

	getCustomOptions: () =>
		{}

	getRequestOptions: () =>
		options = _.clone @defaultRequestOptions
		customOptions = @getCustomOptions()
		_.extend options, customOptions
		_.defaults options.form.params, @params
		options

	parse: (body) =>
		body

	fetch: (tokenId) =>
		options = @getRequestOptions()
		fetchCount = ++@fetches
		try
			r = request options, (err, response, body) =>
				throw err if err
				@rateLimiter.returnToken tokenId
				console.log 'connection:close'
				data = @parse body
				@emit 'data', data, fetchCount, options
			@emit 'connection:open', r, options
		catch err
			console.log "fetch #{fetchCount} failed: ", options
			#console.log options
			#process.exit()
			@rateLimiter.returnToken tokenId


	pull: (rate=0) =>
		@rateLimiter.start rate

module.exports = Puller