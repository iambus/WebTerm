
stack_topright =
	dir1: "down"
	dir2: "left"
	firstpos1: 36
	firstpos2: 12
	spacing1: 5
	spacing2: 10

stack_downright =
	dir1: "up"
	dir2: "left"
	firstpos1: 25
	firstpos2: 12
	spacing1: 5
	spacing2: 10

screen_notification = (message) ->
	if _.isString message
		message = text: message

	default_options =
#		addclass: "stack-bottomright"
		stack: stack_topright
		width: '240px'
		delay: 5000

	$.pnotify $.extend default_options, message

$ ->
	$.pnotify.defaults.styling = "jqueryui"
	$.pnotify.defaults.history = false

webterm.notifications =
	screen_notification: screen_notification
