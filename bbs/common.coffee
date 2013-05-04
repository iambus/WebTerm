
##################################################
# imports
##################################################

if module?.exports?
	$ = require 'jQuery'
	_ = require 'underscore'
	mode = require './mode'
else
	$ = this.$
	_ = this._
	mode = bbs.mode
	if not mode
		throw Error("bbs.mode is not loaded")

Feature = mode.Feature

##################################################
# features
##################################################

class MouseGestureFeature extends Feature
	constructor: (@gestures) ->
		super()
	scan: (screen) ->
		$.each @gestures, (k, v) ->
			if _.isString v
				screen.events.on_mouse_gesture k, ->
					screen.events.send_key v
			else if _.isFunction v
				screen.events.on_mouse_gesture k, v
			else
				consolo.error "Invalid mouse gesture handler: #{k} -> #{v}"


##################################################
# exports
##################################################

exports =
	MouseGestureFeature: MouseGestureFeature

if module?.exports?
	module.exports = exports
else
	this.bbs = this.bbs ? {}
	this.bbs.common = exports

