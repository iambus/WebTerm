

##################################################
# imports
##################################################

if module?.exports?
	throw Error("Not Implemented")
else
	chrome = this.chrome
	resources = webterm.resources

##################################################
# APIs
##################################################

if webterm.platform == 'chrome'
	storage_get = (key, callback) ->
		chrome.storage.local.get key, callback
else
	storage_get = (key, callback) ->
		value = localStorage[key]
		data = {}
		if value
			data[key] = JSON.parse value
		callback data


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
	webterm.storage = exports

