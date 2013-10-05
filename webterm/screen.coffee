

##################################################
# imports
##################################################

$ = this.$
_ = this._
wcwidth = this.wcwidth
encoding = this.encoding
keymap = this.keymap
webterm = this.webterm

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
					throw Error("Cursor overflow! row: #{x}")
				row = x
		Object.defineProperty @, 'column',
			get: -> column
			set: (x) ->
				if not (1 <= x <= @data.width+1) # the caret is moved just after the end of the line
					throw Error("Cursor overflow! column: #{x}")
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
		if char.width == 2 and @cursor.column <= @width
			@cursor.put @fill_char_style @dummy_char()
			@cursor.inc()
		else if char.width == 1 and @cursor.column <= @width and @cursor.get().width == 0
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
					invalid = '\x1b' + c
					while i < len
						c = s.charAt(i++)
						invalid += c
						if c.match /^[a-zA-Z]$/
							console.error "Not Implemented: #{invalid}"
							break
#					throw Error("Not Implemented: #{c}")
				else
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
# Painter
##################################################

class Painter
	constructor: (@screen) ->
	reset_state: ->
		@screen.reset_state()
		@
	clear: ->
		@screen.data.erase_all()
		@
	move_to: (row, column) ->
		@screen.cursor.row = row
		@screen.cursor.column = column
		@
	scollup: (n=1) ->
		for [1..n]
			@screen.data.shift()
		@
	fill_text: (text) ->
		for i in [0...text.length]
			@screen.term.echo text[i]
		@
	foreground: (color) ->
		if color == 'red'
			@screen.term.foreground = 31
			@screen.term.bright = true
		else
			throw Error("Not Implemented: #{color}")
		@
	key: (k, h) ->
		@screen.events.on_key k, h
		@
	area: (attrs, top, left, bottom, right) ->
		@screen.area.define_area attrs, top, left, bottom, right
		@
	flush: ->
		@screen.render()
		@
	render: (render) ->
		render.render @screen
		@

##################################################
# Area
##################################################

class AreaManager
	constructor: (@width, @height) ->
		@open = []
		@closed = []
		@data = {}
		@data_id = 0

	index: (row, column) ->
		(row - 1) * @width + column - 1

	to_data: (data) ->
		if _.isFunction data
			k = "webterm-screen-data-#{@data_id++}"
			@data[k] = data
			return k
		else
			return data

	normalize_attrs: (attrs) ->
		attrs = if _.isString(attrs) then {class: attrs} else attrs
		new_attrs = {}
		for k, v of attrs
			new_attrs[k] = @to_data v
		new_attrs

	define_area: (attrs, top, left, bottom, right) ->
		attrs = @normalize_attrs attrs
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

	data: (id) ->
		@data[id]

##################################################
# Events
##################################################

escape_virtual_key_to_text = (key) ->
	if key?
		text = keymap.virtual_key_to_ascii key
		if text?
			return text
		else
			console.log 'ignore key binding:', key

