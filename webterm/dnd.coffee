
drag_data_to = (selector, callback) ->
	$(selector).on 'drop', (e) ->
		e.originalEvent.stopPropagation()
		e.originalEvent.preventDefault()
		callback e.originalEvent.dataTransfer
	$(selector).on 'dragover', (e) ->
		e.originalEvent.preventDefault()

drag_files_to = (selector, callback) ->
	drag_data_to selector, (data) ->
		callback data.files

webterm.dnd =
	drag_data_to: drag_data_to
	drag_files_to: drag_files_to
