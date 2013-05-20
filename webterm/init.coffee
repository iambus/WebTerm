
webterm.init = (callback) ->
	webterm.settings.init ->
		webterm.cache.load ->
			callback()
