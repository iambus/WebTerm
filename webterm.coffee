
webterm = {}

if nwDispatcher?
	webterm.platform = 'node-webkit'
else if module?.exports?
	webterm.platform = 'node'
else if chrome?
	webterm.platform = 'chrome'
else
	throw Error("Unknown webterm platform")

this.webterm = webterm
