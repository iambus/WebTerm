
##################################################
# imports
##################################################

if module?.exports?
	mode = require './mode'
else
	mode = bbs.mode
	if not mode
		throw Error("bbs.mode is not loaded")

plugin = mode.plugin



##################################################
# exports
##################################################

exports = ->

if module?.exports?
	module.exports = exports
else
	this.bbs = this.bbs ? {}
	this.bbs.nju = exports

