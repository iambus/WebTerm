
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
	constructor: (@name) ->
		if not @name
			@name = @constructor.name
	scan: (screen) ->
	render: (screen) ->

class Mode
	constructor: (@name) ->
		if not @name
			@name = @constructor.name
		console.log 'mode', @name
	scan: (screen) ->
	render: (screen) ->

class FeaturedMode extends Mode
	constructor: (@name, @features) ->
		super @name
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

featured_mode = (name, features) ->
	->
		return new FeaturedMode name, (new feature for feature in features)

featured_mode_by = (test, name, features) ->
	(screen) ->
		if test screen
			featured_mode(name, features)()

test_headline = (regexp) ->
	(screen) ->
		regexp.test headline screen

test_footline = (regexp) ->
	(screen) ->
		regexp.test footline screen




load_mode = (screen, modes, global_mode) ->
	for mode in modes
		m = mode(screen)
		if m?
			return new CompositeMode m.name, [m, global_mode()]
	return global_mode()

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
	utils:
		featured_mode: featured_mode
		featured_mode_by: featured_mode_by
		test_headline: test_headline
		test_footline: test_footline

if module?.exports?
	module.exports = exports
else
	this.bbs = this.bbs ? {}
	this.bbs.mode = exports

