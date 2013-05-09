

chrome_get = (url, raw, callback) ->
	if chrome?
		url = chrome.runtime.getURL url
	xhr = new XMLHttpRequest
	if raw
		xhr.responseType = 'arraybuffer'
	xhr.onreadystatechange = ->
		if xhr.readyState == 4
			if xhr.status in [200, 0]
				callback xhr.response
			else
				console.error "may be incorrect resource address: #{url}", xhr
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
	webterm.resources = exports
