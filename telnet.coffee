
socket = chrome.socket

assert = (expr, message) ->
	if not expr
		logger.raise "Assert failed#{if message then ': ' + message else ''}"
#		throw new Error("Assert failed#{if message then ': ' + message else ''}")

assert_equals = (expected, given) ->
	if expected != given
		logger.raise "Expected: #{expected}, given: #{given}"
#		throw new Error("Expected: #{expected}, given: #{given}")

explain_command = ([command, option]) ->
	command_name = command_codes[command]
	if not command_name
		logger.raise "Not Implemented: #{command}"
	#		throw new Error("Not Implemented: #{command}")
	option_name = option_codes[option]
	if not option_name
		logger.raise "Not Implemented: #{option}"
	#		throw new Error("Not Implemented: #{option}")
	"#{command_name} #{option_name}"

explain_commands = (commands) ->
	(explain_command(command...) for command in commands)

class Connection
	term_type: 'ansi'
#	term_type: 'vt100'

	constructor: (@host, @port=23) ->
		@disconnected = false

		@binary_mode = false
		@out = []
		@on_data = null
		@on_connected = null
		@on_disconnected = null

		@heartbeat = 300
		@heartbeat_timer_id = null

	connect: ->
		socket.create 'tcp', {}, (info) =>
			@socketId = info.socketId
			if @socketId > 0
				socket.connect @socketId, @host, @port, (result) =>
					logger.log 'connected', @host, @port
					@on_connect()
			else
				logger.raise 'unable to create socket'

	on_connect: ->
		@on_connected?()
		@read()

	disconnect: ->
		if not @disconnected
			chrome.socket.disconnect @socketId
			@disconnected = true
			@on_disconnected?()

	reconnect: ->
		if @disconnected
			@disconnected = false
			@connect()

	read: ->
		callback = (info) =>
			if info.resultCode < 0
				console.error 'read error', info
				@disconnect() # XXX: any other possible reason?
				return
			else if info.resultCode > 0
				@reset_heartbeat()
				@on_read(info.data)
			socket.read @socketId, null, callback
		socket.read @socketId, null, callback

	on_read: (buffer) ->
#		logger.log '--'
		[commands, data] = @decode buffer
		for command in commands
			logger.log '[in]', explain_command command
			@process_command command
		if data?
			@on_data? data
		for command in @out
			logger.log '[out]', explain_command command
		@write @encode @out
		@out = []

	write: (buffer) ->
		socket.write @socketId, buffer, (info) =>
			if info.bytesWritten < 0
				console.error 'write error', info
				@disconnect() # XXX: any other possible reason?
				return
			else
				@reset_heartbeat()

	write_data: (a) ->
		@write a.buffer

	process_command: (command) ->
		negotiation = command[0]
		option = command[1]
		if negotiation == DO
			if option == TTYPE
				@out.push [WILL, TTYPE]
			else if option == NAWS
				@out.push [WILL, NAWS]
			else if option == BINARY
				@binary_mode = true
				@out.push [WILL, BINARY]
			else if option == TSPEED
				@out.push [WONT, TSPEED]
			else if option == XDISPLOC
				@out.push [WONT, XDISPLOC]
			else
				throw Error("Not Implemented: " + explain_command(command))
		else if negotiation == WILL
			if option == ECHO
				@out.push [DO, ECHO]
			else if option == SGA
				@out.push [DO, SGA]
			else if option == BINARY
				@out.push [DO, BINARY]
			else
				throw Error("Not Implemented: " + explain_command(command))
		else if negotiation == WONT
			throw Error("Not Implemented: " + explain_command(command))
		else if negotiation == SB
			assert_equals SEND, command[2]
			if option == TTYPE
				@out.push [SB, option, IS, @term_type]
			else
				throw Error("Not Implemented: " + explain_command(command))
		else
			throw Error("Not Implemented: " + explain_command(command))

	decode: (buffer) ->
		a = new Uint8Array(buffer)
		len = a.length
		if len and a[0] != IAC
			return @decode_data(buffer)
		commands = []
		data = null
		i = 0
		while i < len
			if a[i] == IAC
				++i
				if a[i] in [DONT, DO, WONT, WILL]
					negotiation = a[i++]
					option = a[i++]
					commands.push [negotiation, option]
				else if a[i] == SB
					option = a[++i]
					assert_equals SEND, a[++i]
					assert_equals IAC, a[++i]
					assert_equals SE, a[++i]
					commands.push [SB, option, SEND]
					++i
				else
					throw Error("Not Implemented: #{a[i]}")
			else
				# TODO: let decode just return a list of command or data, to support multiple data fregements
				assert data == null, 'only support single data fregement'
				b = new Uint8Array(len - i)
				bi = 0
				while i < len
					if a[i] == IAC
						++i
						if a[i] == IAC
							b[bi++] == a[i++]
						else
							--i
							break
					else
						b[bi++] = a[i++]
				data = b.subarray(0, bi)
		return [commands, data]

	decode_data: (buffer) ->
		a = new Uint8Array(buffer)
		if @binary_mode
			return [[], a]
		len = a.length
		b = new Uint8Array(len + 1)
		ai = 0
		bi = 0
		while ai < len
			if a[ai] == IAC
				++ai
				assert_equals IAC, a[ai]
				b[bi++] = a[ai++]
			else
				b[bi++] = a[ai++]
		[[], b.subarray(0, bi)]

	encode: (commands) ->
		a = []
		for command in commands
			[negotiation, option] = command
			if negotiation in [DONT, DO, WONT, WILL]
				a.push IAC
				a.push negotiation
				a.push option
			else if negotiation == SB
				assert_equals TTYPE, option
				assert_equals IS, command[2]
				a.push IAC
				a.push SB
				a.push option
				a.push command[2]
				for i in [0...command[3].length]
					a.push command[3].charCodeAt(i)
				a.push IAC
				a.push SE
			else
				throw Error("Not Implemented: #{a[i]}")
		return new Uint8Array(a).buffer


	reset_heartbeat: ->
		if @heartbeat_timer_id
			clearTimeout @heartbeat_timer_id
		if @heartbeat > 0
			callback = => @write_data new Uint8Array(1)
			@heartbeat_timer_id = setTimeout callback, @heartbeat * 1000


