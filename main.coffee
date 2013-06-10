

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
	$('#quick-connect').empty()
	$('#connect-book').empty()
	for {name, host, port, protocol, module, icon, user_defined}, i in webterm.address_book.get_list()
		css = if user_defined then 'user_defined' else ''
		if icon
			li = "<li connect='#{i}' class='#{css}'><a href='#}'><img src='#{icon}'/>#{name}</a></li>"
		else
			li = "<li connect='#{i}' class='#{css}'><a href='#'>#{name}</a></li>"
		$('#quick-connect').append li
		$('#connect-book').append li

update_address_book = ->
	setup_address_book()
	$('#quick-connect').menu 'refresh'
	$('#connect-book').menu 'refresh'

setup_quick_connect = ->
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
			id: 'connect-add'
			text: '添加此地址'
			click: ->
				$('#connect-add-name').dialog 'open'
				name = $('#connect-dialog').dialog('option', 'title').match('^连接到(.+)$')?[1]
				if name
					$('#connect-add-name input').val name
					$('#connect-add-name input').select()
		,
#			id: 'connect-manage'
#			text: '管理'
#			click: ->
#				$(@).dialog 'close'
#		,
			id: 'connect-cancel'
			text: '取消'
			click: ->
				$(@).dialog 'close'
		,
			id: 'connect-ok'
			text: '连接'
			click: ->
				webterm.new_bbs_tab
					icon: $('#connect-icon > img').attr 'src'
					name: $('#connect-dialog').dialog('option', 'title').match('^连接到(.+)$')?[1] ? $('#connect-host').val()
					host: $('#connect-host').val()
					port: parseInt $('#connect-port').val()
					module: $('#connect-type').val().toLowerCase()
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
			$('#connect-host').attr 'connect', address_index
			$('#connect-book').hide()
	menu_show = -> $('#connect-book').show()
	menu_hide = -> $('#connect-book').hide()
	$('#connect-icon').hover menu_show, menu_hide

	switch_address 0 # init dialog to address #0

	$("#connect-add-name").dialog
		autoOpen: false
		height: 120
		modal: true
		buttons: [
			text: '添加'
			click: ->
				new_index = webterm.address_book.add
					icon: $('#connect-icon > img').attr 'src'
					name: $(@).find('input').val()
					host: $('#connect-host').val()
					port: parseInt $('#connect-port').val()
					module: $('#connect-type').val().toLowerCase()
				update_address_book()
				old_index = parseInt $('#connect-host').attr('connect') ? 0
				if new_index <= old_index
					$('#connect-host').attr 'connect', old_index + 1
				$(@).dialog 'close'
				$('#connect-host').focus()
		,
			text: '取消'
			click: ->
				$(@).dialog 'close'
				$('#connect-host').focus()
		]

		$.contextMenu
			selector: '#connect-host'
			build: ($trigger, e) ->
				menu =
					callback: ->
						index = $('#connect-host').attr('connect') ? 0
						removed = webterm.address_book.remove index
						if removed?
							update_address_book()
							webterm.status_bar.info '删除地址成功'
							switch_address index
						else
							webterm.status_bar.info '不能删除此地址（此地址可能为内置地址）'
					items: [
						id: 'delete'
						name: '删除此地址'
						icon: 'delete'
					]
				return menu

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
