

user_defined = null

sync = ->
	if user_defined?
		webterm.settings.set 'address_book', user_defined

get_user_defined = ->
	if not user_defined?
		user_defined = webterm.settings.get('address_book') ? []
	user_defined

get_default = ->
	webterm.bbs.list

get_list = ->
	get_user_defined().concat get_default()

nth = (n) ->
	if 0 <= n < get_user_defined().length
		get_user_defined()[n]
	else
		get_default()[n - get_user_defined().length]

size = ->
	get_user_defined().length + get_default().length

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

add = (address) ->
	get_user_defined().push address
	sync()
	get_user_defined().length

webterm.address_book =
	get_list: get_list
	nth: nth
	size: size
	lookup_host: lookup_host
	connect: connect
	add: add
