
##################################################
# algorithms
##################################################

# trivial: only support up/down/left/right

gestrue_direction = ([x1, y1], [x2, y2]) ->
	x = x2 - x1
	y = y2 - y1
	if x > 2 * Math.abs y
		return 'right'
	if x < -2 * Math.abs y
		return 'left'
	if y > 2 * Math.abs x
		return 'down'
	if y < -2 * Math.abs x
		return 'up'

trivial_gesture =  (vector) ->
	minimum_samples = 5
	if vector.length > minimum_samples
		start = vector[0]
		middle = vector[Math.floor vector.length/2]
		end = vector[vector.length - 1]
		d1 = gestrue_direction start, end
		d2 = gestrue_direction start, middle
		d3 = gestrue_direction middle, end
		if d1? and d2? and d3? and d1 == d2 == d3
			return d1

# simple: only support up/down/left/right
# http://doc.qt.digia.com/qq/qq18-mousegestures.html

filter_and_limit = (vector) ->
	minimum_movement = 5
	minimum_movement2 = minimum_movement * minimum_movement
	# filter and limit
	directions = []
	[x0, y0] = vector[0]
	for i in [1...vector.length]
		[x1, y1] = vector[i]
		dx = x1 - x0
		dy = y1 - y0
		if dx*dx + dy*dy >= minimum_movement2
			if dy > 0
				if dx > dy or -dx > dy
					dy = 0
				else
					dx = 0
			else
				if dx > -dy or -dx > -dy
					dy = 0
				else
					dx = 0
			directions.push [dx, dy]
			x0 = x1
			y0 = y1
	return directions

simplify = (vector) ->
	if vector.length == 0
		return vector
	directions = []
	[x0, y0] = vector[0]
	for i in [1...vector.length]
		[x1, y1] = vector[i]
		if x0 * x1 + y0 * y1 > 0
			x0 += x1
			y0 += y1
		else
			directions.push [x0, y0]
			x0 = x1
			y0 = y1
	directions.push [x0, y0]
	return directions

calculate_length = (directions) ->
	total = 0
	for [x, y] in directions
		total += Math.abs(x) + Math.abs(y)
	return total

remove_shortest = (directions) ->
	if directions.length <= 1
		return []
	shortest = 0
	index = 0
	for i in [0...directions.length]
		[x, y] = directions[i]
		n = Math.abs(x) + Math.abs(y)
		if i == 0
			shortest = n
		else
			if n < shortest
				shortest = n
				index = i
	directions.splice index, 1
	return directions

match_gesture = (directions, gesture) ->
	if directions.length == gesture.length
		for i in [0...directions.length]
			[x0, y0] = directions[i]
			[x1, y1] = gesture[i]
			if x0*x1 + y0*y1 <= 0
				return false
		return true

find_matched_gesture = (directions, gestures) ->
	for gesture in gestures
		if match_gesture directions, gesture
			return gesture

match_and_reduce = (directions, gestures) ->
	directions = simplify directions
	minimum_match = 0.9
	minimum_length = calculate_length(directions) * minimum_match
	while directions.length and calculate_length(directions) > minimum_length
		gesture = find_matched_gesture(directions, gestures)
		if gesture
			return gesture
		directions = simplify remove_shortest directions

parse_gesture_directions = (gesture) ->
	directions = []
	for direction in gesture.split ' '
		if direction == 'left'
			directions.push [-1, 0]
		else if direction == 'right'
			directions.push [1, 0]
		else if direction == 'up'
			directions.push [0, -1]
		else if direction == 'down'
			directions.push [0, 1]
		else
			throw Error("Invalid gesture direction: #{direction}")
	return directions

simple_gesture = (vector) ->
	if vector.length <= 1
		return
	directions = filter_and_limit vector
	if not directions?.length
		return
	directions = simplify directions
	direction_text = ([x, y]) ->
		if x == 0
			if y > 0
				'down'
			else
				'up'
		else
			if x > 0
				'right'
			else
				'left'
	(direction_text direction for direction in directions).join ' '

simple_gesture_recognize = (vector, gestures) ->
	if vector.length <= 1
		return
	directions = filter_and_limit vector
	if not directions?.length
		return
	convert_gesture = (g) ->
		gg = parse_gesture_directions(g)
		gg.text = g
		gg
	match_and_reduce(directions, (convert_gesture g for g in gestures))?.text

##################################################
# front end
##################################################

class GestureCanvas
	constructor: (@master) ->
		@id = "gesture_canvas_" + new Date().getTime()
		$('body').append "<canvas id='#{@id}'/>"
		@element = $('#'+@id)
		@element.css
			'background-color': 'rgba(0, 0, 0, 0)'
			'position': 'absolute'
			'z-index': -10

		@canvas = @element[0]
		@context = @canvas.getContext("2d")

		set_canvas_size = => @resize()
		#	set_canvas_size() # XXX: if I call set_canvas_size immidately, it gets size before the initial window resize. why?
		setTimeout set_canvas_size, 100
		$(window).resize set_canvas_size

	resize: ->
		@element.offset(@master.offset()).prop width: @master.width(), height: @master.height()

	show: ->
		@element.css 'z-index': 'auto'

	hide: ->
		@element.css 'z-index': -10

	draw_line: ([x1, y1], [x2, y2])->
		@context.strokeStyle = 'orangered'
		@context.lineWidth = 2
		@context.beginPath()
		@context.moveTo x1, y1
		@context.lineTo x2, y2
		@context.stroke()

	clear: ->
		@context.clearRect(0, 0, @canvas.width, @canvas.height)

class GestureEvent
	constructor: (@vector) ->
#		@direction = simple_gesture @vector
	recognize_gesture: (gestures) ->
		simple_gesture_recognize @vector, gestures

class GestureManager
	constructor: (@at, @handler) ->
		@vector = []
		@gesture_at = new Date()
		@canvas = new GestureCanvas @at
		@minimum_samples = 1

	trace: ->
		@vector = []

	start: ->
		@canvas.show()

	cancel: ->
		@canvas.hide()
		@vector = []
		@canvas.clear()

	update: (x, y) ->
		if @vector.length > 0
			if @vector.length == @minimum_samples
				@start()
			@canvas.draw_line @vector[@vector.length-1], [x, y]
		@vector.push [x, y]

	update_event: (e) ->
		@update e.offsetX, e.offsetY

	end: ->
		@canvas.hide()
		if @vector.length > @minimum_samples
			@process()
			@gesture_at = new Date()
		@vector = []
		@canvas.clear()

	process: ->
		@handler new GestureEvent @vector

$.fn.gesture = (handler) ->

	gesture = new GestureManager(@, handler)

	@mousedown (e) ->
		if e.button != 2
			return
		gesture.trace()
	@mouseup (e) ->
		if e.button != 2
			return
		gesture.end()
	@mousemove (e) ->
		if e.button != 2
			return
		gesture.update_event e
	@contextmenu (e) ->
		if new Date() - gesture.gesture_at < 500
			e.preventDefault()

	# TODO: mouseout?

	gesture.canvas.element.mousedown -> gesture.cancel()
	gesture.canvas.element.mouseup -> gesture.end()
	gesture.canvas.element.mousemove (e) ->
		if e.button != 2
			return
		gesture.update_event e
