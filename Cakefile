

task 'build', 'Compile source', ->
	coffee ['-c', '.']

task 'watch', 'Compile source and watch', ->
	coffee ['-w', '-c', '.'],
		on_stdout: (s) ->
			console.log s.replace /^.*\.coffee:\d+:\d+: error:[\s\S]*$/m, red s
		auto_recover: true

task 'deps', 'Install dependencies', ->
	download_depends()

task 'out', 'Build release to out dir', ->
	build_out()

##################################################
# dirty implementation
##################################################

fs = require 'fs'
path = require 'path'
{spawn} = require 'child_process'
http = require 'http'
https = require 'https'

coffee_bin = ->
	if process.platform =='win32' then 'coffee.cmd' else 'coffee'

green = (m) -> "\x1b[0;32m#{m}\x1b[m"
red = (m) -> "\x1b[1;31m#{m}\x1b[m"

spawn_with_auto_recover = (command, args, on_stdout, on_stderr, auto_recover) ->
	start = new Date
	app = spawn command, args
	app.stdout.on 'data', (data) ->
		s = data.toString().trim()
		if on_stdout?
			on_stdout s
		else
			console.log s
	app.stdout.on 'error', (data) ->
		s = data.toString().trim()
		if on_stderr
			on_stderr s
		else
			console.error red s
	app.on 'close', (code) ->
		if code != 0
			console.error red "something wrong! #{command}: #{args}"
			end = new Date
			if auto_recover and end - start > 5000
				console.error green "restarting..."
				spawn_with_auto_recover command, args
			else
				console.error red "abort!"

coffee = (args, {on_stdout, on_stderr, auto_recover}) ->
	spawn_with_auto_recover coffee_bin(), args, on_stdout, on_stderr, auto_recover

mkdir = (dir) ->
	if not fs.existsSync dir
		parent = path.dirname dir
		if not fs.existsSync parent
			mkdir parent
		fs.mkdirSync dir

download = (url, file) ->
	mkdir path.dirname file
	if url.match /^https:/
		console.log green('https'), url, '->', file
		request = https.get url, (response) ->
			response.pipe fs.createWriteStream file
	else
		console.log green('http'), url, '->', file
		request = http.get url, (response) ->
			response.pipe fs.createWriteStream file
	request.on 'error', (e) ->
		console.error red e

download_jquery_ui = ->
	zip = 'lib/jquery-ui-1.10.2.custom.zip'
	if fs.existsSync zip
		return

	url = 'http://download.jqueryui.com/download'
	form =
		'version': '1.10.2'
		'core': 'on'
		'widget': 'on'
		'mouse': 'on'
		'position': 'on'
		'draggable': 'on'
		'droppable': 'on'
		'resizable': 'on'
		'selectable': 'on'
		'sortable': 'on'
		'accordion': 'on'
		'autocomplete': 'on'
		'button': 'on'
		'datepicker': 'on'
		'dialog': 'on'
		'menu': 'on'
		'progressbar': 'on'
		'slider': 'on'
		'spinner': 'on'
		'tabs': 'on'
		'tooltip': 'on'
		'effect': 'on'
		'effect-blind': 'on'
		'effect-bounce': 'on'
		'effect-clip': 'on'
		'effect-drop': 'on'
		'effect-explode': 'on'
		'effect-fade': 'on'
		'effect-fold': 'on'
		'effect-highlight': 'on'
		'effect-pulsate': 'on'
		'effect-scale': 'on'
		'effect-shake': 'on'
		'effect-slide': 'on'
		'effect-transfer': 'on'
		'theme-folder-name': 'ui-lightness'
		'scope': ''
	request = require 'request'
	console.log green('http'), url, '->', zip
	request.post(url, form: form).pipe(fs.createWriteStream(zip)).on 'close', ->
		AdmZip = require('adm-zip')
		zip = new AdmZip(zip)
		zip.extractAllTo 'lib/'

