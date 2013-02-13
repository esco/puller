_ = require 'underscore'
Puller = require './Puller'

class PaginatedPuller extends Puller

	constructor: (options) ->
		super options

	pull: (start, limit, end, rate=0) =>
		console.log start, limit, end, rate
		@start_key = _.keys(start)[0]
		@start_val = _.values(start)[0]
		@limit_key = _.keys(limit)[0]
		@limit_val = _.values(limit)[0]
		@end_key = _.keys(end)[0]
		@end_val = _.values(end)[0]
		@keepBounds()
		@params[@limit_key] = @limit_val
		@totalFetches = Math.ceil @end_val / (@start_val + @limit_val)
		@on 'data', _.after @totalFetches, () =>
			@emit 'complete'
		@rateLimiter.start rate
  
	keepBounds: () =>
		if @limit_val > @end_val
			@limit_val = @end_val
		if @start_val + @limit_val > @end_val
			@limit_val = @limit_val - @start_val

	prev: () =>

	next: () =>
		params = _.clone @params
		params[@start_key] = @start_val
		params[@limit_key] = @limit_val
		@start_val += @limit_val
		@keepBounds()
		params

	getCustomOptions: () =>
		form:
			params: @next()

module.exports = PaginatedPuller