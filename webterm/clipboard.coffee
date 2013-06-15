
once_callback = null

$('#clipboard').on 'paste', (e) ->
	h = once_callback
	once_callback = null
	data = e.originalEvent.clipboardData
	h? data

get_data = (callback) ->
	once_callback = callback
	$('#clipboard').val('').select()
	document.execCommand('paste')
	$('#clipboard').val('')
	$('#ime').focus()
	return

get_files = (callback) ->
	get_data (data) ->
		# XXX: data.files is always empty!
		callback data.files

get_items = (callback) ->
	get_data (data) ->
		callback data.items

get_text = (callback) ->
	get_items (items) ->
		items[0]?.getAsString (data) ->
			callback data

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

get_sync = ->
	$('#clipboard').val('').select()
	document.execCommand('paste')
	data = $('#clipboard').val()
	$('#clipboard').val('')
	$('#ime').focus()
	data

put_sync = (text) ->
	$('#clipboard').val(text).select()
	document.execCommand('copy')
	$('#clipboard').val('')
	$('#ime').focus()

webterm.clipboard =
	get: (callback) ->
		if callback?
			get_text callback
		else
			get_sync()
	put: put_sync
	get_image_as_png_blob: get_image_as_png_blob

