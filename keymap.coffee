
##################################################
# constants
##################################################

key_to_code_table =
	"Backspace":8
	"Tab":9
	"Enter":13
	"Shift":16
	"Ctrl":17
	"Alt":18
	"Pause/Break":19
	"CapsLock":20
	"Esc":27
	"Space":32
	"PageUp":33
	"PageDown":34
	"End":35
	"Home":36
	"Left":37
	"Up":38
	"Right":39
	"Down":40
	"Insert":45
	"Delete":46
	"0":48
	"1":49
	"2":50
	"3":51
	"4":52
	"5":53
	"6":54
	"7":55
	"8":56
	"9":57
	"A":65
	"B":66
	"C":67
	"D":68
	"E":69
	"F":70
	"G":71
	"H":72
	"I":73
	"J":74
	"K":75
	"L":76
	"M":77
	"N":78
	"O":79
	"P":80
	"Q":81
	"R":82
	"S":83
	"T":84
	"U":85
	"V":86
	"W":87
	"X":88
	"Y":89
	"Z":90
	"Windows":91
	"RightClick":93
	"Numpad0":96
	"Numpad1":97
	"Numpad2":98
	"Numpad3":99
	"Numpad4":100
	"Numpad5":101
	"Numpad6":102
	"Numpad7":103
	"Numpad8":104
	"Numpad9":105
	"Numpad*":106
	"Numpad+":107
	"Numpad-":109
	"Numpad.":110
	"Numpad/":111
	"F1":112
	"F2":113
	"F3":114
	"F4":115
	"F5":116
	"F6":117
	"F7":118
	"F8":119
	"F9":120
	"F10":121
	"F11":122
	"F12":123
	"Num Lock":144
	"ScrollLock":145
	"MyComputer":182
	"MyCalculator":183
	";":186
	"=":187
	"+":188
	"-":189
	".":190
	"/":191
	"`":192
	"[":219
	"\\":220
	"]":221
	"'":222

key_to_code = {}
key_to_code[k.toLowerCase()] = v for k, v of key_to_code_table

code_to_key = {}
code_to_key[v] = k for k, v of key_to_code


key_to_ascii_table =
	space: ' '
	whitespace: ' '
	backspace: '\x08'
	delete: '\x7f'
#	enter: '\r\n'
	enter: '\r'
	tab: '\t'
	esc: '\x1b'
	up: '\x1b\x5b\x41'
	down: '\x1b\x5b\x42'
	right: '\x1b\x5b\x43'
	left: '\x1b\x5b\x44'
	home: '\x1b[1~'
	end: '\x1b[4~'
	pageup: '\x1b[5~'
	pagedown: '\x1b[6~'
	insert: '\x1b[2~'
	f1: '\x1b[11~'
	f2: '\x1b[12~'
	f3: '\x1b[13~'
	f4: '\x1b[14~'
	f6: '\x1b[17~'
	f7: '\x1b[18~'
	f8: '\x1b[19~'
	f9: '\x1b[20~'
	f10: '\x1b[21~'
	f11: '\x1b[22~'

key_to_ascii_table['ctrl-'+String.fromCharCode(x)] = String.fromCharCode(x-96) for x in [97..122]

##################################################
# mappings
##################################################

event_to_virtual_key = (event) ->
	ctrl = event.ctrlKey
	shift = event.shiftKey
	alt = event.altKey
	meta = event.metaKey

	if event.charCode == 0
		charCode = null
		keyCode = event.keyCode
		k = code_to_key[keyCode]
		if keyCode == 229
			# ignore ime event
			return null
	else if event.charCode == event.keyCode
		charCode = event.charCode
		keyCode = null
		k = String.fromCharCode(charCode)
		if k == '\r'
			return 'enter'
		else
			return k
	else
		throw Error("Not Implemented charCode: #{event.charCode}, keyCode: #{event.keyCode}")

	if not (ctrl or shift or alt or meta)
		return k
	else
		a = []
		if ctrl
			a.push 'ctrl'
		if shift
			a.push 'shift'
		if alt
			a.push 'alt'
		if meta
			a.push 'meta'
		if k not in ['ctrl', 'shift', 'alt', 'meta']
			a.push k
		return a.join '-'

virtual_key_to_ascii = (k) ->
	k = k.replace('ctrl+', 'ctrl-')
	k = k.replace('shift+', 'shift-')
	k = k.replace('alt+', 'alt-')
	k = k.replace('meta+', 'meta-')
	x = key_to_ascii_table[k]
	if x
		return x
	if k.length == 1
		return k

##################################################
# export
##################################################

exports = this
exports.keymap =
	event_to_virtual_key: event_to_virtual_key
	virtual_key_to_ascii: virtual_key_to_ascii


