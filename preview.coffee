
load_image = (url, callback) ->
	xhr = new XMLHttpRequest()
	xhr.open('GET', url, true)
	xhr.responseType = 'blob'
	xhr.onload = ->
		if @response.size > 0
			callback window.webkitURL.createObjectURL @response
		else
			callback()
	xhr.send()


resize = ->
	window_width = $('body').width()
	window_height = $('body').height()
	w = $('#preview img').width()
	h = $('#preview img').height()
	if window_width/2 < w or window_height/2 < h
		r1 = w * 2 / window_width
		r2 = h * 2 / window_height
		r = if r1 > r2 then r1 else r2
		w = w/r
		h = h/r
		$('#preview img').width(w).height(h)

mousemove = (e) ->
	window_width = $('body').width()
	window_height = $('body').height()
	w = $('#preview img').width()
	h = $('#preview img').height()
	top = e.pageY
	left = e.pageX
	if window_height - top < h
		top = top - h - 10
	else
		top += 10
	if window_width - left < w
		left = left - w - 10
	else
		left += 10
	$('#preview').css
		top: "#{top}px"
		left: "#{left}px"


$.fn.preview = ->
	container = $('#preview')
	if container.length == 0
		container = $('<div/>')
			.attr('id', 'preview')
			.append('<p class="preview-loading-message">loading...</p>').hide()
			.append('<p class="preview-loading-error-message">loading error</p>').hide()
			.append('<img/>').hide()
			.css('position', 'absolute')
			.appendTo('body')
		container.mouseleave ->
			hover_out()

	img = $ 'img', container

	images = @filter -> @getAttribute('href').match /\.(jpg|jpeg|png|gif|bmp)$/i
	images.mousemove mousemove
#	images.mousemove (e) ->
#		container.css
#			top: "#{e.pageY + 10}px"
#			left: "#{e.pageX + 10}px"
	hover_in = (e) ->
		link = @getAttribute('href')
		container.addClass('preview-loading').show()
		img.load ->
			container.removeClass('preview-loading').removeClass('preview-loading-error')
			resize(img)
			mousemove(e)
			img.show()
#		img.attr 'src', link
		img.attr 'loading', link
		load_image link, (data) =>
#			if $(@).is ':visible'
			if img.attr('loading') == link
				if data
					img.attr 'src', data
				else
					container.addClass('preview-loading-error')
	hover_out = ->
		container.hide()
		img.unbind('load').attr('src', '').css(width:'', height:'').hide()
	images.hover hover_in, hover_out

