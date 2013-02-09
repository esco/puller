http = require 'http'
querystring = require 'querystring'
EventEmitter = require('events').EventEmitter

_ = require 'underscore'
request = require 'request'

class Puller extends EventEmitter

	max_connections: 10
	active_connections: 0
	request_options: {}
	waitIntervalId: 0
	fetches: 0
	totalFetches: 0

	constructor: (request_options=ll, parse=null) ->
		@setOptions request_options if request_options
		@parse = parse
		@on 'fetch', @onFetchComplete

	setOptions: (request_options) =>
		_.extend @request_options, request_options

	setParams: (params) =>
		@params = params

	start: (start, limit, end, delay=0) =>
		if @waitIntervalId
			return false

		console.log start, limit, end, delay
		@start_key = _.keys(start)[0]
		@start_val = _.values(start)[0]
		@limit_key = _.keys(limit)[0]
		@limit_val = _.values(limit)[0]
		@end_key = _.keys(end)[0]
		@end_val = _.values(end)[0]
		@keepBounds()
		@delay = delay
		@params[@limit_key] = @limit_val
		@waitIntervalId = setInterval @run, delay
		@totalFetches = Math.ceil @end_val / (@start_val + @limit_val)
		@totalFetches

	run: () =>
		if @active_connections < @max_connections
			@fetch @next()

	next: () =>
		params = _.clone @params
		params[@start_key] = @start_val
		params[@limit_key] = @limit_val
		@start_val += @limit_val
		@keepBounds()
		console.log 'params: ', params
		params

	keepBounds: () =>
		if @limit_val > @end_val
			@limit_val = @end_val
		if @start_val + @limit_val > @end_val
			#@start_val = @end_val - @start_val
			@limit_val = @limit_val - @start_val

	fetch: (params) =>
		i = @fetches++
		@active_connections++
		console.log '-----------------fetching------------------', @active_connections
		request_options = _.clone @request_options
		request_options.form = params
		request request_options, (err, response, body) =>
			body = @parse(body) if body
			@emit 'fetch', body, i , params

	onFetchComplete: () =>
		console.log 'fetch complete'
		@active_connections--
		if @totalFetches == @fetches
			clearInterval @waitIntervalId
			@emit 'complete'

module.exports = Puller