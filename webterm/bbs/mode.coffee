
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
	@disable: ->
		@::disabled = true
	@enable: ->
		@::disabled = undefined
	@is_enabled: ->
		not @::disabled
	constructor: ->
		if not @name
			@name = @constructor.name
	scan: (screen) ->
	render: (screen) ->

class Mode
	@disable: ->
		@::disabled = true
	@enable: ->
		@::disabled = undefined
	@is_enabled: ->
		not @::disabled
	constructor: ->
		if not @name
			@name = @constructor.name
		console.log 'mode', @name
	scan: (screen) ->
	render: (screen) ->

class FeaturedMode extends Mode
	@reset_features: (features) ->
		@::features = features
	@add_feature: (feature) ->
		@::features.push feature
	@remove_feature: (feature) ->
		i = @::features.indexOf feature
		if i != -1
			@::features.splice i, 1
	constructor: ->
		if not @features
			throw Error("#{@constructor.name} doesn't provide @features")
		@features = (new feature for feature in @features)
	scan: (screen) ->
		for feature in @features
			if not feature.disabled
				feature.scan screen
	render: (screen) ->
		for feature in @features
			if not feature.disabled
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
		if mode.is_enabled() and mode.check?(screen)
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
	this.webterm.bbs = this.webterm.bbs ? {}
	this.webterm.bbs.mode = exports

