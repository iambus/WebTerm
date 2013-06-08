
post_form = (url, data, success, error) ->
	$.ajax
		url: url
		data: data
		cache: false
		contentType: false
		processData: false
		type: 'POST'
		success: success
		error: error

file_to_blob = (file, error, callback) ->
	reader = new FileReader()
	reader.onerror = (e) ->
		error e
	reader.onload = (e) ->
		buffer = e.target.result
		blob = new Blob [buffer]
		callback blob
	reader.readAsArrayBuffer file

form_files_to_blobs = (form, todo, error, callback) ->
	if todo.length > 0
		[k, file, name] = todo.pop()
		file_to_blob file, error, (blob) ->
			form.append k, blob, name ? file.name
			form_files_to_blobs form, todo, error, callback
	else
		callback()

upload_files = ({url, form, encoding, success, error}) ->
	data = new FormData
	files = []
	for k, v of form
		if v instanceof File
			if v.size > 1000 * 1000 * 10
				# limit upload filesize to 10MB
				return error? 'file too big!'
			name = v.name
			files.push [k, v, name]
		else
			data.append k, v
	form_files_to_blobs data, files, error, ->
		post_form url, data, success, error

webterm.upload =
	upload_files: upload_files
