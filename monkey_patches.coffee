
windowAddEventListener = Window.prototype.addEventListener
Window.prototype.addEventListener = (type) ->
	if (type == 'unload' || type == 'beforeunload')
		console.error "#{type} is suppressed by Chrome packaged app"
	else
		return windowAddEventListener.apply(window, arguments)

