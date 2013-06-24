

get_blob = ->
	if arguments.length == 1
		{url, error, callback} = arguments
	else
		if arguments.length == 2
			[url, callback] = arguments
		else if arguments.length == 3
			[url, error, callback] = arguments
		else
			throw new Error("Invalid arguments: #{arguments}")
	xhr = new XMLHttpRequest()
	xhr.open('GET', url, true)
	xhr.responseType = 'blob'
	xhr.onload = ->
		if xhr.status == 200
			callback @response
		else
			console.error "XMLHttpRequest failed: #{xhr}"
			error? xhr
	xhr.send()

get_blobs = ->
	if arguments.length == 1
		{urls, error, callback} = arguments
	else
		if arguments.length == 2
			[urls, callback] = arguments
		else if arguments.length == 3
			[urls, error, callback] = arguments
		else
			throw new Error("Invalid arguments: #{arguments}")
	it = (url, collect) ->
		when_error = ->
			error? url, arguments...
			collect null, null
		when_ok = (response) ->
			collect null, response
		get_blob url, when_error, when_ok
	async.map urls, it, (err, results) ->
		if err?
			console.error "async error: #{err}"
			error? err
		else
			callback results

webterm.ajax =
	get_blob: get_blob
	get_blobs: get_blobs
