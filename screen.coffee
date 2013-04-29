

##################################################
# imports
##################################################

# $
# _
wcwidth = this.wcwidth
encoding = this.encoding
keymap = this.keymap

##################################################
# animations
##################################################

animate_cusor = () ->
	x = $('.cursor')
	color = x.css('color')
	bg = x.css('background-color')
	normal =
		'color': color
		'background-color': bg
	inverted =
		'color': bg
		'background-color': color
	looping = ->
		x.animate inverted, 1000, ->
			x.animate normal, 1000, looping
	looping()

blink = (x, css1, css2, delay) ->
	callback = ->
		if $(x).attr('blink') == '1'
			$(x).css css1
			$(x).attr 'blink', ''
		else
			$(x).css css2
			$(x).attr 'blink', '1'
	timer = setInterval callback, delay
	$(x).attr 'timer', timer

global_animate_cusor = () ->
	global_cursor_flag = true
	callback = ->
		if global_cursor_flag
			$('.cursor').addClass 'highlight'
		else
			$('.cursor').removeClass 'highlight'
		global_cursor_flag = not global_cursor_flag
	global_timer = setInterval callback, 1000

global_blink = () ->
	global_blink_flag = true
	callback = ->
		if global_blink_flag
			$('.blink').addClass 'hidden'
		else
			$('.blink').removeClass 'hidden'
		global_blink_flag = not global_blink_flag
	global_timer = setInterval callback, 1000

$ ->
	global_animate_cusor()
	global_blink()


##################################################
# colors
##################################################

class Char
	constructor: (@char=' ') ->
		@width = wcwidth @char

	set: (c) ->
		if not c?
			throw Error("You got a null char!")
		@char = c
		@width = wcwidth c

##################################################
# Data
##################################################

class Data
	constructor: (@width, @height) ->
		@init()

	new_row: ->
		(@new_cell() for x in [1..@width])
	init: ->
		@data = (@new_row() for y in [1..@height])

	row: (row) ->
		if not (1 <= row <= @height)
			throw Error("Screen overflow!")
		return @data[row-1]
	at: (row, column) ->
		if not column?
			return @row(row)
		if not (1 <= column <= @width)
			throw Error("Screen overflow!")
		return @row(row)[column-1]
	set: (row, column, x) ->
		if not (1 <= column <= @width)
			throw Error("Screen overflow!")
		@row(row)[column-1] = x

	clear: ->
		@init()
	clear_row: (row) ->
		if not (1 <= row <= @height)
			throw Error("Screen overflow!")
		@data[row-1] = @new_row()
	clear_at: (row, column) ->
		@set row, column, @new_cell()
	shift: ->
		@data.shift()
		@data.push @new_row()
	unshift: ->
		@data.unshift @new_row()
		@data.pop()

##################################################
# View
##################################################

class TextView
	constructor: (@data) ->
		Object.defineProperty @, 'width',
			get: -> @data.width
		Object.defineProperty @, 'height',
			get: -> @data.height
	full: ->
		(@row(i) for i in [1..@height]).join('')
	head: ->
		@row 1
	foot: ->
		@row @data.height
	row: (n) ->
		(c.char for c in @data.row(n)).join('')
	row_range: (n, left, right) ->
		row = @data.row(n)
		(row[i-1].char for i in [left .. right ? @width]).join('')
	at: (row, column) ->
		@data.at(row, column).char

class View
	constructor: (@data) ->
		@text = new TextView @data

##################################################
# screenData and Cursor
##################################################

class ScreenData extends Data
	constructor: (width=80, height=24) ->
		@default_new_cell_fn = => @empty_char()
		@new_cell_fn = @default_new_cell_fn
		super width, height

	empty_char: ->
		new Char ' '

	new_cell: ->
		@new_cell_fn()

	erase_all: ->
		@clear()

	erase_to_begin: (cursor) ->
		[row, column] = cursor.point
		for i in [1...curow]
			@clear_row i
		for i in [1..column-1]
			@clear_at row, i

	erase_to_end: (cursor) ->
		[row, column] = cursor.point
		for i in [row+1..@height]
			@clear_row i
		for i in [column..@width]
			@clear_at row, i

	erase_line: (cursor) ->
		@clear_row cursor.row

	erase_line_to_begin: (cursor) ->
		[row, column] = cursor.point
		for i in [1..column-1]
			@clear_at row, i

	erase_line_to_end: (cursor) ->
		[row, column] = cursor.point
		for i in [column..@width]
			@clear_at row, i

