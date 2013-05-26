
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
	click: (screen, div) ->
		k = div.getAttribute('key')
		if k
			screen.events.send_key_sequence_string k
	render: (screen) ->
		screen.events.on_click_div 'div.bbs-clickable:not(.bbs-menu), div.bbs-clickable.bbs-menu > span', (div) =>
			@click screen, div
		screen.events.on_click '.bbs-menu ul li.bbs-clickable', (li) =>
			@click screen, li

class BBSMenu extends Feature
	render_menu: (screen, selector, menus, callback) ->
		div = $(screen.selector).find(selector)
		if div.length == 0
			return
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
		div.append(ul)
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


class URLRecognizer extends Feature
	scan: (screen) ->
		text = screen.view.text.full()
		url_regexp = /http:\/\/[\w:\/?&=%+(@)$;._-]+/g
		while m = url_regexp.exec text
			start = wcwidth(text.substring(0, m.index))
			end = start + m[0].length - 1
			top = Math.floor(start / screen.width) - 1
			left = start - screen.width * (top - 1) + 1
			bottom = Math.floor(end / screen.width) - 1
			right = end - screen.width * (bottom - 1) + 1
			screen.area.define_area 'href', top, left, bottom, right
		screen.context_menus.register
			id: 'open_url'
			title: '打开链接'
			onclick: (context) ->
				url = $(context.target).closest('a').attr 'href'
				if url
					window.open url
			context: 'link'
		screen.context_menus.register
			id: 'copy_url'
			title: '复制链接地址'
			onclick: (context) ->
				url = $(context.target).closest('a').attr 'href'
				if url?
					webterm.clipboard.put url
			context: 'link'
		screen.context_menus.register
			id: 'save_url'
			title: '链接另存为'
			icon: 'download'
			onclick: (context) ->
				url = $(context.target).closest('a').attr 'href'
			context: 'link'
		screen.context_menus.register
			id: 'open_as_url'
			title: '将选中内容作为链接打开'
			onclick: (context) ->
				url = screen.selection?.get_selected_text()?.replace /\n/g, ''
				if url
					window.open url
			context: 'selection'

	render: (screen) ->
		$('div.href').replaceWith ->
			"<a href='#{$(@).text()}' target='_blank'>#{$(@).html()}</a>"

class ImagePreview extends Feature
	render: (screen) ->
		$(screen.selector).find('a').preview()


##################################################
# exports
##################################################

exports =
	MouseGestureFeature: MouseGestureFeature
	Clickable: Clickable
	BBSMenu: BBSMenu
	URLRecognizer: URLRecognizer
	ImagePreview: ImagePreview

if module?.exports?
	module.exports = exports
else
	this.webterm.bbs.common = exports