class Events
	constructor: (@screen) ->
		# keyboard buffer
		@buffer = []

		# keyboard events
		@key_mappings_persisted = new webterm.keys.KeyListener (e) => @on_keyboard_default(e)
		@key_mappings = new webterm.keys.KeyListener @key_mappings_persisted

		# mouse click events
		@clickables = []
		mouse_click_at = null
		$(@screen.selector).mousedown (e) =>
			if e.which == 1
				e.preventDefault()
				# clear old selection
				if @screen.selection
					@screen.selection = null
					@screen.render()
				# start a new selection
				@screen.selection = new Selection(@screen)
				@screen.selection.start = [e.pageX, e.pageY]
				@screen.selection.column_mode = e.altKey
				mouse_click_at = [e.offsetX, e.offsetY]
		$(@screen.selector).mouseup (e) =>
			if e.which == 1
				if @screen.selection
					if not @screen.selection.ready
						@screen.selection = null
					else if @screen.selection.done
						@screen.selection = null
						@screen.render()
						return
					else
						@screen.selection.done = true
						return
				if mouse_click_at?
					# now it's real mouse click event
					@do_click e
					mouse_click_at = null
		$(@screen.selector).mousemove (e) =>
			if e.which == 1 and @screen.selection and not @screen.selection.done
				if not @screen.selection.range?
					start_x = @screen.selection.start[0]
					start_y = @screen.selection.start[1]
					if start_x == e.pageX and start_y == e.pageY
						return
					if Math.abs(start_x - e.pageX) < 4 and Math.abs(start_y - e.pageY) < 4
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
			else if e.which == 1 and @screen.selection and @screen.selection.done
				# when user holds on mouse at the edge of screen
				@screen.selection = null
				@screen.render()
				@screen.selection = new Selection(@screen)
				@screen.selection.start = [e.pageX, e.pageY]
				@screen.selection.column_mode = e.altKey
			else if e.which == 1 and not @screen.selection
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
		@gestures_persisted = {}
		@gestures = {}
		$(@screen.selector).gesture (e) =>
			set = _.keys(@gestures_persisted).concat _.keys(@gestures)
			if _.isEmpty set
				return
			gesture = e.recognize_gesture set
			if gesture?
				handler = @gestures[gesture] ? @gestures_persisted[gesture]
				handler()
			else
				console.log 'gesture ignored'
		@on_mouse_gesture_persisted 'up', =>
			@send_key 'up'
		@on_mouse_gesture_persisted 'down', =>
			@send_key 'down'
		@on_mouse_gesture_persisted 'left', =>
			@send_key 'left'
		@on_mouse_gesture_persisted 'right', =>
			@send_key 'right'

		# drag and drop
		@dnd_handler = null
		webterm.dnd.drag_data_to screen.selector, (data) =>
			@dnd_handler? data # TODO: send event to upper listener when @dnd_handler is null



	clear: ->
		@key_mappings = new webterm.keys.KeyListener @key_mappings_persisted
		@clickables = []
		@gestures = {}
		@dnd_handler = null

	on_keyboard: (e) ->
		@key_mappings.dispatch e

	on_keyboard_default: ({key, text}) ->
		if key?
			@put_key key
		if text?
			@put_text text
		@send()

	on_key: (key, handler) ->
		@key_mappings.on_key key, handler

	on_key_persisted: (key, handler) ->
		@key_mappings_persisted.on_key key, handler

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

	send_key_sequence_string: (k) ->
		for x in k.split(' ')
			if /^\[.+\]$/.test x
				@put_text x.substring 1, x.length - 1
			else
				@put_key x
			@send()

	is_clicking_anything: (e) ->
		$(e.target).closest((x[0] for x in @clickables).join(', ')).length > 0

	do_click: (e) ->
		target = $(e.target).closest((x[0] for x in @clickables).join(', '))[0]
		if target?
			target = $(target)
			for [selector, handler] in @clickables
				if target.is selector
					handler target[0]
#					window.getSelection().removeAllRanges() # clear annoying double clicking selections
					return

	on_click: (selector, handler) ->
		@clickables.push [selector, handler]

	on_click_div: (selector, handler) ->
		@on_click selector, (e) ->
			handler $(e).closest('div')[0]


	send_key_on_click: (selector, keys...) ->
		@on_click selector, =>
			@send_key keys...

	on_mouse_gesture: (gesture, callback) ->
		@gestures[gesture] = callback

	on_mouse_gesture_persisted: (gesture, callback) ->
		@gestures_persisted[gesture] = callback


	on_dnd: (callback) ->
		@dnd_handler = callback

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
		$.contextMenu
			selector: @screen.selector
			reposition: false
			build: ($trigger, e) =>
				return @create_jquery_context_menu event: e, target: e.target, screen: @screen

	register_persisted: (menu) ->
		@persisted.push menu

	register: (menu) ->
		@menus.push menu

	clear: ->
		@menus = []

	lookup_menu: (id) ->
		for menu in @persisted
			if menu.id == id
				return menu
		for menu in @menus
			if menu.id == id
				return menu
		return

	invoke_menu: (id, context) ->
		menu = @lookup_menu(id)
		if not menu
			console.error "context menu #{id} not found"
			return
		if menu.onclick?
			menu.onclick context

	#######################
	# jquery context menu #
	#######################

	match_context: (spec, context) ->
		if not spec
			return true
		if spec == 'all'
			return true
		if spec == 'selection'
			return @screen.selection?.is_valid()
		if spec == 'link'
			return $(context.target).closest('a').length > 0
		if spec == 'image'
			return $(context.target).closest('img').length > 0
		if spec == 'video'
			throw new Error("Not Implemented")
		if spec == 'audio'
			throw new Error("Not Implemented")
		if _.isArray(spec)
			for c in spec
				if @match_context c, context
					return true
			return false
		if _.isFunction(spec)
			return spec(context)
		console.error "Unknow menu context spec: #{spec}"

	create_jquery_menu_items: (runtime_context, menus) ->
		items = []
		for {id, title, icon, context} in menus
			if @match_context(context, runtime_context)
				items.push id: id, name: title, icon: icon
		items

	create_jquery_context_menu: (context) ->
		items = {}
		group1 = @create_jquery_menu_items context, @menus
		group2 = @create_jquery_menu_items context, @persisted
		for menu in group1
			items[menu.id] = menu
		if group1.length > 0 and group2.length > 0
			items['seperator'] = "---------"
		for menu in group2
			items[menu.id] = menu
		callback = (id, options) =>
			@invoke_menu id, context
		return callback: callback, items: items

	############################
	# chrome menu: depreciated #
	############################

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

	is_valid: ->
		true

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
		else if not @has_styles(@)
			@buffer.push @generate_styles c
			@buffer.push c.char
			@copy_styles c, @
		else
			reset = @generate_reset_styles(c)
			diff = @generate_diff_styles(c)
			@buffer.push if reset.length < diff.length then reset else diff
			@buffer.push c.char
			@copy_styles c, @
	append_line: ->
		@buffer.push '\n'
	complete: ->
		if @has_styles @
			@buffer.push '\x1b[m'
		@buffer.join ''

	generate_styles: (c) ->
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
		"\x1b[#{styles.join ';'}m"

	generate_reset_styles: (c) ->
		"\x1b[m" + @generate_styles(c)

	generate_diff_styles: (c) ->
		styles = []
		reset = false
		if not (@equal(@bright, c.bright) and @equal(@underline, c.underline) and @equal(@blink, c.blink))
			if @bright or @underline or @blink
				styles.push 0
				reset = true
			if c.bright
				styles.push 1
			if c.underline
				styles.push 4
			if c.blink
				styles.push 5
		if not @equal(@foreground, c.foreground)
			styles.push if not c.foreground then 39 else c.foreground
		else if reset and c.foreground
			styles.push c.foreground
		if not @equal(@background, c.background)
			styles.push if not c.background then 49 else c.background
		else if reset and c.background
			styles.push c.background
		"\x1b[#{styles.join ';'}m"

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
# sider
##################################################

