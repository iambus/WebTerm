

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
	screen = new webterm.Screen selector
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


new_bbs_tab = (address) ->
	webterm.tabs.add
		icon: address.icon
		title: address.name
		content: '<div class="screen"></div>'
		on_open: (info) ->
			info.session = connect("##{info.id} .screen", address.host, address.port, address.module)
			info.session.connection.on_connected = ->
				info.li.addClass 'connected'
				info.li.removeClass 'disconnected'
			info.session.connection.on_disconnected = ->
				info.li.addClass 'disconnected'
				info.li.removeClass 'connected'
#				info.session.screen.painter.clear().foreground('red').move_to(24, 28).fill_text('连接已断开，按回车键重连。').flush()
				info.session.screen.painter.scollup().foreground('red').move_to(24, 28).fill_text('连接已断开，按回车键重连。').flush()
				$(info.session.screen.selector).find('.cursor').removeClass('cursor')
				$(info.session.screen.selector).find('.blink').removeClass('blink')
		on_closed: (info) ->
			info.session.connection.disconnect()

new_test_tab = (address) ->
	webterm.tabs.add
		icon: 'lib/smth.ico'
		title: 'Test'
		content: '<div class="screen"></div>'
		on_open: (info) -> info.session = test("##{info.id} .screen")

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
				new_test_tab()
			else
				address_index = parseInt selected
				address = bbs.list[address_index]
				new_bbs_tab address
	menu_show = -> $('#quick-connect').show()
	menu_hide = -> $('#quick-connect').hide()
	$('#new-menu').hover menu_show, menu_hide

setup_connect_dialog = ->
	$( "#connect" ).dialog
		autoOpen: false
#		height: 300
		width: 380
		modal: true
		buttons: [
			text: '连接'
			click: ->
				new_bbs_tab
					# TODO: set icon
					name: $('#connect-host').val()
					host: $('#connect-host').val()
					port: parseInt $('#connect-port').val()
					module: bbs[$('#connect-host').val().toLowerCase()]
				$(@).dialog 'close'
		,
			text: '取消'
			click: ->
				$(@).dialog 'close'
		]
		close: ->

setup = ->
	Object.defineProperty webterm, 'active',
		get: ->
			webterm.tabs.active?.session
	Object.defineProperty webterm, 'screen',
		get: ->
			webterm.active?.screen
	webterm.keys.root.chain = (e) ->
		if webterm.active?.connection?.disconnected and e.key == '\r'
			console.log 'reconnecting...'
			webterm.active.connection.reconnect()
		else
			webterm.active?.screen.events.on_keyboard e

	webterm.tabs.on 'new', ->
		# TODO: customize behavior
		$("#connect").dialog 'open'

	new_test_tab() # for testing
	webterm.keys.root.on_key 'ctrl-n', -> new_test_tab() # for testing
#	$("#connect").dialog 'open' # for testing



webterm.storage.init ->
	setup_address_book()
	setup_connect_dialog()
	setup()
