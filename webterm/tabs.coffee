

add_tab = (id, label, content) ->
	li = """<li><a href="##{id}">#{label}</a><span class="ui-icon ui-icon-close" role="presentation">Remove Tab</span></li>"""
	tabs = $('#tabs')
	tabs.find(".ui-tabs-nav").append(li)
	tabs.find('#main').append "<div id='#{id}'>#{content}</div>"
	tabs.tabs "refresh"
	$('#'+id)[0]

class Tabs
	constructor: (@selector) ->
		@counter = 0
		@registry = {}

		Object.defineProperty @, 'active',
			get: ->
				@get_active_tab()

	init: ->
		@tabs = $(@selector)
		tabs = @tabs.tabs()
		tabs.find(".ui-tabs-nav").sortable
			axis: "x"
			stop: ->
				tabs.tabs "refresh"

	on: (event, callback) ->
		if event == 'new'
			$('#new-tab').click callback
		else if event == 'active'
			@tabs.on 'tabsactivate', (event, ui) ->
				callback
					event: event
					ui: ui
					id: ui.newPanel.attr 'id'
					selector: ui.newPanel.selector

	auto_id: ->
		@counter++
		"new-tab-#{@counter}"

	add: ({id, title, icon, content, data, on_open, on_close, on_closing, on_closed}) ->
		id = id ? @auto_id()
		if icon?
			title = "<img src='#{icon}' class='ui-icon ui-icon-blank'/>#{title}"
		div = add_tab id, title, content
		info =
			id: id
			li: @tabs.find("ul#tab-bar li a[href=##{id}]").parent()
			div: div
			data: data
			on_open: on_open
			on_close: on_close
			on_closing: on_closing
			on_closed: on_closed
		@registry[id] = info
		on_open?(info)
		@tabs.tabs 'option', 'active', @tabs.find("ul#tab-bar li").length - 1

	on_close: (element) ->
		li = $(element).closest("li")
		id = li.attr('aria-controls')
		info = @registry[id]
		todo = =>
			@registry[id]?.on_closing?(info)
			li.remove()
			$("#"+id).remove()
			@tabs.tabs "refresh"
			@registry[id]?.on_closed?(info)
			@registry[id] = undefined
		on_close = info.on_close
		if on_close
			on_close todo
		else
			todo()

	nth_id: (n) ->
		###
		# Note: n start from 0
		###
		@tabs.find("ul#tab-bar li:nth-child(#{n+1})").attr('aria-controls')

	nth_div_selector: (n) ->
		"##{@nth_id n}"

	nth: (n) ->
		@registry[@nth_id(n)]

	get_active_tab: ->
		n = @tabs.tabs 'option', 'active'
		@nth n

$ ->
	webterm.tabs = new Tabs('#tabs')
	webterm.tabs.init()

	$('#tab-bar').on 'click', 'li .ui-icon-close', ->
		webterm.tabs.on_close @

	$('#close-window').click ->
		window.close()
	if webterm.platform == 'chrome'
		$('#max-window').click ->
			if chrome.app.window.current().isMaximized()
				chrome.app.window.current().restore()
			else
				chrome.app.window.current().maximize()
		chrome.app.window.current().onMaximized.addListener ->
			$('#max-window').attr 'title', '恢复'
		chrome.app.window.current().onRestored.addListener ->
			$('#max-window').attr 'title', '最大化'
		$('#min-window').click ->
			chrome.app.window.current().minimize()
	else if webterm.platform == 'node-webkit'
		gui = require 'nw.gui'
		win = gui.Window.get()
		isMaximized = false
		$('#max-window').click ->
			if isMaximized
				win.restore()
			else
				win.maximize()
		win.on 'maximize', ->
			$('#max-window').attr 'title', '恢复'
			isMaximized = true
		win.on 'restore', ->
			$('#max-window').attr 'title', '最大化'
			isMaximized = false
		$('#min-window').click ->
			win.minimize()


	limit_bar_width = ->
		max_width = $('#title-bar').width() - $('#title-panel').width() - $('#new-menu').width()
		$('#tab-bar').css 'max-width', max_width + 'px'

	limit_bar_width()
	$(window).resize limit_bar_width

