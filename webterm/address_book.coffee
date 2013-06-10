


get_default = ->
	webterm.bbs.list


get_list = ->
	get_default()

nth = (n) ->
	get_list()[n]

size = ->
	get_list().length

webterm.address_book =
	get_list: get_list
	nth: nth
	size: size
