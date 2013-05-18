
webterm.eval = (code) ->
	CoffeeScriptEval code, $: $, webterm: webterm