class ScreenSider
	constructor: (@div) ->
		@multimedia = @div.find('.screen-sider-multimedia')
		@hotkeys = @div.find('.screen-sider-hotkeys')
		@gestures = @div.find('.screen-sider-gestures')
		@commands = @div.find('.screen-sider-commands')
		@jobs = @div.find('.screen-sider-jobs')
		@locations = @div.find('.screen-sider-locations')

		@div_images = @multimedia.find('> .screen-sider-images')
		@div_sounds = @multimedia.find('> .screen-sider-sounds')
		@div_videos = @multimedia.find('> .screen-sider-videos')

		screen_div = @div.parents('.screen-layout').find('.screen')
		@multimedia.tooltip
			items: ".image-loading-complete img"
			content: ->
				max_width = $(screen_div).width()
				if max_width > 1024
					max_width = 1024
				max_height = $(screen_div).height()
				return "<img src='#{@getAttribute 'src'}' style='max-width: #{max_width}px; max-height: #{max_height}px'>"
			position:
				my: "right center"
				at: "left center"
				collision: "fit"
				within: screen_div
			tooltipClass: 'image-preview-tooltip'

		@urls = []
		webterm.accordion @div, 'on', 'show', (accordion, section) =>
			if @multimedia.parent().is section
				@render_multimedia @urls

	update_multimedia: (urls) ->
		@urls = urls
		if @multimedia.is ":visible"
			@render_multimedia(urls)

	render_multimedia: (urls) ->
		images = (url for url in urls when url.match /\.(jpg|jpeg|png|gif|bmp)$/i)
		sounds = (url for url in urls when url.match /\.(mp3|wma|wav)$/i)
		@show_images images
		@show_sounds sounds

	show_images: (urls) ->
		if _.isEqual(@images, urls)
			return
		@images = urls
		@div_images.empty()
		for url in urls
			@show_image url
		return

	show_image: (url) ->
		div = $("<div class='image-loader image-loading'><img/><span class='image-status'>Loading...</span></div>").appendTo @div_images
		img = div.find('img')
		span = div.find('span')
		xhr = new XMLHttpRequest()
		xhr.open('GET', url, true)
		xhr.responseType = 'blob'
		get_filename = ->
			name = xhr.getResponseHeader('Content-Disposition')?.match(/filename=(\S+)/)?[1]
			if name?
				return decodeURIComponent name
		xhr.onload = ->
			if @response.size > 0
				img.attr 'src', window.webkitURL.createObjectURL @response
				filename = get_filename()
				if filename?
					img.attr 'filename', filename
					img.attr 'title', filename
				div.removeClass 'image-loading'
				div.addClass 'image-loading-complete'
			else
				span.attr 'title', url
				span.text "error"
				div.addClass 'image-loading-error'
		xhr.addEventListener 'progress', (event) ->
			if event.loaded? and event.total?
				percent = Math.floor event.loaded / event.total * 100
				span.text "#{percent}%"
		, false
		xhr.send()

	show_sounds: (urls) ->
		if _.isEqual(@sounds, urls)
			return
		@sounds = urls
