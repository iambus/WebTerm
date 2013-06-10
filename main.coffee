

resize = ->
	width = $('#main').width()
	height = $('#main').height()
	px = Math.floor height / 24
#	px = _.min [Math.floor(height / 24), Math.floor(width / 40)]
#	if px % 2 == 1
#		px--
	$('.screen').css
		'font-size': "#{px}px"


setup_address_book = ->
	for {name, host, port, protocol, module, icon}, i in webterm.address_book.get_list()
		if icon
			$('#quick-connect').append "<li connect='#{i}'><a href='#}'><img src='#{icon}'/>#{name}</a></li>"
			$('#connect-book').append "<li connect='#{i}'><a href='#}'><img src='#{icon}'/>#{name}</a></li>"
		else
			$('#quick-connect').append "<li connect='#{i}'><a href='#'>#{name}</a></li>"
			$('#connect-book').append "<li connect='#{i}'><a href='#'>#{name}</a></li>"

setup_quick_connect = ->
	$('#quick-connect').append "<li connect='test'><a href='#'>空白测试页面</a></li>"
	$('#quick-connect').menu
		select: (event, ui) ->
			selected = ui.item.attr('connect')
			if selected == 'test'
				webterm.test.new_tab()
			else
				address_index = parseInt selected
				webterm.address_book.connect address_index
				$('#quick-connect').hide()
	menu_show = -> $('#quick-connect').show()
	menu_hide = -> $('#quick-connect').hide()
	$('#new-menu').hover menu_show, menu_hide

setup_connect_dialog = ->
	tip = null
	$("#connect-dialog").dialog
		autoOpen: false
#		height: 300
		width: 380
		modal: true
		resizable: false
		buttons: [
			id: 'connect-ok'
			text: '连接'
			click: ->
				webterm.new_bbs_tab
					icon: $('#connect-icon > img').attr 'src'
					name: $('#connect-host').val()
					host: $('#connect-host').val()
					port: parseInt $('#connect-port').val()
					module: webterm.bbs[$('#connect-type').val().toLowerCase()]
				$(@).dialog 'close'
		,
			id: 'connect-cancel'
			text: '取消'
			click: ->
				$(@).dialog 'close'
		]
		open: ->
			tip = webterm.status_bar.tip '按上下键选择收藏夹中的站点'
		close: ->
			tip?.close()
			tip = null

	apply_addres  = (address) ->
		$('#connect-host').val address.host
		$('#connect-port').val address.port
		$('#connect-icon > img').attr 'src', address.icon
		$('#connect-type').val switch address.module
			when webterm.bbs.smth then 'SMTH'
			when webterm.bbs.lily then 'LILY'
			when webterm.bbs.firebird then 'Firebird'
		$('#connect-dialog').dialog "option", "title", "连接到#{address.name}"

	switch_address = (n) ->
		current = parseInt $('#connect-host').attr('connect') ? 0
		selected = (current + n + webterm.address_book.size()) % webterm.address_book.size()
		apply_addres webterm.address_book.nth selected
		$('#connect-host').attr 'connect', selected

	$('#connect-host').keydown (e) ->
		k = keymap.event_to_virtual_key e
		if k == 'up'
			switch_address -1
			e.preventDefault()
		else if k == 'down'
			switch_address 1
			e.preventDefault()
		else if k == 'enter'
			$('#connect-ok').click()

	$('#connect-host').on 'input', (e) ->
		host = $(@).val()
		address = webterm.address_book.lookup_host host
		$('#connect-dialog').dialog "option", "title", "连接到#{address?.name ? ''}"
		$('#connect-icon > img').attr 'src', address?.icon ? 'lib/webterm.png'

	$('#connect-book').menu
		select: (event, ui) ->
			selected = ui.item.attr('connect')
			address_index = parseInt selected
			address = webterm.address_book.nth address_index
			apply_addres address
			$('#connect-book').hide()
	menu_show = -> $('#connect-book').show()
	menu_hide = -> $('#connect-book').hide()
	$('#connect-icon').hover menu_show, menu_hide

	switch_address 0

setup_settings_dialog = ->
	$('#settings').click ->
		$('#settings-dialog').dialog 'open'
	$("#settings-dialog").dialog
		autoOpen: false
		modal: true
		width: 400
		height: 200
		resizeStop: ->
			init_editor.resize()
			session_editor.resize()
	$('#settings-tabs').tabs
		activate: (event, ui) ->
			id = $(ui.newPanel.selector + '.ace_editor').attr 'id'
			if id?
				editor = ace.edit id
				editor.focus()
	# init
	init_editor = webterm.editors.ace_coffee_editor
		id: 'settings-init-script-editor'
		code: webterm.settings.get("scripts.init")?.coffeescript
		listener: (code) -> webterm.settings.set "scripts.init", code
	# session init
	session_editor = webterm.editors.ace_coffee_editor
		id: 'settings-session-script-editor'
		code: webterm.settings.get("scripts.session")?.coffeescript
		listener: (code) -> webterm.settings.set "scripts.session", code


