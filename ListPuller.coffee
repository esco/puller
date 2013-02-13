_ = require 'underscore'
Puller = require './Puller'

class ListPuller extends Puller

	constructor: (options) ->
		super options

	getCustomOptions: () =>
		url: @urls.shift()

	pull: (urls, rateLimit, sleep, awake) =>
		@urls = urls

		@removeListener('data', @onCompleteAsync )if @onCompleteAsync 
		@onCompleteAsync = _.after @urls.length, () =>
			@emit 'complete'
			@removeListener 'data', @onCompleteAsync
		@on 'data', @onCompleteAsync
		@rateLimiter.start rateLimit, sleep, awake
		
	onComplete: () =>
		@rateLimiter.stop()

module.exports = ListPuller