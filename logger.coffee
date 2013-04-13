
log = (messages...) ->
	console.log messages...
#	$('#logger').append messages.join(' ') + '<br>'

raise = (messages...) ->
	console.trace()
	console.error messages...
	message = messages.join(' ')
#	$('#logger').append "<span style='color: red;'>#{message}</span><br>"
	throw new Error(message)

exports =
	log: log
	raise: raise

this.logger = exports
