

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

