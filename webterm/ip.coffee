
##################################################
# imports
##################################################

if module?.exports?
	encoding = require '../encoding'
else
	encoding = this.encoding


##################################################
# QQWry implementation
##################################################

class QQWry
	# http://lumaqq.linuxsir.org/article/qqwry_format_detail.html
	constructor: (@array) ->
		@view = new DataView @array.buffer
		@offset = 0
		@start = @view.getUint32 0, true
		@end = @view.getUint32 4, true
		console.log "IP file size: #{@array.length}, index range: #{@start}, #{@end}"

	seek: (@offset) ->

	parse_ip_string: (ip) ->
		p4 = ((if n == '*' then 0 else parseInt(n)) for n in ip.split '.')
		if p4.length != 4
			throw new Error("Invalid IP address: #{ip}")
		return (p4[0] * Math.pow(2, 24)) + (p4[1] * Math.pow(2, 16)) + (p4[2] * Math.pow(2, 8)) + p4[3] # don't use bitwise, which will overflow

	unparse_ip_number: (n) ->
		"#{0xff & n >> 24}.#{0xff & n >> 16}.#{0xff & n >> 8}.#{0xff & n}"

	read_offset: ->
		a = @array[@offset++]
		b = @array[@offset++]
		c = @array[@offset++]
		return a | b << 8 | c << 16

	read_string: ->
		buffer = []
		while c = @array[@offset++]
			buffer.push c
		return encoding.gbk_to_string(buffer)

	read_ip_number: ->
		@view.getUint32 @offset, true

	read_ip_number_at: (@offset) ->
		@read_ip_number()

	read_ip_offset_at: (offset) ->
		@seek offset + 4
		@read_offset()

	binary_search: (ip_number, start, end) ->
		if (end - start) % 7 != 0
			throw new Error("Invalid file? offset: [#{start}, #{end}]")
		a = @read_ip_number_at start
		if a == ip_number
			return @read_ip_offset_at start
		b = @read_ip_number_at end
		if b == ip_number
			return @read_ip_offset_at end
		if end - start <= 7
			return @read_ip_offset_at start
		middle = start + Math.floor((end - start) / 14) * 7
		c = @read_ip_number_at middle
		if ip_number < c
			return @binary_search ip_number, start, middle
		else
			return @binary_search ip_number, middle, end

	read_address_at: (offset) ->
		@seek offset + 4
		n = @array[@offset]
		if n == 1
			@offset++
			country_offset = @read_offset()
			@seek country_offset
			n = @array[@offset]
			if n == 2
				@offset++
				@seek @read_offset()
				country = @read_string()
				@seek country_offset + 4
			else
				country = @read_string()
			area = @read_area()
			return [country, area]
		else if n == 2
			@offset++
			country_offset = @read_offset()
			@seek country_offset
			country = @read_string()
			@seek country_offset + 8
			area = @read_area()
			return [country, area]
		else
			@read_string()

	read_area: ->
		n = @array[@offset]
		if n == 1
			throw new Error("Not Implemented")
		else if n == 2
			@offset++
			offset = @read_offset()
			if offset == 0
				throw new Error("Not Implemented")
			else
				@seek offset
				@read_string()
		else
			@read_string()

	lookup: (ip_string) ->
		if ip_string.match /^(\d+\.){3}(\d+|\*)$/
			@read_address_at @binary_search @parse_ip_string(ip_string), @start, @end
		else
			throw new Error("Invalid IP address: #{ip_string}")

##################################################
# storage, API, etc
##################################################

storage_key = 'ip_qq_1'

service = null
callbacks = []

binary_string_to_array = (s) ->
	array = new Uint8Array s.length
	for i in [0...s.length]
		array[i] = s.charCodeAt i
	array

delete_from_local_storage = ->
	webterm.storage.remove storage_key
	service = null

save_to_local_storage = (s) ->
	webterm.storage.set storage_key, btoa s

load_from_local_storage = (callback) ->
	webterm.storage.get storage_key, (s) ->
		if s?
			service = new QQWry binary_string_to_array atob s
			callback? true
		else
			callback? false

load_from_file_system = ->
	webterm.dialogs.file_open accepts: [extensions: ['dat']], format: 'binarystring', (s) ->
		console.log 'IP file loaded'
		save_to_local_storage s
		console.log "binary string length: #{s.length}"
		service = new QQWry binary_string_to_array s
		console.log 'IP service ready'

lookup_ip = (ip, callback) ->
	if service?
		if service
			if callback?
				callback service.lookup ip
			else
				service.lookup ip
		else
			throw new Error("IP service not ready")
	else
		throw new Error("IP service not installed")

##################################################
# imports
##################################################


if module?.exports?
	module.exports =
		QQWry: QQWry
else
	webterm.ip =
		load_from_file_system: load_from_file_system
		load_from_local_storage: load_from_local_storage
		is_service_installed: -> !! service
		lookup: lookup_ip
		load: load_from_local_storage
		install: load_from_file_system
		uninstall: delete_from_local_storage
