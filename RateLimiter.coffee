EventEmitter = require('events').EventEmitter

class RateLimiter extends EventEmitter

	@::tokens = {}

	constructor: (options={}) ->
		@maxTokens = options.maxTokens or 30
		@ttl = options.ttl or 4000
		@activeTokens = 0
		@rate = 0
		@sleepTime = 0
		@isIdle = false
		@sleepTimeout = null
		@isSleeping = false

	start: (rate=0, sleepTime=0, wakeTime=0) =>
		@rate = rate
		@releaseToken()

		if sleepTime and wakeTime
			@sleepTime = sleepTime
			@wakeTime = wakeTime
			@wake()

	stop: () =>
		console.log 'stopping'
		clearTimeout @timeout
		clearTimeout @sleepTimeout
		clearTimeout @wakeTimeout
		@activeTokens = 0
	
	sleep: () =>
		@isSleeping = true
		console.log '---------------------------zzzzzzzzzz....'
		@sleepTimeout = setTimeout @wake, @sleepTime 

	wake: () =>
		console.log '---------------------------*** yawn ***'
		@isSleeping = false
		@releaseToken()
		@wakeTimeout = setTimeout @sleep, @wakeTime 

	releaseToken: () =>
		if not @isSleeping
			tokenId = @getToken()
			if tokenId
				@emit 'token', tokenId
				@timeout = setTimeout @releaseToken, @rate

	getToken: () =>
		if @activeTokens < @maxTokens
			tokenId = +new Date()
			@tokens[tokenId] = true
			@activeTokens++
			console.log 'activeTokens: ', @activeTokens
			setTimeout () =>
				@returnToken tokenId
			,
				@ttl
		else
			@isIdle = true

		tokenId

	returnToken: (tokenId) =>
		if @tokens.hasOwnProperty tokenId
			delete @tokens[tokenId]
			@activeTokens--

			if @isIdle and not @isSleeping
				@releaseToken()
				@isIdle = false

module.exports = RateLimiter