download_depends = ->
	libs =
		'http://code.jquery.com/jquery-1.9.1.js': 'lib/jquery-1.9.1.js'
		'http://code.jquery.com/jquery-1.9.1.min.js': 'lib/jquery-1.9.1.min.js'
		'http://underscorejs.org/underscore.js': 'lib/underscore.js'
		'http://documentcloud.github.io/underscore/underscore-min.js': 'lib/underscore-min.js'
		'http://coffeescript.org/extras/coffee-script.js': 'lib/coffee-script.js'
		'http://iambus.github.io/static/CoffeeScriptEval.js': 'lib/CoffeeScriptEval.js'
		'https://raw.github.com/ajaxorg/ace-builds/master/src-min-noconflict/ace.js': 'lib/ace/ace.js'
		'https://raw.github.com/ajaxorg/ace-builds/master/src-min-noconflict/mode-coffee.js': 'lib/ace/mode-coffee.js'
		'https://raw.github.com/ajaxorg/ace-builds/master/src-min-noconflict/worker-coffee.js': 'lib/ace/worker-coffee.js'
		'https://raw.github.com/ajaxorg/ace-builds/master/src-min-noconflict/theme-merbivore_soft.js': 'lib/ace/theme-merbivore_soft.js'
		'https://raw.github.com/medialize/jQuery-contextMenu/master/src/jquery.contextMenu.js': 'lib/jQuery-contextMenu/jquery.contextMenu.js'
		'https://raw.github.com/medialize/jQuery-contextMenu/master/src/jquery.contextMenu.css': 'lib/jQuery-contextMenu/jquery.contextMenu.css'
		'https://raw.github.com/medialize/jQuery-contextMenu/master/src/images/cut.png': 'lib/jQuery-contextMenu/images/'
		'https://raw.github.com/medialize/jQuery-contextMenu/master/src/images/door.png': 'lib/jQuery-contextMenu/images/'
		'https://raw.github.com/medialize/jQuery-contextMenu/master/src/images/page_white_add.png': 'lib/jQuery-contextMenu/images/'
		'https://raw.github.com/medialize/jQuery-contextMenu/master/src/images/page_white_copy.png': 'lib/jQuery-contextMenu/images/'
		'https://raw.github.com/medialize/jQuery-contextMenu/master/src/images/page_white_delete.png': 'lib/jQuery-contextMenu/images/'
		'https://raw.github.com/medialize/jQuery-contextMenu/master/src/images/page_white_edit.png': 'lib/jQuery-contextMenu/images/'
		'https://raw.github.com/medialize/jQuery-contextMenu/master/src/images/page_white_paste.png': 'lib/jQuery-contextMenu/images/'
		'http://www.newsmth.net/favicon.ico': 'lib/smth.ico'
		'http://lilybbs.net/favicon.ico': 'lib/lily.ico'
		'http://bbs.byr.cn/favicon.ico': 'lib/byr.ico'
		'http://bbs.sjtu.edu.cn/favicon.ico': 'lib/sjtu.ico'
		'http://bbs.fudan.edu.cn/favicon.ico': 'lib/fudan.ico'
		'http://bbs.pku.edu.cn/favicon.ico': 'lib/pku.ico'
		'http://bbs.seu.edu.cn/favicon.ico': 'lib/seu.ico'
		'http://bbs.whnet.edu.cn/favicon.ico': 'lib/whnet.ico'
		'http://bbs.whu.edu.cn/favicon.ico': 'lib/whu.ico'
		'http://bbs.xjtu.edu.cn/favicon.ico': 'lib/xjtu.ico'
	for url, file of libs
		if file.match /\/$/
			file += path.basename url
		if not fs.existsSync file
			download url, file
	download_jquery_ui()

copy_file = (src, target) ->
	mkdir path.dirname target
	fs.createReadStream(src).pipe fs.createWriteStream(target)