class Cursor
	constructor: (@data) ->
		row = 1
		column = 1
		Object.defineProperty @, 'point',
			get: -> [row, column]
		Object.defineProperty @, 'row',
			get: -> row
			set: (x) ->
				if not (1 <= x <= @data.height)
					throw Error("Cursor overflow!")
				row = x
		Object.defineProperty @, 'column',
			get: -> column
			set: (x) ->
				if not (1 <= x <= @data.width+1) # the caret is moved just after the end of the line
					throw Error("Cursor overflow!")
				column = x

	inc: ->
		@column++

	dec: ->
		@column--

	reset: ->
		@row = 1
		@column = 1

	get: ->
		@data.at @row, @column

	put: (c) ->
		if @column > @data.width
			@column -= @data.width
			@row++
		@data.set @row, @column, c

	clear: (c) ->
		@data.clear_at @row, @column

##################################################
# Term
##################################################

class Term
	constructor: (@width=80, @height=24) ->

		@data = new ScreenData @width, @height
		@cursor = new Cursor @data

		@buffer = null
		@clear_style()

	dummy_char: ->
		new Char ''

	new_styled_char: (c) ->
		c = new Char c
		@fill_char_style c

	echo: (c) ->
		if c == '\r'
			@cursor.column = 1
			return
		else if c == '\n'
			if @cursor.row == @height
				@data.shift()
			else
				@cursor.row++
			return
		else if c == '\x08'
			@cursor.dec()
			return
		else if c == '\x07'
			# TODO: bell
			return

		# printable chars
		char = @new_styled_char c
		@cursor.put char
		@cursor.inc()
		if char.width == 2 and @cursor.column < @width
			@cursor.put @fill_char_style @dummy_char()
			@cursor.inc()
		else if char.width == 1 and @cursor.column < @width and @cursor.get().width == 0
