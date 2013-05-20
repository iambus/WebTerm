
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
	mode = webterm.bbs.mode
	if not mode
		throw Error("webterm.bbs.mode is not loaded")

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
				console.error "Invalid mouse gesture handler: #{k} -> #{v}"


class Clickable extends Feature
	render: (screen) ->
		screen.events.on_click_div 'div.bbs-clickable:not(.bbs-menu), div.bbs-clickable.bbs-menu > span', (div) ->
			k = div.getAttribute('key')
			if k
				for x in k.split(' ')
					if /^\[.+\]$/.test x
						screen.events.put_text x.substring 1, x.length - 1
					else
						screen.events.put_key x
					screen.events.send()


##################################################
# exports
##################################################

exports =
	MouseGestureFeature: MouseGestureFeature
	Clickable: Clickable

if module?.exports?
	module.exports = exports
else
	this.webterm.bbs.common = exports