setup_menu = ->
	$('#menu ul').menu
		select: (event, ui) ->
			id = ui.item.find('a').attr('href')
			if id == '#input-dialog'
				$('#input-dialog').dialog 'open'
			else if id == '#script-dialog'
				$('#script-dialog').dialog 'open'
			else if id == '#status-bar'
				webterm.status_bar.show()
			else if id == '#about-dialog'
				$('#about-dialog').dialog 'open'
			menu_hide()
	menu_show = -> $('#menu ul').show()
	menu_hide = -> $('#menu ul').hide()
	$('#menu').hover menu_show, menu_hide

setup_input_dialog = ->
	post = ->
		text = $('#input-dialog textarea').val()
		webterm.active?.screen?.events.send_text text
	$("#input-dialog").dialog
		autoOpen: false
		modal: false
		width: 400
		height: 200
		buttons: [
			text: '插入'
			click: ->
				post()
				$(@).find('textarea').focus()
		,
			text: '清除'
			click: ->
				$(@).find('textarea').val('')
				$(@).find('textarea').focus()
		,
			text: '关闭'
			click: ->
				$(@).dialog 'close'
		]
	$('#input-dialog textarea').keydown (e) ->
		k = keymap.event_to_virtual_key e
		if k == 'ctrl-enter'
			post()
		else if k == 'ctrl-w'
			post()
			$('#input-dialog').dialog 'close'

setup_script_dialog = ->
	editor = webterm.editors.ace_coffee_editor
		id: 'script-editor'

	$("#script-dialog").dialog
		autoOpen: false
		modal: false
		width: 400
		height: 200
		buttons: [
			text: '打开'
			click: ->
				webterm.dialogs.file_open accepts: [extensions: ['coffee']], (script) ->
					editor.getSession().setValue script
					editor.focus()
		,
			text: '运行'
			click: ->
				webterm.eval editor.getSession().getValue()
				editor.focus()
		,
			text: '清除'
			click: ->
				editor.getSession().setValue()
				editor.focus()
		,
			text: '关闭'
			click: ->
				$(@).dialog 'close'
		]
		resizeStop: ->
			editor.resize()

	webterm.dnd.drag_data_to '#script-dialog', (data) ->
		items = _.filter data.items, (item) -> item.kind == 'file'
		if items.length == 0
			return
		if items.length > 1
			console.log 'too many files'
		item = items[0]
		chosenFileEntry = item.webkitGetAsEntry()
		chrome.fileSystem.getDisplayPath chosenFileEntry, (path) ->
			if not path.match /\.coffee$/
				console.log 'not a .coffee file'
				return
			chosenFileEntry.file (file) ->
				reader = new FileReader()
				reader.onerror = (e) ->
					console.log 'open file error!', arguments
				reader.onload = (e) ->
					editor.getSession().setValue e.target.result
				reader.readAsText file
	$('#script-dialog').on 'dragover', (e) ->
		e.originalEvent.preventDefault()

setup_about = ->
	$('#about-dialog').dialog
		autoOpen: false
		modal: true
		width: 400
		open: ->
			webterm.resources.get_text 'manifest.json', (text) ->
				webterm_version = JSON.parse(text).version
				chrome_version = window.navigator.appVersion.match(/Chrom(?:e|ium)\/\S+/)?[0] ? 'Chrome version unknown'
				$('#about-version').text "Webterm/#{webterm_version}, #{chrome_version}"

setup = ->
	Object.defineProperty webterm, 'active',
		get: ->
			webterm.tabs.active?.session
	Object.defineProperty webterm, 'screen',
		get: ->
			webterm.active?.screen
	webterm.keys.root.chain = (e) ->
		webterm.active?.screen.events.on_keyboard e

	webterm.tabs.on 'new', ->
		# TODO: customize behavior
		$("#connect-dialog").dialog 'open'

	webterm.keys.on 'alt-f4', -> webterm.windows.safe_close()
	webterm.keys.on 'ctrl-shift-i', -> $('#input-dialog').dialog 'open'
	webterm.keys.on 'f5', -> $('#script-dialog').dialog 'open'
	webterm.keys.on 'f8', -> $('#settings-dialog').dialog 'open'
	webterm.keys.on 'f12', webterm.windows.toggle_full_screen

#	webterm.test.new_tab() # for testing
	$("#connect-dialog").dialog 'open'
	webterm.keys.on 'ctrl-n', webterm.test.new_tab # for testing
	webterm.keys.on 'ctrl-shift-s', webterm.test.save_current_screen # for testing
	webterm.keys.on 'ctrl-shift-l', webterm.test.load # for testing
#	$("#connect-dialog").dialog 'open' # for testing
#	$("#settings-dialog").dialog 'open' # for testing

	webterm.windows.on_closed ->
		# FIXME: XXX: this doesn't work?
		webterm.cache.save()
	setInterval webterm.cache.save, 30000 # XXX: auto save every 30s -- just a workaround to above

setup_font = ->
	resize()
	$(window).resize resize
#	$(window).resize ->
#		$('.screen').css 'z-index': 1
	webterm.tabs.on 'create', resize

init = ->
	init = webterm.settings.get("scripts.init")
	if init?
		webterm.eval init.coffeescript

webterm.init ->
	setup_address_book()
	setup_quick_connect()
	setup_connect_dialog()
	setup_settings_dialog()
	setup_menu()
	setup_input_dialog()
	setup_script_dialog()
	setup_about()
	setup()
	setup_font()
	init()
