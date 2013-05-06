

add_tab = (id, label, content) ->
	li = """<li><a href="##{id}">#{label}</a><span class="ui-icon ui-icon-close" role="presentation">Remove Tab</span></li>"""
	tabs = $('#tabs')
	tabs.find(".ui-tabs-nav").append(li)
	tabs.append "<div id='#{id}'>#{content}</div>"
	tabs.tabs "refresh"
	$('#'+id)[0]

class Tabs
	constructor: ->
		@counter = 0
		@registry = {}

	on: (event, callback) ->
		if event == 'new'
			$('#new-tab').click callback
		else if event == 'active'
			$('#tabs').on 'tabsactivate', (event, ui) ->
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
			div: div
			data: data
			on_open: on_open
			on_close: on_close
			on_closing: on_closing
			on_closed: on_closed
		@registry[id] = info
		on_open?(info)
		$('#tabs').tabs 'option', 'active', $("#tabs ul#tab-bar li").length - 1

	on_close: (element) ->
		li = $(element).closest("li")
		id = li.attr('aria-controls')
		todo = =>
			@registry[id]?.on_closing?()
			li.remove()
			$("#"+id).remove()
			$('#tabs').tabs "refresh"
			@registry[id]?.on_closed?()
			@registry[id] = undefined
		on_close = @registry[id]?.on_close
		if on_close
			on_close todo
		else
			todo()

	nth_id: (n) ->
		###
		# Note: n start from 0
		###
		$("#tabs ul#tab-bar li:nth-child(#{n})").attr('aria-controls')

	nth_div_selector: (n) ->
		"##{@nth_id n}"


$ ->
	tabs = $('#tabs').tabs()
	tabs.find(".ui-tabs-nav").sortable
		axis: "x"
		stop: ->
			tabs.tabs "refresh"

	$('#tabs #tab-bar').on 'click', 'li .ui-icon-close', ->
		webterm.tabs.on_close @

	$('#close-window').click ->
		window.close()


webterm.tabs = new Tabs

