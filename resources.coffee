

chrome_get = (url, raw, callback) ->
	url = chrome.runtime.getURL url
	xhr = new XMLHttpRequest
	if raw
		xhr.responseType = 'arraybuffer'
	xhr.onreadystatechange = ->
		if xhr.readyState == 4
			callback xhr.response
	xhr.open("GET", url, true)
	xhr.send()

get_text = (url, callback) ->
	chrome_get url, false, callback

get_raw = (url, callback) ->
	chrome_get url, true, callback

##################################################
# exports
##################################################

exports =
	get_text: get_text
	get_raw: get_raw

if module?.exports?
	module.exports = exports
else
	this.resources = exports
