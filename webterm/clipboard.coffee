
once_callback = null

$('#clipboard').on 'paste', (e) ->
	h = once_callback
	once_callback = null
	data = e.originalEvent.clipboardData
	h? data

paste_data = (callback) ->
	once_callback = callback
	$('#clipboard').val('').select()
	document.execCommand('paste')
	$('#clipboard').val('')
	$('#ime').focus()
	return

get_items = (callback) ->
	paste_data (data) ->
		callback data.items

get_image_as_png_blob = (callback, error) ->
	error = error ? (x) -> console.error x
	get_items (items) ->
		image = items[0]
		if not image?
			error? 'Clipboard is empty'
			return
		if image.type != 'image/png'
			error? "Clipboard data is not image/png: #{image.type}"
			return
		file = image.getAsFile()
		reader = new FileReader()
		reader.onerror = (e) ->
			error? "open image error #{arguments}"
		reader.onload = (e) ->
			callback new Blob [e.target.result]
		reader.readAsArrayBuffer file

webterm.clipboard =
	get: ->
		$('#clipboard').val('').select()
		document.execCommand('paste')
		data = $('#clipboard').val()
		$('#clipboard').val('')
		$('#ime').focus()
		data
	put: (text) ->
		$('#clipboard').val(text).select()
		document.execCommand('copy')
		$('#clipboard').val('')
		$('#ime').focus()
	get_image_as_png_blob: get_image_as_png_blob