#			erasing a wide char
			@cursor.clear()

	control: (c, opts) ->
		if c == 'm'
			@m opts
			return
		else if c == 'A'
			if opts?
				if opts.length == 1
					n = opts[0]
				else
					throw Error("Not Implemented: ^#{opts.join ';'}A")
			else
				n = 1
			row = @cursor.row - n
			if row < 1
				row = 1
			@cursor.row = row
			return
		else if c == 'B'
			if opts?
				if opts.length == 1
					n = opts[0]
				else
					throw Error("Not Implemented: ^#{opts.join ';'}B")
			else
				n = 1
			row = @cursor.row + n
			if row > @height
				row = @height
			@cursor.row = row
			return
		else if c == 'C'
			if opts?
				if opts.length == 1
					n = opts[0]
				else
					throw Error("Not Implemented: ^#{opts.join ';'}C")
			else
				n = 1
			column = @cursor.column + n
			if column > @width
				column = @width
			@cursor.column = column
			return
		else if c == 'D'
			if opts?
				if opts.length == 1
					n = opts[0]
				else
					throw Error("Not Implemented: ^#{opts.join ';'}D")
			else
				n = 1
			column = @cursor.column - n
			if column < 1
				column = 1
			@cursor.column = column
			return
		else if c == 'E'
			if opts?
				if opts.length == 1
					n = opts[0]
				else
					throw Error("Not Implemented: ^#{opts.join ';'}B")
			else
				n = 1
			row = @cursor.row + n
			if row > @height
				row = @height
			@cursor.row = row
			@cursor.column = 1
			return
		else if c == 'F'
			if opts?
				if opts.length == 1
					n = opts[0]
				else
					throw Error("Not Implemented: ^#{opts.join ';'}A")
			else
				n = 1
			row = @cursor.row - n
			if row < 1
				row = 1
			@cursor.row = row
			@cursor.column = 1
			return
		else if c == 'H'
			if opts?
				if opts.length == 2
					[row, column] = opts
					row = if row then row else 1
					column = if column then column else 1
					if row == 1025
						@data.shift()
						row = 1
					@cursor.row = row
					@cursor.column = column
				else
					throw Error("Not Implemented: ^#{opts.join ';'}H")
			else
				@cursor.reset()
			return
		else if c == 'J'
			n = opts?[0] ? 0
			if n == 0
				@data.erase_to_end @cursor
			else if n == 1
				@data.erase_to_begin @cursor
			else if n == 2
				@data.erase_all()
			else
				throw Error("Not Implemented: ^#{opts.join ';'}J")
			return
		else if c == 'K'
			n = opts?[0] ? 0
			if n == 0
				@data.new_cell_fn = => @new_styled_char(' ') # XXX: what about other codes (i.e. J)?
				@data.erase_line_to_end @cursor
			else if n == 1
				@data.new_cell_fn = => @new_styled_char(' ') # XXX: what about other codes (i.e. J)?
				@data.erase_line_to_begin @cursor
			else if n == 2
				@data.new_cell_fn = => @new_styled_char(' ') # XXX: what about other codes (i.e. J)?
				@data.erase_line  @cursor
			else
				throw Error("Not Implemented: ^#{opts.join ';'}J")
			@data.new_cell_fn = @data.default_new_cell_fn
			return
		else if c == 'L'
			n = opts?[0] ? 1
			@data.unshift() for [1..n]
			return
		else if c == 'I'
			console.log ("Not Implemented:  ^#{(opts?.join ';') ? ''}#{c}")
			return
		else
			throw Error("Not Implemented:  ^#{(opts?.join ';') ? ''}#{c}")
			return

	##########
	# styles #
	##########

	clear_style: ->
		@foreground = null
		@background = null
		@bright = null
		@underline = null
		@blink = null

	m: (opts) ->
		if not opts?
			@clear_style()
			return
		for n in opts
			if n == 0
				@clear_style()
			else if n == 1
				@bright = true
			else if 30 <= n <= 37
				@foreground = n
			else if n == 39
				@foreground = null
			else if 40 <= n <= 47
				@background = n
			else if n == 49
				@background = null
			else if n == 4
				@underline = true
			else if n == 5
				@blink = true
			else if n == 7
				background = (@foreground ? 37) + 10
				foreground = (@background ? 40) - 10
				@foreground = foreground
				@background = background
			else
				console.log 'ignore m: ', n

	fill_char_style: (c) ->
		c.foreground = @foreground
		c.background = @background
		c.bright = @bright
		c.underline = @underline
		c.blink = @blink
		c


	##################
	# user interface #
	##################

	fill_ascii_unicode: (s) ->
		if @buffer
			s = @buffer + s
			@buffer = null
		i = 0
		len = s.length
		while i < len
			c = s.charAt(i++)
			if c == '\x1b'
				if i >= len
					@buffer = '\x1b'
					break
				c = s.charAt(i++)
				if c != '['
					throw Error("Not Implemented: #{c}")
				n = i
				while s.charAt(n) == ';' or 48 <= s.charCodeAt(n) <= 57
					n++
				if n >= len
					@buffer = s.substring(i-2)
					break
				if n > i
					opts = (parseInt(m) for m in s.substring(i, n).split ';')
				else
					opts = null
				i = n
				c = s.charAt(i++)
				@control c, opts
			else
				@echo c


##################################################
# Area
##################################################

class AreaManager
	constructor: (@width, @height) ->
		@open = []
		@closed = []

	index: (row, column) ->
		(row - 1) * @width + column - 1

	define_area: (attrs, top, left, bottom, right) ->
		attrs = if _.isString(attrs) then {class: attrs} else attrs
		start = @index top, left
		end = @index bottom, right
		names = @open[start] ? []
		names.push [attrs, end]
		@open[start] = names
		n = @closed[end] ? 0
		@closed[end] = n + 1

	get_open_areas: (row, column) ->
		names = @open[@index row, column]
		if names
			(x[0] for x in _.sortBy(names, (x) -> x[1]).reverse())

	get_closed_area_number: (row, column) ->
		@closed[@index row, column]

