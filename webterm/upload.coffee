
##################################################
# multipart for non-utf-8 encoding
##################################################

generate_boundary = ->
	'----WebTermFormBoundary' + btoa(Math.random()).replace /[=]+$/, ''

class GBKFormData
	constructor: ->
		@data = []
		@boundary = generate_boundary()
	append: (k, v, filename) ->
		@data.push '--'
		@data.push @boundary
		@data.push '\r\n'
		if filename?
			@data.push encoding.string_to_gbk """Content-Disposition: form-data; name="#{k}"; filename="#{filename}"\r\nContent-Type: text/plain\r\n\r\n"""
			@data.push v
			@data.push """\r\n"""
		else
			@data.push """Content-Disposition: form-data; name="#{k}"\r\n\r\n#{v}\r\n"""
	end: ->
		@data.push '--'
		@data.push @boundary
		@data.push '--\r\n'
	to_blob: ->
		new Blob @data

post_gbk_form = (url, data, success, error) ->
	data.end()
	blob = data.to_blob()
#	reader = new FileReader
#	reader.onload = (data) ->
#		console.log data.target.result
#	reader.readAsText blob
	$.ajax
		url: url
		data: blob
		cache: false
		contentType: "multipart/form-data; boundary=#{data.boundary}"
		processData: false
		type: 'POST'
		success: success
		error: error

##################################################
# upload
##################################################

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
	if encoding == 'gbk'
		data = new GBKFormData()
	else if encoding?
		throw new Error("Not supported encoding: #{encoding}")
	else
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
		if data instanceof GBKFormData
			post_gbk_form url, data, success, error
		else
			post_form url, data, success, error

webterm.upload =
	upload_files: upload_files
