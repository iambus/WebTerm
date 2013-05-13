

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

if webterm.platform == 'chrome'
	storage_get = (key, callback) ->
		chrome.storage.local.get key, (o) -> callback o[key]
	storage_set = (key, value) ->
		o = {}
		o[key] = value
		chrome.storage.local.set o
else
	storage_get = (key, callback) ->
		value = localStorage[key]
		data = {}
		if value
			data[key] = JSON.parse value
		callback data
	storage_set = (key, value) ->
		localStorage[key] = JSON.stringify value


##################################################
# exports
##################################################

exports =
	storage_get: storage_get
	storage_set: storage_set

if module?.exports?
	exports = exports
else
	webterm.storage = exports

