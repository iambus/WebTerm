

on_keyboard = (callback) ->
	$('body').on 'keydown', (event) ->
		if not ($('body').is(event.target) or $('#ime').is(event.target) or $(event.target).closest($('#tabs')).length > 0)
#			console.log event, document.activeElement
			return
#		console.log 'keydown', "ctrl: #{event.ctrlKey}, alt: #{event.altKey}, shift: #{event.shiftKey}, meta: #{event.metaKay}, char: #{String.fromCharCode event.charCode}, key: #{String.fromCharCode event.keyCode}, charCode: #{event.charCode}, keyCode: #{event.keyCode}"
#		console.log 'keydown', keymap.event_to_virtual_key event
		key = keymap.event_to_virtual_key event
		if key in ['ctrl', 'shift', 'alt', 'meta']
			return
		if key in ['ctrl-c', 'ctrl-v', 'ctrl-insert', 'shift-insert', 'tab']
			event.preventDefault()
		$('#ime').focus()
		if event.ctrlKey or event.altKey or event.metaKey
			callback key: key
		else if key in ['tab', 'delete', 'backspace', 'up', 'down', 'left', 'right', 'esc', 'home', 'end', 'pageup', 'pagedown', 'insert',
										'f1', 'f2', 'f3', 'f4', 'f5', 'f6', 'f7', 'f8', 'f9', 'f10', 'f11', 'f12']
			callback key: key
		else if key in ['shift-insert']
			callback key: key

	$('#ime').on 'keypress', (event) ->
#		console.log 'keypress', "ctrl: #{event.ctrlKey}, alt: #{event.altKey}, shift: #{event.shiftKey}, meta: #{event.metaKay}, char: #{String.fromCharCode event.charCode}, key: #{String.fromCharCode event.keyCode}, charCode: #{event.charCode}, keyCode: #{event.keyCode}"
#		console.log 'keypress', keymap.event_to_virtual_key event
		if not event.ctrlKey
			# XXX: why ctrl-b, ctrl-f, ctrl-n, and may else, still trigger keypress events?
			key = keymap.event_to_virtual_key event
			callback key: key
		event.preventDefault()

	$('#ime').on 'textInput', (event) ->
#		console.log 'textInput', event.originalEvent.data, event
		callback
			text: event.originalEvent.data
			event: event

normalize_key = (k) ->
	if k.length == 1
		return k
	m = k.match /^((?:(?:ctrl|shift|alt|meta)[+-])*)(.+)$/
	a = []
	if m[1].indexOf('ctrl') != -1
		a.push 'ctrl'
	if m[1].indexOf('shift') != -1
		a.push 'shift'
	if m[1].indexOf('alt') != -1
		a.push 'alt'
	if m[1].indexOf('meta') != -1
		a.push 'meta'
	a.push m[2]
	return a.join '-'

is_key = (x, y) ->
	if x == y
		return true
	return normalize_key(x) == normalize_key(y)

class KeyListener
	constructor: (@chain) ->
		@mappings = []
		@text_handler = null

	on_key: (key, handler) ->
		@mappings.unshift [key, handler]

	on_text: (handler) ->
		@text_handler = handler

	lookup_key: (key) ->
		for [k, h] in @mappings
			if is_key(k, key)
				return h

	dispatch_next: (e) ->
		if @chain?
			if @chain.dispatch?
				@chain.dispatch e
			else
				@chain e

	dispatch: (e) ->
		if e.key?
			h = @lookup_key(e.key)
			if h
				h e.key
			else
				@dispatch_next(e)
		if e.text?
			h = @text_handler
			if h
				h e.text
			else
				@dispatch_next(e)


root_keys = new KeyListener

on_keyboard (e) ->
	root_keys.dispatch e

webterm.keys =
	root: root_keys
	KeyListener: KeyListener

