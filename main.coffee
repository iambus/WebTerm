

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


host = 'bbs.newsmth.net'
#host = 'bbs.nju.edu.cn'

#resize()
#$(window).resize ->
#	resize()
$(window).resize ->
	$('#screen').css 'z-index': 1

storage.init ->
#	test()
	connect(host)
