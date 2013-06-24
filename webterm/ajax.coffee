

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

webterm.ajax =
	get_blob: get_blob