build_out = ->
	if fs.existsSync 'out'
		fs.renameSync 'out', 'out-' + new Date().getTime()
	mkdir 'out'
	files = [
		'manifest.json'
		'settings.json'
		'main.html'
		'jquery-ui-custom.css'
		'main.css'
		'encoding-indexes.js'
		'encoding.js'
		'gesture.js'
		'keymap.js'
		'launch.js'
		'logger.js'
		'main.js'
		'preview.js'
		'telnet.js'
		'test.js'
		'wcwidth.js'
		'webterm.js'
		'webterm/bbs/common.css'
		'webterm/bbs/common.js'
		'webterm/bbs/firebird.js'
		'webterm/bbs/lily.js'
		'webterm/bbs/list.js'
		'webterm/bbs/mode.js'
		'webterm/bbs/smth.css'
		'webterm/bbs/smth.js'
		'webterm/cache.js'
		'webterm/clipboard.js'
		'webterm/dialogs.js'
		'webterm/editors.js'
		'webterm/eval.js'
		'webterm/init.js'
		'webterm/keys.js'
		'webterm/resources.js'
		'webterm/screen.css'
		'webterm/screen.js'
		'webterm/settings.js'
		'webterm/storage.js'
		'webterm/tabs.js'
		'webterm/windows.js'
		'webterm/status_bar.js'
		'webterm/ip.js'

		'lib/byr.ico'
		'lib/fudan.ico'
		'lib/lily.ico'
		'lib/pku.ico'
		'lib/seu.ico'
		'lib/sjtu.ico'
		'lib/smth.ico'
		'lib/whnet.ico'
		'lib/whu.ico'
		'lib/xjtu.ico'

		'lib/CoffeeScriptEval.js'
		'lib/coffee-script.js'
		'lib/underscore-min.js'
		'lib/jquery-1.9.1.min.js'
		'lib/jquery-ui-1.10.2.custom/css/ui-lightness/images/animated-overlay.gif'
		'lib/jquery-ui-1.10.2.custom/css/ui-lightness/images/ui-bg_flat_0_aaaaaa_40x100.png'
		'lib/jquery-ui-1.10.2.custom/css/ui-lightness/images/ui-bg_flat_75_ffffff_40x100.png'
		'lib/jquery-ui-1.10.2.custom/css/ui-lightness/images/ui-bg_glass_55_fbf9ee_1x400.png'
		'lib/jquery-ui-1.10.2.custom/css/ui-lightness/images/ui-bg_glass_65_ffffff_1x400.png'
		'lib/jquery-ui-1.10.2.custom/css/ui-lightness/images/ui-bg_glass_75_dadada_1x400.png'
		'lib/jquery-ui-1.10.2.custom/css/ui-lightness/images/ui-bg_glass_75_e6e6e6_1x400.png'
		'lib/jquery-ui-1.10.2.custom/css/ui-lightness/images/ui-bg_glass_95_fef1ec_1x400.png'
		'lib/jquery-ui-1.10.2.custom/css/ui-lightness/images/ui-bg_highlight-soft_75_cccccc_1x100.png'
		'lib/jquery-ui-1.10.2.custom/css/ui-lightness/images/ui-icons_222222_256x240.png'
		'lib/jquery-ui-1.10.2.custom/css/ui-lightness/images/ui-icons_2e83ff_256x240.png'
		'lib/jquery-ui-1.10.2.custom/css/ui-lightness/images/ui-icons_454545_256x240.png'
		'lib/jquery-ui-1.10.2.custom/css/ui-lightness/images/ui-icons_888888_256x240.png'
		'lib/jquery-ui-1.10.2.custom/css/ui-lightness/images/ui-icons_cd0a0a_256x240.png'
		'lib/jquery-ui-1.10.2.custom/css/ui-lightness/jquery-ui-1.10.2.custom.min.css'
		'lib/jquery-ui-1.10.2.custom/js/jquery-ui-1.10.2.custom.min.js'
		'lib/ace/ace.js'
		'lib/ace/mode-coffee.js'
		'lib/ace/theme-merbivore_soft.js'
		'lib/ace/worker-coffee.js'
		'lib/jQuery-contextMenu/jquery.contextMenu.js'
		'lib/jQuery-contextMenu/jquery.contextMenu.css'
		'lib/jQuery-contextMenu/images/cut.png'
		'lib/jQuery-contextMenu/images/door.png'
		'lib/jQuery-contextMenu/images/page_white_add.png'
		'lib/jQuery-contextMenu/images/page_white_copy.png'
		'lib/jQuery-contextMenu/images/page_white_delete.png'
		'lib/jQuery-contextMenu/images/page_white_edit.png'
		'lib/jQuery-contextMenu/images/page_white_paste.png'

	]
	for f in files
		copy_file f, 'out/' + f
