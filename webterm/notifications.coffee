
webkit_notification = (message) ->
	if _.isString message
		message =
			text: message
	havePermission = window.webkitNotifications.checkPermission()
	if havePermission == 0
		notification = window.webkitNotifications.createNotification message.icon ? 'lib/webterm.png', message.title ? '', message.text
		if message.onclick?
			notification.onclick = ->
				message.onclick()
				notification.close()
		notification.show()
	else
		window.webkitNotifications.requestPermission()
		console.error 'Desktop Notification is disabled!'
		screen_notification type: 'error', text: "Desktop Notification is disabled in your environment!\nRequested content: #{message.text}"


chrome_notification = (message) ->
	if _.isString message
		message =
			text: message
	chrome.notifications.create '',
		type: 'basic'
		iconUrl: 'lib/webterm.png'
		title: message.title ? ''
		message: message.text
		(notificationId) ->

is_chrome_notification_available = ->
	if chrome.notifications?
		version = navigator.appVersion.match(/Chrom(e|ium)\/([0-9]+)\./)?[2]
		return version and parseInt(version) >= 28

desktop_notification = (message) ->
	if is_chrome_notification_available()
		chrome_notification(message)
	else
		webkit_notification(message)

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
	desktop_notification: desktop_notification
	webkit_notification: webkit_notification
	chrome_notification: chrome_notification
