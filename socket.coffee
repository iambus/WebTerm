
net = require 'net'

socket_id = 0

sockets = {}
callbacks = {}

create = (type, options, callback) ->
	if type != 'tcp'
		throw Error("Not Implemented: #{type}")

	callback
		socketId: ++socket_id

connect = (socketId, host, port, callback) ->
	client = net.connect port, host
	client.on 'data', (data) ->
		on_read = client.on_read
		client.on_read = undefined
		if on_read?
			on_read
				resultCode: 1
				data: data
		else
			console.log 'read dropped', client
	client.on 'close', ->
		console.log 'closing socket!'
	sockets[socketId] = client
	callback client # TODO: should pass an interger

read = (socketId, bufferSize, callback) ->
	if bufferSize != null
		throw Error("Not Implemented")
	client = sockets[socketId]
	client.on_read = callback


write = (socketId, data, callback) ->
	client = sockets[socketId]
	buffer = new Buffer data.byteLength
	array = new Uint8Array data
	for i in [0...buffer.length]
		buffer[i] = array[i]
	client.write buffer, null, ->
		callback
			resultCode: 1

disconnect = (socketId) ->
	client = sockets[socketId]
	client.end()

module.exports =
	create: create
	connect: connect
	read: read
	write: write
	disconnect: disconnect
