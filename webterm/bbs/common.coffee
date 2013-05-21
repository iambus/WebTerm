
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
	send_key: (screen, k) ->
		for x in k.split(' ')
			if /^\[.+\]$/.test x
				screen.events.put_text x.substring 1, x.length - 1
			else
				screen.events.put_key x
			screen.events.send()
	click: (screen, div) ->
		k = div.getAttribute('key')
		if k
			@send_key screen, k
	render: (screen) ->
		screen.events.on_click_div 'div.bbs-clickable:not(.bbs-menu), div.bbs-clickable.bbs-menu > span', (div) =>
			@click screen, div
		screen.events.on_click '.bbs-menu ul li.bbs-clickable', (li) =>
			@click screen, li

class BBSMenu extends Feature
	render_menu: (screen, selector, menus, callback) ->
		# generate menu html
		html = ['<ul>']
		for menu in menus
			if _.isString menu
				html.push "<li><a href='#'>#{menu}</a>"
			else
				html.push "<li"
				for k, v of menu
					if k != 'text'
						html.push " #{k}='#{v}'"
				html.push "><a href='#'>"
				html.push menu.text
				html.push "</a></li>"
		html.push "</ul>"
		ul = html.join ''
#		menus = ((if _.isString menu then text: menu else menu) for menu in menus)
#		ul = """<ul>#{("<li #{("#{k}='#{v}'" for k, v of menu).join('')}><a href='#'>#{menu.text}</a></li>" for menu in menus).join ''}</ul>"""
		# create menu
		div = $(screen.selector).find(selector).append(ul)
		ul = div.find('ul')
		ul.hide().css('position', 'fixed').menu
			select: (event, ui) ->
				callback? ui.item
				ui.item.parent().hide()
		# fix menu position
		{top, left} = div.offset()
		if $(screen.selector).width() < left - $(screen.selector).offset().left + ul.width()
			top += div.height()
			left -= ul.width() - div.find('span').width() + 3
			ul.offset top: top, left: left
		# done!
		menu_show = (e) -> $(e.currentTarget).find('ul').show()
		menu_hide = (e) -> $(e.currentTarget).find('ul').hide()
		div.hover menu_show, menu_hide

##################################################
# exports
##################################################

exports =
	MouseGestureFeature: MouseGestureFeature
	Clickable: Clickable
	BBSMenu: BBSMenu

if module?.exports?
	module.exports = exports
else
	this.webterm.bbs.common = exports

