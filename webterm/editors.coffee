
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
			webterm.status_bar.error message
			console.error message

ace_coffee_editor = ({id, code, listener}) ->
	editor = ace.edit id
#	editor.setTheme("ace/theme/monokai")
	editor.setTheme("ace/theme/merbivore_soft")
	editor.getSession().setMode("ace/mode/coffee")
	editor.getSession().setTabSize(2)
#	editor.renderer.setShowGutter(false)
	if code?
		editor.getSession().setValue code
	editor.getSession().on 'change', (e) ->
		coffeescript = editor.getSession().getValue()
		try
			javascript = CoffeeScript.compile coffeescript
			listener? coffeescript: coffeescript, javascript: javascript
		catch {location, message}
			if location?
				message = "##{location.first_line + 1}: #{message}"
			webterm.status_bar.error message
			console.error message
	editor.commands.addCommand
		name: 'eval',
		bindKey: 'Ctrl-Enter'
		exec: (editor) ->
			webterm.eval editor.getSession().getValue()
	return editor

webterm.editors =
	textarea_coffee_editor: textarea_coffee_editor
	ace_coffee_editor: ace_coffee_editor
