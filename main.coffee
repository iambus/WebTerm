

resize = ->
	width = $(window).width()
	height = $(window).height()
	width -= 10
	height -= 32
	if height/width < 24/40
		width = height / 24 * 40
	else
		height = width / 40 * 24
	px = width / 40
	width = 40 * px
	height = 24 * px
	console.log width, height, px
	$('#screen').css
		width: "${width}px"
		height: "${height}px"
		'font-size': "#{px}px"

connect = (selector, host, port, mode, on_connected) ->
	connection = new telnet.Connection host, port
	screen = new Screen selector
	mode?(screen)

	connection.on_connected = on_connected

	connection.on_data = (data) =>
		screen.fill_ascii_raw data
		screen.render()

	screen.on_data = (data) ->
		connection.write_data data

	connection.connect()


	connection: connection
	screen: screen


#resize()
#$(window).resize ->
#	resize()
$(window).resize ->
	$('.screen').css 'z-index': 1

on_keyboard = (callback) ->
	$('body').on 'keydown', (event) ->
#		console.log 'keydown', "ctrl: #{event.ctrlKey}, alt: #{event.altKey}, shift: #{event.shiftKey}, meta: #{event.metaKay}, char: #{String.fromCharCode event.charCode}, key: #{String.fromCharCode event.keyCode}, charCode: #{event.charCode}, keyCode: #{event.keyCode}"
#		console.log 'keydown', keymap.event_to_virtual_key event
		key = keymap.event_to_virtual_key event
		if key in ['ctrl', 'shift', 'alt', 'meta']
			return
		if key in ['ctrl-c', 'ctrl-v', 'ctrl-insert', 'shift-insert']
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

add_tab_by_address = (address) ->
	webterm.tabs.add
		icon: address.icon
		title: address.name
		content: '<div class="screen"></div>'
		on_open: (info) ->
			{connection, screen} = connect("##{info.id} .screen", address.host, address.port, address.module)
			info.screen = screen
			connection.on_connected = ->
				info.li.addClass 'connected'
				info.li.removeClass 'disconnected'
			connection.on_disconnected = ->
				info.li.addClass 'disconnected'
				info.li.removeClass 'connected'

add_tab_test = (address) ->
	webterm.tabs.add
		icon: 'lib/smth.ico'
		title: 'Test'
		content: '<div class="screen"></div>'
		on_open: (info) -> info.screen = test("##{info.id} .screen")

setup_address_book = ->
	for {name, host, port, protocol, module, icon}, i in bbs.list
		if icon
			$('#quick-connect').append "<li connect='#{i}'><a href='#}'><img src='#{icon}'/>#{name}</a></li>"
		else
			$('#quick-connect').append "<li connect='#{i}'><a href='#'>#{name}</a></li>"
	$('#quick-connect').append "<li connect='test'><a href='#'>空白测试页面</a></li>"
	$('#quick-connect').menu
		select: (event, ui) ->
			selected = ui.item.attr('connect')
			if selected == 'test'
				add_tab_test()
			else
				address_index = parseInt selected
				address = bbs.list[address_index]
				add_tab_by_address address
	menu_show = -> $('#quick-connect').show()
	menu_hide = -> $('#quick-connect').hide()
	$('#new-menu').hover menu_show, menu_hide

setup = ->
	id = null
	screen = null
	webterm.tabs.on 'active', (info) ->
		id = info.id
		screen?.inactive()
		screen = webterm.tabs.registry[id]?.screen
		screen?.active()
	Object.defineProperty webterm, 'screen',
		get: ->
			if id?
				webterm.tabs.registry[id]?.screen
	on_keyboard (e) ->
		if id?
			webterm.tabs.registry[id]?.screen?.events.on_keyboard e

	webterm.tabs.on 'new', ->
		add_tab_by_address
			icon: 'lib/smth.ico'
			name: 'NEWSMTH'
			host: 'bbs.newsmth.net'
			port: 23
			module: test.setup

	add_tab_test()



storage.init ->
	setup_address_book()
	setup()
#	test()
#	connect('bbs.newsmth.net', 23, test.setup)
#	connect('bbs.newsmth.net', 23, bbs.smth)
#	connect('bbs.nju.edu.cn', 23, bbs.lily)
