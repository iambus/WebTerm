

file_save = ({text, blob, accepts}) ->
	blob = blob ? new Blob [text], type: 'text/plain'
	chrome.fileSystem.chooseEntry type: 'saveFile', accepts: accepts, (writableFileEntry) ->
		if not writableFileEntry
			console.log 'save file canceled?'
			return
		error_handler = (e) ->
			console.log 'save file error!', arguments
		writer_callback = (writer) ->
			writer.onerror = error_handler
			writer.onwriteend = (e) ->
				console.log 'save file good!', arguments
			writer.write blob
		writableFileEntry.createWriter writer_callback, error_handler

file_open = ({accepts, format}, callback) ->
	chrome.fileSystem.chooseEntry type: 'openFile', accepts: accepts, (chosenFileEntry) ->
		if not chosenFileEntry
			console.log 'No file selected'
			return

		chosenFileEntry.file (file) ->
			reader = new FileReader()
			reader.onerror = (e) ->
				console.log 'open file error!', arguments
			reader.onload = (e) ->
				callback e.target.result
			format = format ? 'text'
			if format == 'text'
				reader.readAsText file
			else if format == 'arraybuffer'
				reader.readAsArrayBuffer file
			else if format == 'binarystring'
				reader.readAsBinaryString file
			else if format == 'dataurl'
				reader.readAsDataURL file
			else
				throw new Error("Not Implemented: #{format}")

common_confirm_result = null
common_confirm_callback = null

common_confirm = (title, message, callback) ->
	if not callback?
		callback = message
		message = title
		title = '请确认'
	if common_confirm_callback?
		throw new Error("Multiple instances required for confirm dialog")
		return
	common_confirm_callback = callback
	$('#common-confirm-dialog').dialog 'option', 'title', title
	$('#common-confirm-dialog .dialog-message').text message
	$('#common-confirm-dialog').dialog 'open'

$ ->
	$('#common-confirm-dialog').dialog
		autoOpen: false
		modal: true
		buttons: [
			text: '确认'
			click: ->
				common_confirm_result = true
				$(@).dialog 'close'
		,
			text: '取消'
			click: ->
				common_confirm_result = false
				$(@).dialog 'close'
		]
		close: ->
			if common_confirm_callback?
				common_confirm_callback? common_confirm_result
			common_confirm_result = null
			common_confirm_callback = null

webterm.dialogs =
	file_save: file_save
	file_open: file_open
	confirm: common_confirm
