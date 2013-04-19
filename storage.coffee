

##################################################
# imports
##################################################

if module?.exports?
	throw Error("Not Implemented")
else
	chrome = this.chrome
	resources = this.resources

##################################################
# APIs
##################################################

storage_get = (key, callback) ->
	chrome.storage.local.get key, callback


init = (callback) ->
	storage_get 'settings', (v) ->
		if v.settings?
			exports.settings = v
			callback()
		else
			resources.get_text "settings.json", (v) ->
				exports.settings = JSON.parse v
				# TODO: set settings
				callback()


##################################################
# exports
##################################################

exports =
	init: init

if module?.exports?
	exports = exports
else
	this.storage = exports

