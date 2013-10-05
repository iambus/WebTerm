
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

screen_html = '<div class="screen"></div>'
screen_layout_html = '''<div class="screen-layout" style="width: 100%; height: 100%">
<div class="ui-layout-center"><div class="screen"></div></div>
<div class="ui-layout-east">
<div class="screen-sider webterm-accordion">
<div class="webterm-accordion-section webterm-accordion-toggled">
	<h3>多媒体</h3>
	<div class="screen-sider-multimedia">
		<div class="screen-sider-sounds"></div>
		<div class="screen-sider-videos"></div>
		<div class="screen-sider-images"></div>
	</div>
</div>
<div class="webterm-accordion-section webterm-accordion-toggled">
	<h3>快捷键</h3>
	<div class="screen-sider-hotkeys"></div>
</div>
<div class="webterm-accordion-section">
	<h3>版务</h3>
	<div class="screen-sider-power-hotkeys"></div>
</div>
<div class="webterm-accordion-section webterm-accordion-toggled">
	<h3>手势</h3>
	<div class="screen-sider-gestures"></div>
</div>
<div class="webterm-accordion-section webterm-accordion-toggled">
	<h3>命令</h3>
	<div class="screen-sider-commands"></div>
</div>
<div class="webterm-accordion-section webterm-accordion-toggled">
	<h3>任务</h3>
	<div class="screen-sider-jobs"></div>
</div>
<div class="webterm-accordion-section webterm-accordion-toggled">
	<h3>位置</h3>
	<div class="screen-sider-locations"></div>
</div>
<div class="webterm-accordion-section webterm-accordion-toggled">
	<h3>选项</h3>
	<div class="screen-sider-options"></div>
</div>
</div>
</div>
</div>'''
screen_layout = (div) ->
	element = $(div).find('.screen-layout')
	if element.length > 0
		setTimeout ->
			element.layout
				defaults:
					spacing_open: 3
					spacing_closed: 3
				east:
					resizable: true
					resizeWhileDragging: true
					slidable: true
					size: 100
#			$(div).find('.screen-sider').accordion()
			webterm.accordion $(div).find('.webterm-accordion')
		, 0

new_bbs_tab = (address) ->
	webterm.tabs.add
		icon: address.icon
		title: address.name
#		content: screen_html
		content: screen_layout_html
		on_open: (info) ->
			screen_layout(info.div)
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

$ ->
	webterm.tabs.bbs = new_bbs_tab