##################################################
# Events
##################################################

on_keyboard = (callback) ->
	$('body').on 'keydown', (event) ->
#		console.log 'keydown', "ctrl: #{event.ctrlKey}, alt: #{event.altKey}, shift: #{event.shiftKey}, meta: #{event.metaKay}, char: #{String.fromCharCode event.charCode}, key: #{String.fromCharCode event.keyCode}, charCode: #{event.charCode}, keyCode: #{event.keyCode}"
#		console.log 'keydown', keymap.event_to_virtual_key event
		key = keymap.event_to_virtual_key event
		if key in ['ctrl', 'shift', 'alt', 'meta']
			return
		if key in ['ctrl-c', 'ctrl-v', 'ctrl-insert', 'shift-insert']
			event.preventDefault()
		$('#ime').focus()
		if event.ctrlKey or event.altKey or event.metaKey
			callback key: key
		else if key in ['tab', 'delete', 'backspace', 'up', 'down', 'left', 'right', 'esc', 'home', 'end', 'pageup', 'pagedown', 'insert',
		                'f1', 'f2', 'f3', 'f4', 'f5', 'f6', 'f7', 'f8', 'f9', 'f10', 'f11', 'f12']
			callback key: key
		else if key in ['shift-insert']
			callback key: key

	$('#ime').on 'keypress', (event) ->
#		console.log 'keypress', "ctrl: #{event.ctrlKey}, alt: #{event.altKey}, shift: #{event.shiftKey}, meta: #{event.metaKay}, char: #{String.fromCharCode event.charCode}, key: #{String.fromCharCode event.keyCode}, charCode: #{event.charCode}, keyCode: #{event.keyCode}"
#		console.log 'keypress', keymap.event_to_virtual_key event
		if not event.ctrlKey
			# XXX: why ctrl-b, ctrl-f, ctrl-n, and may else, still trigger keypress events?
			key = keymap.event_to_virtual_key event
			callback key: key
		event.preventDefault()

	$('#ime').on 'textInput', (event) ->
#		console.log 'textInput', event.originalEvent.data, event
		callback
			text: event.originalEvent.data
			event: event

escape_virtual_key_to_text = (key) ->
	if key?
		text = keymap.virtual_key_to_ascii key
		if text?
			return text
		else
			console.log 'ignore key binding:', key

normalize_key = (k) ->
	if k.length == 1
		return k
	m = k.match /^((?:(?:ctrl|shift|alt|meta)[+-])*)(.+)$/
	a = []
	if m[1].indexOf('ctrl') != -1
		a.push 'ctrl'
	if m[1].indexOf('shift') != -1
		a.push 'shift'
	if m[1].indexOf('alt') != -1
		a.push 'alt'
	if m[1].indexOf('meta') != -1
		a.push 'meta'
	a.push m[2]
	return a.join '-'

is_key = (x, y) ->
	if x == y
		return true
	return normalize_key(x) == normalize_key(y)

