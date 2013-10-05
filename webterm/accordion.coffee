
accordion = (div) ->
	$(div).on 'click', '> .webterm-accordion-section > h3', ->
		section = $(@).parent()
		if section.hasClass 'webterm-accordion-toggled'
			section.removeClass 'webterm-accordion-toggled'
		else
			section.addClass 'webterm-accordion-toggled'



webterm.accordion = accordion
