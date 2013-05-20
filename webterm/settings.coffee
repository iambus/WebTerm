
##################################################
# imports
##################################################

if module?.exports?
	throw Error("Not Implemented")
else
	resources = webterm.resources
	{storage_get, storage_set} = webterm.storage

##################################################
# APIs
##################################################

load_default = (callback) ->
	resources.get_text "settings.json", (v) ->
		callback JSON.parse v

load = (callback) ->
	storage_get 'settings', (v) ->
		callback v

save = (settings) ->
	storage_set 'settings', settings

default_cache = null
cache = null

init = (callback) ->
	load_default (default_settings) ->
		default_cache = default_settings
		storage_get 'settings', (local_settings) ->
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

if module?.exports?
	exports = exports
else
	webterm.settings = exports

