
##################################################
# imports
##################################################

if module?.exports?
	indexes = require('./encoding-indexes')
	exports = module.exports
else
	this.encoding = this.encoding ? {}
	exports = this.encoding
	indexes = exports

##################################################
# iso-8859-1
##################################################

string_to_cp1252 = (s) ->
	a = new Uint8Array(s.length)
	for i in [0...s.length]
		a[i] = s.charCodeAt(i)
	return a

cp1252_to_string = (bytes) ->
	String.fromCharCode.apply null, bytes

##################################################
# gbk/gb18030 indexes
##################################################

{gbk_index, gb18030_index} = indexes

throw new Error('No encoding indexes!') unless gbk_index and gbk_index

##################################################
# gbk/gb18030
##################################################

indexPointerFor = (code_point, index) ->
	pointer = index.indexOf(code_point)
	return if pointer == -1 then null else pointer

indexCodePointFor = (pointer, index) ->
	(index || [])[pointer] || null

indexGB18030PointerFor = (code_point) ->
	offset = 0
	pointer_offset = 0
	index = gb18030_index
	for i in [0...index.length]
		entry = index[i]
		if entry[1] <= code_point
			offset = entry[1]
			pointer_offset = entry[0]
		else
			break
	pointer_offset + code_point - offset

div = (x, y) ->
	Math.floor x / y

string_to_gbk = (s) ->
#	TextEncoder('gbk').encode s
	a = []
	for i in [0...s.length]
		c = s.charCodeAt(i)
		if 0 <= c <= 0x7f
			a.push c
		else
			pointer = indexPointerFor c, gbk_index
			if pointer?
				lead = div(pointer, 190) + 0x81
				trail = pointer % 190
				offset = if trail < 0x3f then 0x40 else 0x41
				a.push lead
				a.push trail + offset
			else
				# a.push 0x3f # '?'
				# gb18030
				pointer = indexGB18030PointerFor c
				byte1 = div(div(div(pointer, 10), 126), 10)
				pointer = pointer - byte1 * 10 * 126 * 10
				byte2 = div(div(pointer, 10), 126)
				pointer = pointer - byte2 * 10 * 126
				byte3 = div(pointer, 10)
				byte4 = pointer - byte3 * 10
				a.push byte1 + 0x81
				a.push byte2 + 0x30
				a.push byte3 + 0x81
				a.push byte4 + 0x30

	return new Uint8Array(a)



gbk_to_string_partial = (bytes) ->
#	TextDecoder('gbk').decode bytes
	a = []
	left = []
	i = 0
	len = bytes.length
	while i < len
		if i < 0
			throw Error("Internal error: i < 0 !")
		b = bytes[i++]
		if 0 <= b <= 0x7f
			a.push b
		else if b == 0x80
			a.push 0x20ac
		else if 0x81 <= b <= 0xfe
			b2 = bytes[i++]
			if not b2?
				left.push b
				break
			if 0x30 <= b2 <= 0x39
				# gb18030
				b3 = bytes[i++]
				if not b3?
					left.push b
					left.push b2
					break
				if 0x81 <= b3 <= 0xfe
					b4 = bytes[i++]
					if not b4?
						left.push b
						left.push b2
						left.push b3
						break
					if 0x30 <= b4 <= 0x39
						a.push (b - 0x81) * 10 + (b2 - 0x30) * 126 + (b3 - 0x81) * 10 + b4 - 0x30
					else
						i -= 3
						if i < 0
							throw "Not Implemented"
						a.push 0x3f # '?'
				else
				i -= 2
				if i < 0
					throw "Not Implemented"
				a.push 0x3f # '?'
			else
				# gbk
				lead = b
				offset = if b2 < 0x7f then 0x40 else 0x41
				if 0x40 <= b2 <= 0x7e or 0x80 <= b2 <= 0xfe
					pointer = (lead - 0x81) * 190 + (b2 - offset)
					a.push indexCodePointFor(pointer, gbk_index)
				else
					--i
					a.push 0x3f # '?'
		else
			a.push 0x3f # '?'

	return [String.fromCharCode.apply(null, a), left]

gbk_to_string = (bytes) ->
	[s, left] = gbk_to_string_partial(bytes)
	s += '?' for [0...left.length]
	return s

##################################################
# exports
##################################################

exports.string_to_cp1252 = string_to_cp1252
exports.cp1252_to_string = cp1252_to_string
exports.string_to_gbk = string_to_gbk
exports.gbk_to_string = gbk_to_string
exports.gbk_to_string_partial = gbk_to_string_partial

