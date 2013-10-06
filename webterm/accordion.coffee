
section_toggle = (accordion, section) ->
	if section.hasClass 'webterm-accordion-toggled'
		section.removeClass 'webterm-accordion-toggled'
	else
		section.addClass 'webterm-accordion-toggled'
		section.trigger 'show', accordion, section
	return

accordion_toggle = (section_div) ->
	section = $(section_div)
	if not section.hasClass "webterm-accordion-section"
		console.error section
		throw new Error("Incorrect accordion section element: #{section}")
	accordion = section.parents('.webterm-accordion')
	if accordion.length == 0
		throw new Error(".webterm-accordion not found in path")
	section_toggle accordion, section

accordion_init = (div) ->
	div = $(div)
	div.on 'click', '> .webterm-accordion-section > h3', ->
		section = $(@).parent()
		section_toggle div, section

accordion_methods =
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
