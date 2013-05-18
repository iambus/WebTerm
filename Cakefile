

task 'build', 'compile source', ->
	coffee ['-c', '.']

task 'watch', 'compile source and watch', ->
	coffee ['-w', '-c', '.'], (s) ->
		console.log s.replace /^In .*, Parse error on line \d+.+$/m, red s

task 'deps', 'Install dependencies', ->
	download_depends()

##################################################
# dirty implementation
##################################################

fs = require 'fs'
path = require 'path'
{spawn} = require 'child_process'
http = require 'http'

coffee_bin = ->
	if process.platform =='win32' then 'coffee.cmd' else 'coffee'

green = (m) -> "\x1b[0;32m#{m}\x1b[m"
red = (m) -> "\x1b[1;31m#{m}\x1b[m"

coffee = (args, on_stdout, on_stderr) ->
	app = spawn coffee_bin(), args
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
			console.error red "something wrong! coffee: #{args}"

download = (url, file) ->
	dir = path.dirname file
	if not fs.existsSync dir
		fs.mkdirSync dir
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
		'http://underscorejs.org/underscore.js': 'lib/underscore.js'
		'http://coffeescript.org/extras/coffee-script.js': 'lib/coffee-script.js'
		'http://iambus.github.io/static/CoffeeScriptEval.js': 'lib/CoffeeScriptEval.js'
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
		if not fs.existsSync file
			download url, file
	download_jquery_ui()
