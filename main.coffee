

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

connect = (host, port) ->
	connection = new telnet.Connection host, port
	connection.connect()

	screen = new Screen

	bbs.smth(screen)

	connection.on_data = (data) =>
		screen.fill_ascii_raw data
		screen.render()

	screen.on_data = (data) ->
		connection.write_data data

	window.screen = screen # XXX: for debugging

test = ->
	screen = new Screen

	bbs.smth(screen)

	chrome_get = (url, callback) ->
		url = chrome.runtime.getURL url
		xhr = new XMLHttpRequest
		xhr.responseType = 'arraybuffer'
		xhr.onreadystatechange = ->
			if xhr.readyState == 4
				callback xhr.response
		xhr.open("GET", url, true)
		xhr.send()

	load_ascii = (screen, resources...) ->
		load_ascii_at = (i) ->
			if i < resources.length
				chrome_get "test/" + resources[i], (data) ->
					screen.fill_ascii_raw new Uint8Array data
					load_ascii_at i+1
			else
				screen.render()
		load_ascii_at 0

#	load_ascii screen, 'smth_menu_main_1', 'smth_menu_main_2'
#	load_ascii screen, 'smth_list_1', 'smth_list_2'
#	load_ascii screen, 'smth_read_a_1', 'smth_read_a_2', 'smth_read_a_3'
#	load_ascii screen, 'smth_long_url'
#	load_ascii screen, 'smth_logout'
#	load_ascii screen, 'board_list_1', 'board_list_2'
#	load_ascii screen, 'board_group_1', 'board_group_2', 'board_group_3', 'board_group_4', 'board_group_5'
#	load_ascii screen, 'smth_user_1'
	load_ascii screen, 'login_error_1', 'login_error_2', 'login_error_3', 'login_error_4', 'login_error_5'

	window.screen = screen # XXX: for debugging

host = 'bbs.newsmth.net'
#host = 'bbs.nju.edu.cn'

#resize()
#$(window).resize ->
#	resize()
$(window).resize ->
	$('#screen').css 'z-index': 1
#test()
connect(host)