class Events
	constructor: (@screen) ->
		# keyboard buffer
		@buffer = []

		# keyboard events
		@key_mappings_persisted = []
		@key_mappings = []
		on_keyboard ({key, text}) =>
			if key?
				for [k, h] in @key_mappings
					if is_key(k, key)
						h(key)
						return
				for [k, h] in @key_mappings_persisted
					if is_key(k, key)
						h(key)
						return
				@put_key key
			if text?
				@put_text text
			@send()

		# mouse click events
		@clickables = []
		mouse_click_at = null
		mouse_click_when = new Date()
		$(@screen.selector).mousedown (e) =>
			if e.button == 0 and e.which == 1
				if @screen.selection
					@screen.selection = null
					@screen.render()
				@screen.selection = new Selection(@screen)
				@screen.selection.start = [e.pageX, e.pageY]
				@screen.selection.column_mode = e.altKey
				e.preventDefault()
			if e.button == 0
				mouse_click_at = [e.offsetX, e.offsetY]
				now = new Date()
				if now - mouse_click_when < 500 and $(e.target).closest(@clickables).length > 0
					# double clicking on a clickable, let's prevent annoying selections
					e.preventDefault()
				mouse_click_when = now
		$(@screen.selector).mouseup (e) =>
			if e.button == 0 and e.which == 1 and @screen.selection
				if not @screen.selection.ready
					@screen.selection = null
				else if @screen.selection.done
					@screen.selection = null
					@screen.render()
					return
				else
					@screen.selection.done = true
					return
			if e.button == 0
				if mouse_click_at?
					if mouse_click_at[0] == e.offsetX and mouse_click_at[1] == e.offsetY
						target = $(e.target).closest(@clickables)
						if target.length > 0
							target.data('handler')?(e.target) # XXX: when there are multiple targets?
							window.getSelection().removeAllRanges() # clear annoying double clicking selections
					mouse_click_at = null
		$(@screen.selector).mousemove (e) =>
			if e.button == 0 and e.which == 1 and @screen.selection and not @screen.selection.done
				if not @screen.selection.range?
					start_x = @screen.selection.start[0]
					start_y = @screen.selection.start[1]
					if start_x == e.pageX and start_y == e.pageY
						return
					@screen.selection.ready = true
					@screen.render()
					pos = @screen.selection.position_at_point start_x, start_y
					if pos
						@screen.selection.set_range [pos, pos]
						@screen.render_selection()
					else
						@screen.selection = null
						@screen.render()
						return
				pos = @screen.selection.position_at_point e.pageX, e.pageY
				if pos?
					if @screen.selection.update_range pos
						@screen.render_selection()
						e.preventDefault()
			else if e.button == 0 and e.which == 1 and @screen.selection and @screen.selection.done
				# when user holds on mouse at the edge of screen
				@screen.selection = null
				@screen.render()
				@screen.selection = new Selection(@screen)
				@screen.selection.start = [e.pageX, e.pageY]
				@screen.selection.column_mode = e.altKey
			else if e.button == 0 and e.which == 1 and not @screen.selection
				# when user holds on mouse at the edge of screen
				@screen.selection = new Selection(@screen)
				@screen.selection.start = [e.pageX, e.pageY]
				@screen.selection.column_mode = e.altKey

		# mouse wheels
		$(@screen.selector).on 'mousewheel', (e) =>
			delta = e.originalEvent.wheelDelta
			if delta > 0
				@send_key "up"
			else if delta < 0
				@send_key "down"

		# mouse gestures!
		@gestures = {}
		$(@screen.selector).gesture (e) =>
			gesture = e.direction
			if gesture?
				handler = @gestures[gesture]
				if handler?
					handler()
				else
					@send_key gesture


	clear: ->
		@key_mappings = []
		@clickables = []
		@gestures = {}

	on_key: (key, handler) ->
		@key_mappings.push [key, handler]

	on_key_persisted: (key, handler) ->
		@key_mappings_persisted.push [key, handler]

	put_key: (keys...) ->
#		console.log 'send key', keys
		for key in keys
			text = escape_virtual_key_to_text key
			if text?.length > 0
				@buffer.push text

	put_text: (text) ->
#		console.log 'send text', text
		# XXX: TODO: escape?
		@buffer.push text

	send: ->
		if @buffer.length > 0
			text = @buffer.join ''
			@buffer = []
			if text.length > 0
				data = encoding.string_to_gbk(text)
				@screen.on_data? data

	send_key: (keys...) ->
		@put_key keys...
		@send()

	send_text: (text) ->
		@put_text text
		@send()

	on_click: (selector, handler) ->
		elements = $(@screen.selector).find(selector)
		$.merge @clickables, elements
		elements.data 'handler', (e) ->
			handler e

	on_click_div: (selector, handler) ->
		@on_click selector, (e) ->
			handler $(e).closest('div')[0]


	send_key_on_click: (selector, keys...) ->
		@on_click selector, =>
			@send_key keys...

	on_mouse_gesture: (gesture, callback) ->
		@gestures[gesture] = callback

##################################################
# Commands
##################################################

