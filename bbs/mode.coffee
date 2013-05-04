
##################################################
# imports
##################################################


##################################################
# ...
##################################################

headline = (screen) ->
	screen.view.text.head()

footline = (screen) ->
	screen.view.text.foot()

class Feature
	constructor: ->
		if not @name
			@name = @constructor.name
	scan: (screen) ->
	render: (screen) ->

class Mode
	constructor: ->
		if not @name
			@name = @constructor.name
		console.log 'mode', @name
	scan: (screen) ->
	render: (screen) ->

class FeaturedMode extends Mode
	constructor: ->
		if not @features
			throw Error("#{@constructor.name} doesn't provide @features")
		@features = (new feature for feature in @features)
	scan: (screen) ->
		for feature in @features
			feature.scan screen
	render: (screen) ->
		for feature in @features
			feature.render screen

class CompositeMode extends Mode
	constructor: (@name, @modes) ->
		super @name
	scan: (screen) ->
		for mode in @modes
			mode.scan screen
	render: (screen) ->
		for mode in @modes
			mode.render screen

test_headline = (regexp) ->
	(screen) ->
		regexp.test headline screen

test_footline = (regexp) ->
	(screen) ->
		regexp.test footline screen




load_mode = (screen, modes, global_mode) ->
	for mode in modes
		if mode.check?(screen)
			m = new mode()
			return new CompositeMode m.name, [ m, new global_mode]
	return new global_mode

plugin = (screen, modes, global_mode) ->
	screen.on_screen_updated = ->
		m = screen.mode = load_mode screen, modes, global_mode
		m?.scan screen
	screen.on_screen_rendered = ->
		screen.mode?.render screen
	screen



##################################################
# exports
##################################################

exports =
	plugin: plugin
	Mode: Mode
	Feature: Feature
	FeaturedMode: FeaturedMode
	utils:
		test_headline: test_headline
		test_footline: test_footline

if module?.exports?
	module.exports = exports
else
	this.bbs = this.bbs ? {}
	this.bbs.mode = exports