exports =
	Connection: Connection

this.telnet = exports




# Telnet protocol characters
IAC  = (255) # "Interpret As Command"
DONT = (254)
DO   = (253)
WONT = (252)
WILL = (251)
theNULL = (0)

SE  = (240)  # Subnegotiation End
NOP = (241)  # No Operation
DM  = (242)  # Data Mark
BRK = (243)  # Break
IP  = (244)  # Interrupt process
AO  = (245)  # Abort output
AYT = (246)  # Are You There
EC  = (247)  # Erase Character
EL  = (248)  # Erase Line
GA  = (249)  # Go Ahead
SB =  (250)  # Subnegotiation Begin


# Telnet protocol options code (don't change)
# These ones all come from arpa/telnet.h
BINARY = (0) # 8-bit data path
ECHO = (1) # echo
RCP = (2) # prepare to reconnect
SGA = (3) # suppress go ahead
NAMS = (4) # approximate message size
STATUS = (5) # give status
TM = (6) # timing mark
RCTE = (7) # remote controlled transmission and echo
NAOL = (8) # negotiate about output line width
NAOP = (9) # negotiate about output page size
NAOCRD = (10) # negotiate about CR disposition
NAOHTS = (11) # negotiate about horizontal tabstops
NAOHTD = (12) # negotiate about horizontal tab disposition
NAOFFD = (13) # negotiate about formfeed disposition
NAOVTS = (14) # negotiate about vertical tab stops
NAOVTD = (15) # negotiate about vertical tab disposition
NAOLFD = (16) # negotiate about output LF disposition
XASCII = (17) # extended ascii character set
LOGOUT = (18) # force logout
BM = (19) # byte macro
DET = (20) # data entry terminal
SUPDUP = (21) # supdup protocol
SUPDUPOUTPUT = (22) # supdup output
SNDLOC = (23) # send location
TTYPE = (24) # terminal type
EOR = (25) # end or record
TUID = (26) # TACACS user identification
OUTMRK = (27) # output marking
TTYLOC = (28) # terminal location number
VT3270REGIME = (29) # 3270 regime
X3PAD = (30) # X.3 PAD
NAWS = (31) # window size
TSPEED = (32) # terminal speed
LFLOW = (33) # remote flow control
LINEMODE = (34) # Linemode option
XDISPLOC = (35) # X Display Location
OLD_ENVIRON = (36) # Old - Environment variables
AUTHENTICATION = (37) # Authenticate
ENCRYPT = (38) # Encryption option
NEW_ENVIRON = (39) # New - Environment variables
# the following ones come from
# http://www.iana.org/assignments/telnet-options
# Unfortunately, that document does not assign identifiers
# to all of them, so we are making them up
TN3270E = (40) # TN3270E
XAUTH = (41) # XAUTH
CHARSET = (42) # CHARSET
RSP = (43) # Telnet Remote Serial Port
COM_PORT_OPTION = (44) # Com Port Control Option
SUPPRESS_LOCAL_ECHO = (45) # Telnet Suppress Local Echo
TLS = (46) # Telnet Start TLS
KERMIT = (47) # KERMIT
SEND_URL = (48) # SEND-URL
FORWARD_X = (49) # FORWARD_X
PRAGMA_LOGON = (138) # TELOPT PRAGMA LOGON
SSPI_LOGON = (139) # TELOPT SSPI LOGON
PRAGMA_HEARTBEAT = (140) # TELOPT PRAGMA HEARTBEAT
EXOPL = (255) # Extended-Options-List
NOOPT = (0)

