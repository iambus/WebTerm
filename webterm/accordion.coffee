
accordion_init = (div) ->
	handlers =
		'show': []
	$(div).data 'webterm-accordion-handlers', handlers
	$(div).on 'click', '> .webterm-accordion-section > h3', ->
		section = $(@).parent()
		if section.hasClass 'webterm-accordion-toggled'
			section.removeClass 'webterm-accordion-toggled'
		else
			section.addClass 'webterm-accordion-toggled'
			for callback in handlers.show
				callback $(div), section
		return

accordion_on = (div, event, callback) ->
	if not div.hasClass "webterm-accordion"
		throw new Error("Incorrect accordion element: #{div}")
	$(div).data('webterm-accordion-handlers')[event]?.push callback

accordion_methods =
	'on': accordion_on

accordion = (div, method, args...) ->
	if method?
		m = accordion_methods[method]
		if m?
			m div, args...
		else
			throw new Error("Wrong accordion method: #{method}")
	else
		accordion_init div

webterm.accordion = accordion
