

upload_files = ({url, form, success, error}) ->
	data = new FormData
	for k, v of form
		data.append k, v
	$.ajax
		url: url
		data: data
		cache: false
		contentType: false
		processData: false
		type: 'POST'
		success: success
		error: error

webterm.upload =
	upload_files: upload_files