class Commands
	constructor: (@screen) ->
		@persisted = {}
		@commands = {}
	register_persisted: (name, command) ->
		@persisted[name] = command
	register: (name, command) ->
		@commands[name] = command
	lookup: (name) ->
		@commands[name] or @persisted[name]
	execute: (name) ->
		command = @lookup(name)
		if not command
			throw Error("Command not found: #{name}")
		command()
	clear: ->
		@commands = {}


##################################################
# Context Menus
##################################################

class ContextMenus
	constructor: (@screen) ->
		@persisted = []
		@menus = []

	register_persisted: (menu) ->
		@persisted.push menu

	register: (menu) ->
		@menus.push menu

	clear: ->
		@menus = []

	compute_session: ->
		session = []
		for menu in @persisted
			session.push menu.id
		for menu in @menus
			session.push menu.id
		session

	update_menus: ->
		callbacks = {}
		for menu in @persisted
			callbacks[menu.id] = menu.onclick
		for menu in @menus
			callbacks[menu.id] = menu.onclick
		chrome.contextMenus.removeAll =>
			for {id, title, contexts} in @persisted
				chrome.contextMenus.create
					title: title
					id: id
					contexts: contexts ? ['all']
			for {id, title, contexts} in @menus
				chrome.contextMenus.create
					title: title
					id: id
					contexts: contexts ? ['all']
		if @listener
			chrome.contextMenus.onClicked.removeListener @listener
		@listener = (info) ->
			callback = callbacks[info.menuItemId]
			if callback?
				callback()
			else
				console.error "No handler for menu #{info.menuItemId}"
		chrome.contextMenus.onClicked.addListener @listener
		@session = @compute_session()

	refresh: ->
		if @session and _.isEqual(@session, @compute_session())
			return
		@update_menus()

##################################################
# Expect
##################################################

class Expect
	constructor: (@screen) ->
		@callbacks = {}
		@counter = 0
	check: (check, callback) ->
		@callbacks[@counter++] = [check, callback]
	update: ->
		to_remove = []
		for id, [check, callback] of @callbacks
			if check @screen
				callback @screen
		for id in to_remove
			@callbacks[id] = undefined


##################################################
# Selection
##################################################

class Selection
	constructor: (@screen) ->

	set_range: (range) ->
		@range = range
		@update_range_cache()

	update_range: ([r, c]) ->
		if @range[1][0] != r or @range[1][1] != c
			@range[1] = [r, c]
			@update_range_cache()
			return true

	get_rect: ->
		top   : _.min([@range[0][0], @range[1][0]])
		bottom: _.max([@range[0][0], @range[1][0]])
		left  : _.min([@range[0][1], @range[1][1]])
		right : _.max([@range[0][1], @range[1][1]])

	get_band: ->
		start = (@range[0][0]-1) * @screen.width + (@range[0][1]-1)
		end = (@range[1][0]-1) * @screen.width + (@range[1][1]-1)
		[_.min([start, end]), _.max([start, end])]

	update_range_cache: ->
		if @column_mode
			@rect = @get_rect()
		else
			@band = @get_band()

	contains: (row, column) ->
		if @column_mode
			@rect.top <= row <= @rect.bottom and @rect.left <= column <= @rect.right
		else
			if not @band
				console.log 'error!'
			@band[0] <= (row-1) * @screen.width + (column-1) <= @band[1]

	get_selected_text: ->
		if @column_mode
			if @rect
				{top, bottom, left, right} = @rect
				((@screen.data.data[i-1][j-1].char for j in [left..right]).join('').trimRight() for i in [top..bottom]).join '\n'
		else
			if @band
				[start, end] = @band
				buffer = []
				for i in [start..end]
					row = (Math.floor i / @screen.width) + 1
					column = (i % @screen.width) + 1
					buffer.push @screen.data.at(row, column).char
					if column == @screen.width
						buffer.push '\n'
				text = buffer.join ''
				text.replace /\x20+$/gm, ''

	get_selected_ascii: ->
		if @column_mode
			if @rect
				{top, bottom, left, right} = @rect
				builder = new ASCIIBuilder
				for i in [top..bottom]
					for j in [left..right]
						builder.append @screen.data.at i, j
					builder.append_line()
				builder.complete()
		else
			if @band
				[start, end] = @band
				builder = new ASCIIBuilder
				for i in [start..end]
					row = (Math.floor i / @screen.width) + 1
					column = (i % @screen.width) + 1
					builder.append @screen.data.at row, column
					if column == @screen.width
						builder.append_line()
				builder.complete()

	select_all: ->
		@set_range [[1, 1], [@screen.height, @screen.width]]
		@

	# helpers
	position_of_span: (span) ->
		row = span.getAttribute('row')
		column = span.getAttribute('column')
		if top? and column?
			[parseInt(row), parseInt(column)]
	position_at_point: (x, y) ->
		@position_of_span document.elementFromPoint x, y


