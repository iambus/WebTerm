
connect = (selector, host, port, mode, on_connected) ->
	connection = new telnet.Connection host, port
	screen = new webterm.Screen selector
	screen.name = host

	if mode == 'smth'
		mode = webterm.bbs.smth
	else if mode == 'lily'
		mode = webterm.bbs.lily
	else if mode == 'firebird'
		mode = webterm.bbs.firebird
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
				reconnect = ->
					console.log 'reconnecting...'
					info.session.screen.data.clear()
					info.session.connection.reconnect()
#				info.session.screen.painter.clear().foreground('red').move_to(24, 28).fill_text('连接已断开，按回车键重连。').flush()
				info.session.screen.painter
					.reset_state()
					.scollup()
					.foreground('red')
					.move_to(24, 28)
					.fill_text('连接已断开，按回车键重连。')
					.key('enter', reconnect)
					.area('bbs-clickable bbs-reconnect', 24, 28, 24, 53)
					.flush()
					.render(new webterm.bbs.common.Clickable)
				info.session.screen.cursor.reset()
				$(info.session.screen.selector).find('.bbs-reconnect').click reconnect
				$(info.session.screen.selector).find('.cursor').removeClass('cursor')
				$(info.session.screen.selector).find('.blink').removeClass('blink')
		on_closed: (info) ->
			info.session.connection.disconnect()

webterm.new_bbs_tab = new_bbs_tab
