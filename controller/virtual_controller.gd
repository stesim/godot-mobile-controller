extends Control


enum ButtonDirection {
	LEFT,
	RIGHT,
	UP,
	DOWN,
}


@export var joystick : VirtualJoystick

@export var buttons : Array[VirtualButton]

@export var server_url := ""


var _joystick_state := Vector2.ZERO

var _button_changes := {}

var _connection : WebSocketPeer = null



func _ready() -> void:
	for button_index in buttons.size():
		var button := buttons[button_index]
		button.button_down.connect(_on_button_state_changed.bind(button_index, true))
		button.button_up.connect(_on_button_state_changed.bind(button_index, false))

	if not server_url.is_empty():
		_connection = WebSocketPeer.new()
		var error := _connection.connect_to_url(server_url)
		if error != OK:
			push_error("Failed to connect to mobile controller server: ", error_string(error))
			_connection = null


func _process(_delta : float) -> void:
	if _connection != null:
		_connection.poll()

	_update()


func _update() -> void:
	var changes := {}

	var joystick_changed := not joystick.output.is_equal_approx(_joystick_state)
	if joystick_changed:
		_joystick_state = joystick.output
		changes.joystick = [_joystick_state.x, _joystick_state.y]

	if not _button_changes.is_empty():
		changes.buttons = _button_changes

	if not changes.is_empty():
		_send_update(changes)
		_button_changes.clear()


func _send_update(changes : Dictionary) -> void:
	var payload := JSON.stringify(changes)
	_connection.send_text(payload)


func _on_button_state_changed(button_index : int, is_pressed : bool) -> void:
	_button_changes[button_index] = is_pressed


func _create_button_state() -> Array[bool]:
	var state : Array[bool] = []
	state.resize(buttons.size())
	state.fill(false)
	return state