##################################################
# ASCII builder
##################################################

class ASCIIBuilder
	constructor: ->
		@buffer = []
		@foreground = null
		@background = null
		@bright = null
		@underline = null
		@blink = null
	append: (c) ->
		if @equal_styles(@, c)
			@buffer.push c.char
		else if not @has_styles(c)
			@buffer.push '\x1b[m'
			@buffer.push c.char
			@copy_styles c, @
		else
			@buffer.push '\x1b[m'
			styles = []
			if c.foreground
				styles.push c.foreground
			if c.background
				styles.push c.background
			if c.bright
				styles.push 1
			if c.underline
				styles.push 4
			if c.blink
				styles.push 5
			@buffer.push "\x1b[#{styles.join ';'}m"
			@buffer.push c.char
			@copy_styles c, @
	append_line: ->
		@buffer.push '\n'
	complete: ->
		if @has_styles @
			@buffer.push '\x1b[m'
		@buffer.join ''

	## helpers
	equal: (x, y) ->
		if x? and y?
			return x == y
		else if x? or y?
			return false
		else
			return true
	equal_styles: (x, y) ->
		@equal(x.foreground, y.foreground) and
		@equal(x.background, y.background) and
		@equal(x.bright, y.bright) and
		@equal(x.underline, y.underline) and
		@equal(x.blink, y.blink)
	has_styles: (x) ->
		x.foreground? or x.background? or x.bright? or x.underline? or x.blink?
	copy_styles: (from, to) ->
		to.foreground = from.foreground
		to.background= from.background
		to.bright = from.bright
		to.underline = from.underline
		to.blink = from.blink

##################################################
# HTML builder
##################################################

##################################################
# Screen
##################################################

