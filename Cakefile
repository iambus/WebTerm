

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
			console.error red "something wrong! coffee: #{options}"

download = (url, path) ->
	console.log green('http'), url, '->', path
	out = fs.createWriteStream path
	request = http.get url, (response) ->
		response.pipe out
	request.on 'error', (e) ->
		console.error red e

download_depends = ->
	libs =
		'http://code.jquery.com/jquery-1.9.1.js': 'lib/jquery-1.9.1.js'
		'http://underscorejs.org/underscore.js': 'lib/underscore.js'
	if not fs.existsSync 'lib'
		fs.mkdirSync 'lib'
	for url, path of libs
		if not fs.existsSync path
			download url, path
