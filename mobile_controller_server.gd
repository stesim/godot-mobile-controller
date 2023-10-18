class_name MobileControllerServer
extends Node


signal client_added(id : int)

signal client_removed(id : int)


@export var input_mapping : MobileControllerMapping

@export var port := 9080

@export var address := "*"

@export var accept_new_clients := false :
	set(value):
		if value != accept_new_clients:
			accept_new_clients = value
			if accept_new_clients:
				_start_listening()
			else:
				_stop_listening()


var _server := TCPServer.new()

var _clients : Array[WebSocketPeer] = []

var _client_ids := {}

var _client_id_counter := 100


func _process(_delta : float) -> void:
	if _server.is_listening():
		_handle_connection_requests()

	_handle_clients()


func _handle_connection_requests() -> void:
	if _server.is_connection_available():
		_accept_connection()


func _handle_clients() -> void:
	for client in _clients:
		client.poll()

		match client.get_ready_state():
			WebSocketPeer.STATE_OPEN:
				while client.get_available_packet_count() > 0:
					var packet := client.get_packet()
					_handle_client_packet(client, packet)
			WebSocketPeer.STATE_CLOSED:
				_erase_client.call_deferred(client)


func _accept_connection() -> void:
	var connection := _server.take_connection()
	if connection == null:
		return

	var client := WebSocketPeer.new()
	var error = client.accept_stream(connection)
	if error != OK:
		push_error("Failed to start mobile controller server (port = %d, address = %s): %s" % [port, address, error_string(error)])
		return

	_clients.push_back(client)
	var id := _client_id_counter
	_client_ids[client] = id
	_client_id_counter += 1

	print("Accepted mobile controller client.")
	client_added.emit(id)


func _reject_connection() -> void:
	var connection := _server.take_connection()
	if connection != null:
		connection.disconnect_from_host()


func _erase_client(client : WebSocketPeer) -> void:
	_clients.erase(client)
	var id : int = _client_ids[client]
	_client_ids.erase(client)
	print("Terminated mobile controller client connection.")
	client_removed.emit(id)


func _handle_client_packet(client : WebSocketPeer, packet : PackedByteArray) -> void:
	var packet_string := packet.get_string_from_utf8()
	if packet_string.is_empty():
		# TODO: kick client because of invalid packets?
		return
	var payload : Variant = JSON.parse_string(packet_string)
	if payload == null:
		# TODO: kick client because of invalid packets?
		return

	var id : int = _client_ids[client]
	_emulate_inputs(id, payload)


func _emulate_inputs(device_id : int, payload : Dictionary) -> void:
	if input_mapping == null:
		return

	var joystick_state : Variant = payload.get(&"joystick")
	var is_joystick_state_valid : bool = (
		joystick_state != null
		and joystick_state is Array
		and joystick_state.size() == 2
		and joystick_state[0] is float
		and joystick_state[1] is float
	)
	if is_joystick_state_valid:
		var state_vector := Vector2(joystick_state[0], joystick_state[1])
		input_mapping.handle_stick_input(device_id, state_vector)

	var buttons_state : Variant = payload.get(&"buttons")
	var is_buttons_state_valid : bool = (
		buttons_state != null
		and buttons_state is Dictionary
	)
	if is_buttons_state_valid:
		for key in buttons_state:
			if not buttons_state[key] is bool:
				continue
			var state : bool = buttons_state[key]
			var button_index := int(key)
			input_mapping.handle_button_input(device_id, button_index, state)


func _start_listening() -> void:
	var error := _server.listen(port, address)
	if error != OK:
		push_error("Failed to start mobile controller server (port = %d, address = %s): %s" % [port, address, error_string(error)])
		return
	print("Started mobile controller server.")


func _stop_listening() -> void:
	_server.stop()
