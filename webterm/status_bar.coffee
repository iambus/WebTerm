
display_message = (message) ->
	if message.type == 'error'
		$('#message-body').addClass 'error'
	else
		$('#message-body').removeClass 'error'
	$('#message-body').attr 'message-id', message.id
	if message.text?
		$('#message-body').text(message.text)
	if message.html?
		$('#message-body').html(message.html)

animate_message = (message, callback) ->
	$('#message-body').effect 'drop', direction: 'up', 50,
		->
			display_message message
			$('#message-body').effect 'slide', direction: 'down', 200, callback

render_message = (message, callback) ->
	if message.type == 'error'
		show_status_bar()
		display_message message
		callback?()
	else
		animate_message message, callback

clear_message = (message) ->
	if not(message?) or $('#message-body').attr('message-id') == message.id.toString()
		$('#message-body').removeClass('error').text ''

class Message
	constructor: (message) ->
		if _.isString message
			message =
				type: 'info'
				text: message
		@type = message.type
		@text = message.text
		@html = message.html
		@time = new Date
	close: ->
		clear_message @

class MessageQueue
	constructor: (@queue=[]) ->
		@counter = 0
		@working = false

	post: (message) ->
		message = new Message message
		message.id = ++@counter
		for m in @queue
			if m.type == message.type and m.text == message.text and m.html == message.html
				# remove duplicate message
				# TODO: customize this behavior
				return
		@queue.push message
		if not @working
			@poll()
		return message

	is_empty: ->
		@queue.length <= 0

	schedule: ->
		if @last_message?.type != 'error' and @queue[0].type == 'error'
			# don't delay when we receive an error message
			@poll()
		else
			setTimeout (=> @poll()), 1500

	poll: ->
		@working = true
		if not @is_empty()
			message = @queue.shift()
			@last_message = message
			render_message message, =>
				if not @is_empty()
					@schedule()
				else
					@working = false
		else
			@working = false


queue = new MessageQueue()

hide_status_bar = ->
	$('#status-bar').hide()

show_status_bar = ->
	$('#status-bar').show()

$ ->
	$('#message-body').on 'click', '[eval]', ->
		code = $(@).attr 'eval'
		if code
			webterm.eval code
	$('#status-bar-close-button').click hide_status_bar
	if not window.onerror?
		window.onerror = (e) -> webterm.status_bar.error e

webterm.status_bar =
	show: show_status_bar
	hide: hide_status_bar
	queue: queue
	tip: (message) -> queue.post message
	info: (message) -> queue.post message
	error: (message) ->
		if _.isString message
			message =
				text: message
		message.type = 'error'
		queue.post message
	clear: clear_message

