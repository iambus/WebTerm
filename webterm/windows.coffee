
close = ->
	window.close()

safe_close = ->
	if webterm.tabs.count() > 0
		for i in [0...webterm.tabs.count()]
			if webterm.tabs.nth(i).session?.connection?.is_connected()
				$('#close-window-confirm-dialog').dialog 'open'
				return
		close()
	else
		close()

if webterm.platform == 'node-webkit'
	gui = require 'nw.gui'
	win = gui.Window.get()
	maximized = false

minimize = ->
	if webterm.platform == 'chrome'
		chrome.app.window.current().minimize()
	else if webterm.platform == 'node-webkit'
		win.minimize()

maximize = ->
	if webterm.platform == 'chrome'
		chrome.app.window.current().maximize()
	else if webterm.platform == 'node-webkit'
		win.maximize()

restore = ->
	if webterm.platform == 'chrome'
		chrome.app.window.current().restore()
	else if webterm.platform == 'node-webkit'
		win.restore()

is_maximized = ->
	if webterm.platform == 'chrome'
		chrome.app.window.current().isMaximized()
	else if webterm.platform == 'node-webkit'
		maximized

on_closed = (callback) ->
	if webterm.platform == 'chrome'
		chrome.app.window.current().onClosed.addListener callback

enter_full_screen = ->
	document.body.webkitRequestFullscreen()

exit_full_screen = ->
	document.webkitExitFullscreen()

toggle_full_screen = ->
	if document.webkitIsFullScreen
		exit_full_screen()
	else
		enter_full_screen()

$ ->
	$('#close-window-confirm-dialog').dialog
		autoOpen: false
		modal: true
		buttons: [
			text: '确认退出'
			click: ->
				close()
		,
			text: '取消'
			click: ->
				$(@).dialog 'close'
		]

	$('#close-window').click safe_close
	$('#min-window').click ->
		minimize()
	$('#max-window').click ->
		if is_maximized()
			restore()
		else
			maximize()

	if webterm.platform == 'chrome'
		chrome.app.window.current().onMaximized.addListener ->
			$('#max-window').attr 'title', '恢复'
		chrome.app.window.current().onRestored.addListener ->
			$('#max-window').attr 'title', '最大化'
	else if webterm.platform == 'node-webkit'
		win.on 'maximize', ->
			$('#max-window').attr 'title', '恢复'
			maximized = true
		win.on 'restore', ->
			$('#max-window').attr 'title', '最大化'
			maximized = false
		win.on 'unmaximize', ->
			$('#max-window').attr 'title', '最大化'
			maximized = false


webterm.windows =
	close: close
	safe_close: safe_close
	minimize: minimize
	maximize: maximize
	restore: restore
	is_maximized: is_maximized
	on_closed: on_closed
	enter_full_screen: enter_full_screen
	exit_full_screen: exit_full_screen
	toggle_full_screen: toggle_full_screen

