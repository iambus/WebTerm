
##################################################
# imports
##################################################

if module?.exports?
	mode = require './mode'
else
	mode = webterm.bbs.mode
	if not mode
		throw Error("webterm.bbs.mode is not loaded")

plugin = mode.plugin



##################################################
# exports
##################################################

exports = ->

if module?.exports?
	module.exports = exports
else
	this.webterm.bbs.firebird = exports

