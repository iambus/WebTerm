
textarea_coffee_editor = ({id, code, listener}) ->
	if code?
		$("##{id} textarea").val code
	$("##{id} textarea").on 'input', (e) ->
		coffeescript = $(@).val()
		try
			javascript = CoffeeScript.compile coffeescript
			listener? coffeescript: coffeescript, javascript: javascript
		catch {location, message}
			if location?
				message = "##{location.first_line + 1}: #{message}"
			console.error message # TODO: print in status bar

ace_coffee_editor = ({id, code, listener}) ->
	editor = ace.edit id
#	editor.setTheme("ace/theme/monokai")
	editor.setTheme("ace/theme/merbivore_soft")
	editor.getSession().setMode("ace/mode/coffee")
	editor.getSession().setTabSize(2)
#	editor.renderer.setShowGutter(false)
	if code?
		editor.setValue code
		editor.navigateFileStart()
	editor.getSession().on 'change', (e) ->
		coffeescript = editor.getValue()
		try
			javascript = CoffeeScript.compile coffeescript
			listener? coffeescript: coffeescript, javascript: javascript
		catch {location, message}
			if location?
				message = "##{location.first_line + 1}: #{message}"
			console.error message # TODO: print in status bar
	editor.commands.addCommand
		name: 'eval',
		bindKey: 'Ctrl-Enter'
		exec: (editor) ->
			webterm.eval editor.getValue()
	return editor

webterm.editors =
	textarea_coffee_editor: textarea_coffee_editor
	ace_coffee_editor: ace_coffee_editor
