

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
	storage_remove = (key) ->
		chrome.storage.local.remove key
	sotarge_clear = ->
		chrome.storage.local.clear()
else
	storage_get = (key, callback) ->
		value = localStorage[key]
		data = {}
		if value
			data[key] = JSON.parse value
		callback data
	storage_set = (key, value) ->
		localStorage[key] = JSON.stringify value

storage_print = (key) ->
	storage_get key, (x) -> console.log x

##################################################
# exports
##################################################

exports =
	get: storage_get
	set: storage_set
	remove: storage_remove
	clear: sotarge_clear
	print: storage_print

if module?.exports?
	exports = exports
else
	webterm.storage = exports