IS = 0
SEND = 0x01


command_codes = {}
command_codes[DONT] = 'DONT'
command_codes[DO] = 'DO'
command_codes[WONT] = 'WONT'
command_codes[WILL] = 'WILL'
command_codes[SE]  = 'Subnegotiation End'
command_codes[NOP] = 'No Operation'
command_codes[DM]  = 'Data Mark'
command_codes[BRK] = 'Break'
command_codes[IP]  = 'Interrupt process'
command_codes[AO]  = 'Abort output'
command_codes[AYT] = 'Are You There'
command_codes[EC]  = 'Erase Character'
command_codes[EL]  = 'Erase Line'
command_codes[GA]  = 'Go Ahead'
command_codes[SB]  = 'Subnegotiation Begin'

option_codes = {}
option_codes[BINARY] = '8-bit data path'
option_codes[ECHO] = 'echo'
option_codes[RCP] = 'prepare to reconnect'
option_codes[SGA] = 'suppress go ahead'
option_codes[NAMS] = 'approximate message size'
option_codes[STATUS] = 'give status'
option_codes[TM] = 'timing mark'
option_codes[RCTE] = 'remote controlled transmission and echo'
option_codes[NAOL] = 'negotiate about output line width'
option_codes[NAOP] = 'negotiate about output page size'
option_codes[NAOCRD] = 'negotiate about CR disposition'
option_codes[NAOHTS] = 'negotiate about horizontal tabstops'
option_codes[NAOHTD] = 'negotiate about horizontal tab disposition'
option_codes[NAOFFD] = 'negotiate about formfeed disposition'
option_codes[NAOVTS] = 'negotiate about vertical tab stops'
option_codes[NAOVTD] = 'negotiate about vertical tab disposition'
option_codes[NAOLFD] = 'negotiate about output LF disposition'
option_codes[XASCII] = 'extended ascii character set'
option_codes[LOGOUT] = 'force logout'
option_codes[BM] = 'byte macro'
option_codes[DET] = 'data entry terminal'
option_codes[SUPDUP] = 'supdup protocol'
option_codes[SUPDUPOUTPUT] = 'supdup output'
option_codes[SNDLOC] = 'send location'
option_codes[TTYPE] = 'terminal type'
option_codes[EOR] = 'end or record'
option_codes[TUID] = 'TACACS user identification'
option_codes[OUTMRK] = 'output marking'
option_codes[TTYLOC] = 'terminal location number'
option_codes[VT3270REGIME] = '3270 regime'
option_codes[X3PAD] = 'X.3 PAD'
option_codes[NAWS] = 'window size'
option_codes[TSPEED] = 'terminal speed'
option_codes[LFLOW] = 'remote flow control'
option_codes[LINEMODE] = 'Linemode option'
option_codes[XDISPLOC] = 'X Display Location'
option_codes[OLD_ENVIRON] = 'Old - Environment variables'
option_codes[AUTHENTICATION] = 'Authenticate'
option_codes[ENCRYPT] = 'Encryption option'
option_codes[NEW_ENVIRON] = 'New - Environment variables'
option_codes[TN3270E] = 'TN3270E'
option_codes[XAUTH] = 'XAUTH'
option_codes[CHARSET] = 'CHARSET'
option_codes[RSP] = 'Telnet Remote Serial Port'
option_codes[COM_PORT_OPTION] = 'Com Port Control Option'
option_codes[SUPPRESS_LOCAL_ECHO] = 'Telnet Suppress Local Echo'
option_codes[TLS] = 'Telnet Start TLS'
option_codes[KERMIT] = 'KERMIT'
option_codes[SEND_URL] = 'SEND-URL'
option_codes[FORWARD_X] = 'FORWARD_X'
option_codes[PRAGMA_LOGON] = 'TELOPT PRAGMA LOGON'
option_codes[SSPI_LOGON] = 'TELOPT SSPI LOGON'
option_codes[PRAGMA_HEARTBEAT] = 'TELOPT PRAGMA HEARTBEAT'
option_codes[EXOPL] = 'Extended-Options-List'