class Screen
	constructor: (@width=80, @height=24) ->
		@selector = '#screen'

		@term = new Term(@width, @height)
		@data = @term.data
		@cursor = @term.cursor

		@events = new Events @

		@commands = new Commands @

		@selection = null

		copy = =>
			selected = @selection?.get_selected_text()
			if selected
				@selection = null
				@render()
			else
				selected = new Selection(@).select_all().get_selected_text()
			$('#clipboard').val(selected).select()
			document.execCommand('copy')
			$('#clipboard').val('')

		copy_ascii = =>
			selected = @selection?.get_selected_ascii()
			if selected
				@selection = null
				@render()
			else
				selected = new Selection(@).select_all().get_selected_ascii()
			$('#clipboard').val(selected).select()
			document.execCommand('copy')
			$('#clipboard').val('')

		copy_if = =>
			selected = @selection?.get_selected_text()
			if selected
				$('#clipboard').val(selected).select()
				document.execCommand('copy')
				$('#clipboard').val('')
				@selection = null
				@render()
			else
				@events.send_key 'ctrl-c'


		paste = =>
			$('#clipboard').val('').select()
			document.execCommand('paste')
			data = $('#clipboard').val()
			$('#clipboard').val('')
			data = data.replace /\x1b/g, '\x1b\x1b'
			@events.send_text data

		@commands.register_persisted 'copy', copy
		@commands.register_persisted 'copy-ascii', copy_ascii
		@commands.register_persisted 'copy-if', copy_if
		@commands.register_persisted 'paste', paste

		@events.on_key_persisted 'ctrl-insert', =>
			@commands.execute('copy')
		@events.on_key_persisted 'shift-insert', =>
			@commands.execute('paste')
		@events.on_key_persisted 'ctrl-shift-c', =>
			@commands.execute('copy-ascii')
		@events.on_key_persisted 'ctrl-c', =>
			@commands.execute('copy-if')

		@context_menus = new ContextMenus @
		@context_menus.register_persisted
			title: '文本复制'
			id: 'copy'
			contexts: ['all']
			onclick: copy
		@context_menus.register_persisted
			title: '彩色复制'
			id: 'copy-ascii'
			contexts: ['all']
			onclick: copy_ascii
		@context_menus.register_persisted
			title: '粘贴'
			id: 'paste'
			contexts: ['all']
			onclick: paste
		@context_menus.refresh()

		@expect = new Expect @

		@on_screen_updated = null
		@on_screen_rendered = null
		@on_data = null

	update_area: ->
		@area = new AreaManager(@width, @height)

	update_view: ->
		@view = new View @data

	##################
	# user interface #
	##################

	screen_updated: ->
		@update_area()
		@update_view()
		@events.clear()
		@commands.clear()
		@context_menus.clear()
		@expect.update()
		@on_screen_updated?()

	screen_rendered: ->
		@context_menus.refresh()
		@on_screen_rendered?()

	render: ->
		$('#screen').html @to_html()
		$('#ime').offset $('.cursor').offset()
		@screen_rendered()

	fill_ascii_raw: (a) ->
		if a.constructor.name == 'String'
			a = encoding.string_to_cp1252 a
		if @ascii_buffer?
			concat = (a, b) ->
				c = new Uint8Array(a.length + b.length)
				offset = 0
				for i in [0...a.length]
					c[offset++] = a[i]
				for i in [0...b.length]
					c[offset++] = b[i]
				c
			a = concat(@ascii_buffer, a)
			@ascii_buffer = null
		[s, left] = encoding.gbk_to_string_partial a
		if left.length > 0
			@ascii_buffer = left
		@fill_ascii_unicode(s)

	fill_ascii_unicode: (s) ->
		@term.fill_ascii_unicode(s)
		@screen_updated()

	to_text: ->
		((c.char for c in line).join('') for line in @data.data).join '\n'

	to_html: ->
		html = []
		tag = null
		for line, i in @data.data
			for c, j in line
				row = i + 1
				column = j + 1
				closed = @area.get_closed_area_number row, column
				open = @area.get_open_areas row, column
				styles = []
				if open?
					if tag?
						html.push '</span>'
						tag = null
					for attrs in open
						html.push """<div#{(" #{k}='#{v}'" for k, v of attrs).join ''}>"""
				if row == @cursor.row and column == @cursor.column
					styles.push 'cursor highlight'
				if c.foreground
					styles.push 'c' + c.foreground
				if c.background
					styles.push 'c' + c.background
				if c.bright
					styles.push 'c1'
				if c.underline
					styles.push 'underline'
				if c.blink
					styles.push 'blink'
				if styles.length or @selection?.ready?
					if @selection?.ready?
						new_tag = "<span class='#{styles.join ' '}' row='#{row}' column='#{column}'>"
					else
						new_tag = "<span class='#{styles.join ' '}'>"
					if tag?
						if tag != new_tag
							html.push '</span>'
							html.push new_tag
					else
						html.push new_tag
					html.push _.escape c.char
					tag = new_tag
				else
					if tag?
						html.push '</span>'
						tag = null
					html.push _.escape c.char
				if closed > 0
					if tag?
						html.push '</span>'
						tag = null
					html.push '</div>' for [1..closed]
			html.push '\n'
		html.pop() # popup last '\n
		if tag?
			html.push '</span>'
		return html.join ''

	render_selection: ->
		if @selection?.range?
			selection = @selection
			$(@selector).find('span.selected').removeClass('selected')
			cells = $(@selector).find('span[row][column]').filter ->
				[row, column] = selection.position_of_span @
				selection.contains row, column
			cells.addClass('selected')


jQuery.expr[':'].area =

##################################################
# exports
##################################################

exports = this
exports.Screen = Screen
