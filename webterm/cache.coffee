

##################################################
# imports
##################################################

if module?.exports?
	throw Error("Not Implemented")
else
	chrome = this.chrome

##################################################
# APIs
##################################################


cache = null

load = (callback) ->
	webterm.storage.get 'cache', (v) ->
		cache = v ? {}
		callback?()

save = ->
	webterm.storage.set 'cache', cache

class MRUCache
	constructor: (@key, @size=10) ->
		if not cache[@key]?
			cache[@key] = []
		if cache[@key].length > @size
			cache.splice @size
	put: (v) ->
		i = cache[@key].indexOf v
		if i != -1
			if i != 0
				cache[@key].splice i, 1
				cache[@key].unshift v
		else
			cache[@key].unshift v
			if cache[@key].length > @size
				cache.splice @size
		return
	get: ->
		cache[@key]

mru = (key, size) ->
	new MRUCache key, size


##################################################
# exports
##################################################

webterm.cache =
	load: load
	save: save
	set: (key, value) -> cache[key] = value
	get: (key) -> cache[key]
	remove: (key) -> delete cache[key]
	clear: -> cache = {}
	cached: -> cache
	mru: mru
