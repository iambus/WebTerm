

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

simple_gesture =  (vector) ->
	if vector.length > 5
		start = vector[0]
		middle = vector[Math.floor vector.length/2]
		end = vector[vector.length - 1]
		d1 = gestrue_direction start, end
		d2 = gestrue_direction start, middle
		d3 = gestrue_direction middle, end
		if d1? and d2? and d3? and d1 == d2 == d3
			return d1

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


class Gesture
	constructor: (@at, @handler) ->
		@vector = []
		@gesture_at = new Date()
		@canvas = new GestureCanvas @at

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
			if @vector.length == 5
				@start()
			@canvas.draw_line @vector[@vector.length-1], [x, y]
		@vector.push [x, y]

	update_event: (e) ->
		@update e.offsetX, e.offsetY

	end: ->
		@canvas.hide()
		if @vector.length > 5
			@process()
			@gesture_at = new Date()
		@vector = []
		@canvas.clear()

	process: ->
		direction = simple_gesture @vector
		if direction?
			@handler? 'direction': direction

$.fn.gesture = (handler) ->

	gesture = new Gesture(@, handler)

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
