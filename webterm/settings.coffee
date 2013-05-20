
##################################################
# imports
##################################################

if module?.exports?
	throw Error("Not Implemented")
else
	webterm = this.webterm

##################################################
# APIs
##################################################

load_default = (callback) ->
	webterm.resources.get_text "settings.json", (v) ->
		callback JSON.parse v

load = (callback) ->
	webterm.storage.get 'settings', (v) ->
		callback v

save = (settings) ->
	webterm.storage.set 'settings', settings

default_cache = null
cache = null

init = (callback) ->
	load_default (default_settings) ->
		default_cache = default_settings
		webterm.storage.get 'settings', (local_settings) ->
			cache = local_settings ? {}
			callback()

get = (k) ->
	cache[k] ? default_cache[k]

set = (k, v) ->
	cache[k] = v
	save cache

##################################################
# exports
##################################################

exports =
	init: init
	set: set
	get: get
	cached: -> cache

if module?.exports?
	exports = exports
else
	webterm.settings = exports

