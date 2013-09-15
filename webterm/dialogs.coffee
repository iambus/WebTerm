

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



confirm = (title, message, callback) ->
	if not callback?
		callback = message
		message = title
		title = '请确认'
	dialog = $ """
						 <p>
						 <span class="ui-icon ui-icon-alert" style="float: left; margin: 0 7px 20px 0;"></span>
						 <span class="dialog-message"></span>
						 </p>"""
	dialog.find('.dialog-message').text message
	result = null
	dialog.dialog
		title: title
		autoOpen: true
		modal: true
		buttons: [
			text: '确认'
			click: ->
				result = true
				$(@).dialog 'close'
		,
			text: '取消'
			click: ->
				result = false
				$(@).dialog 'close'
		]
		open: ->
#			$(@).parents('.ui-dialog-buttonpane button:eq(1)').focus() # XXX: doesn't work
			$(@).parent().find('.ui-dialog-buttonpane button:eq(1)').focus()
		close: ->
			$(@).dialog('destroy').remove()
			callback? result
	dialog.parent().keypress (e) ->
		if e.keyCode == e.charCode == 'y'.charCodeAt(0)
			$(@).find('.ui-dialog-buttonpane button:eq(0)').click()
			e.preventDefault()
			e.stopPropagation()
		else if e.keyCode == e.charCode == 'n'.charCodeAt(0)
			$(@).find('.ui-dialog-buttonpane button:eq(1)').click()
			e.preventDefault()
			e.stopPropagation()


webterm.dialogs =
	file_save: file_save
	file_open: file_open
	confirm: confirm
