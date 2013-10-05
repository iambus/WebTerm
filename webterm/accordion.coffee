
section_toggle = (accordion, section, handlers) ->
	if section.hasClass 'webterm-accordion-toggled'
		section.removeClass 'webterm-accordion-toggled'
	else
		section.addClass 'webterm-accordion-toggled'
		for callback in handlers.show
			callback accordion, section
	return

accordion_toggle = (section_div) ->
	section = $(section_div)
	if not section.hasClass "webterm-accordion-section"
		console.error section
		throw new Error("Incorrect accordion section element: #{section}")
	accordion = section.parents('.webterm-accordion')
	if accordion.length == 0
		throw new Error(".webterm-accordion not found in path")
	handlers = accordion.data 'webterm-accordion-handlers'
	section_toggle accordion, section, handlers

accordion_init = (div) ->
	handlers =
		'show': []
	div = $(div)
	div.data 'webterm-accordion-handlers', handlers
	div.on 'click', '> .webterm-accordion-section > h3', ->
		section = $(@).parent()
		section_toggle div, section, handlers

accordion_on = (div, event, callback) ->
	if not div.hasClass "webterm-accordion"
		console.error div
		throw new Error("Incorrect accordion element: #{div}")
	$(div).data('webterm-accordion-handlers')[event]?.push callback

accordion_methods =
	'on': accordion_on
	'toggle': accordion_toggle

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
