
display_message = (message) ->
	if message.type == 'error'
		$('#message-body').addClass 'error'
	else
		$('#message-body').removeClass 'error'
	$('#message-body').text(message.text)

animate_message = (message, callback) ->
	$('#message-body').effect 'drop', direction: 'up', 50,
		->
			display_message message
			$('#message-body').effect 'slide', direction: 'down', 200, callback


render_message = (message, callback) ->
	if message.type == 'error'
		display_message message
		callback?()
	else
		animate_message message, callback

class MessageQueue
	constructor: (@queue=[]) ->
		@counter = 0
		@working = false
	post: (message) ->
		if _.isString message
			message =
				type: 'info'
				text: message
		message.id = ++@counter
		message.time = new Date
		@queue.push message
		if not @working
			@poll()
	poll: ->
		@working = true
		if @queue.length > 0
			message = @queue.shift()
			render_message message, =>
				if @queue.length > 0
					setTimeout (=> @poll()), 2000
				else
					@working = false
		else
			@working = false


queue = new MessageQueue()

webterm.status_bar =
	queue: queue
	tip: (message) -> queue.post message
	error: (message) -> queue.post type: 'error', text: message

