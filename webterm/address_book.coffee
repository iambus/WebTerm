


get_default = ->
	webterm.bbs.list


get_list = ->
	get_default()

nth = (n) ->
	get_list()[n]

size = ->
	get_list().length

lookup_host = (host) ->
	for address in get_list()
		if host == address.host
			return address
	return


connect = (n) ->
	address = nth n
	if address?
		webterm.new_bbs_tab address
	else
		console.error "address book overflow: #{n}"

webterm.address_book =
	get_list: get_list
	nth: nth
	size: size
	lookup_host: lookup_host
	connect: connect