#		@div_sounds.empty()
		playing = []
		for div in @div_sounds.children('div.sound-loader')
			audio = $(div).children('audio')[0]
			if audio.paused
				$(div).remove()
			else
				playing.push audio.currentSrc
		for url in urls
			if url not in playing
				div = $("""<div class='sound-loader'><audio controls="controls" title="#{url}"><source src="#{url}"></audio></div>""").appendTo @div_sounds

##################################################
# Screen
##################################################

class Screen
	constructor: (@selector, @width=80, @height=24) ->
		if not @selector
			throw Error("Screen must has a selector")

		@div = $(@selector)
		@sider_div = @div.parents('.screen-layout').find('.screen-sider')
		@sider = new ScreenSider @sider_div

		@term = new Term(@width, @height)
		@data = @term.data
		@cursor = @term.cursor
		@painter = new Painter @

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
			webterm.clipboard.put selected

		copy_ascii = =>
			selected = @selection?.get_selected_ascii()
			if selected
				@selection = null
				@render()
			else
				selected = new Selection(@).select_all().get_selected_ascii()
			webterm.clipboard.put selected

		copy_if = =>
			selected = @selection?.get_selected_text()
			if selected
				webterm.clipboard.put selected
				@selection = null
				@render()
			else
				@events.send_key 'ctrl-c'

		paste = =>
			data = webterm.clipboard.get()
			data = data.replace /\x1b/g, '\x1b\x1b'
			@events.send_text data

		paste_confirm = ->
			webterm.dialogs.confirm '粘贴确认', '当前状态可能不是编辑状态，确认要发送剪切板上的内容吗？', (ok) ->
				if ok
					paste()

		paste_rich_confirm = ->
			data = webterm.clipboard.get()
			if data.match /[\r\n\x1b]/
				webterm.dialogs.confirm '粘贴确认', '剪切板上的内容可能包含控制字符或者换行，确认发送？', (ok) ->
					if ok
						paste()
			else
				paste()

		@commands.register_persisted 'copy', copy
		@commands.register_persisted 'copy-ascii', copy_ascii
		@commands.register_persisted 'copy-if', copy_if
		@commands.register_persisted 'paste', paste
		@commands.register_persisted 'paste-confirm', paste_confirm
		@commands.register_persisted 'paste-rich-confirm', paste_rich_confirm
		@commands.register_persisted 'paste-default', paste_confirm

		@events.on_key_persisted 'ctrl-insert', =>
			@commands.execute('copy')
		@events.on_key_persisted 'shift-insert', =>
			@commands.execute('paste-default')
		@events.on_key_persisted 'ctrl-shift-c', =>
			@commands.execute('copy-ascii')
		@events.on_key_persisted 'ctrl-c', =>
			@commands.execute('copy-if')

		@context_menus = new ContextMenus @
		@context_menus.register_persisted
			title: '文本复制'
			id: 'copy'
			icon: 'copy'
			context: 'all'
			onclick: copy
		@context_menus.register_persisted
			title: '彩色复制'
			id: 'copy-ascii'
			icon: 'copy'
			context: 'all'
			onclick: copy_ascii
		@context_menus.register_persisted
			title: '粘贴'
			id: 'paste'
			icon: 'paste'
			contexts: 'all'
			onclick: paste # XXX: or paste-default?
#		@context_menus.refresh()

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

	reset_state: ->
		@update_area()
		@update_view()
		@events.clear()
		@commands.clear()
		@context_menus.clear()
		@expect.update()

	screen_updated: ->
		@reset_state()
		@on_screen_updated?()

	screen_rendered: ->
#		if @is_active
#			@context_menus.refresh()
		@on_screen_rendered?()

	render_default: ->
		$(@selector).html @to_html()
		if $(@selector).is ":visible"
			$('#ime').offset $(@selector).find('.cursor').offset()

	render: ->
		@render_default()
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


##################################################
# exports
##################################################

webterm.Screen = Screen
