class_name MobileControllerPhysicalMapping
extends MobileControllerMapping


enum StickSide {
	LEFT,
	RIGHT,
}


@export var stick_side := StickSide.LEFT

@export var button_indices : Array[int] = [0, 1, 2, 3]


func handle_stick_input(client_index : int, state : Vector2) -> void:
	var horizontal_input := InputEventJoypadMotion.new()
	horizontal_input.axis = JOY_AXIS_LEFT_X if stick_side == StickSide.LEFT else JOY_AXIS_RIGHT_X
	horizontal_input.axis_value = state.x
	horizontal_input.device = client_index
	Input.parse_input_event(horizontal_input)

	var vertical_input := InputEventJoypadMotion.new()
	vertical_input.axis = JOY_AXIS_LEFT_Y if stick_side == StickSide.LEFT else JOY_AXIS_RIGHT_Y
	vertical_input.axis_value = state.y
	vertical_input.device = client_index
	Input.parse_input_event(vertical_input)


func handle_button_input(client_index : int, button_index : int, state : bool) -> void:
	if button_index >= button_indices.size():
		assert(button_index < button_indices.size())
		return

	var button_input := InputEventJoypadButton.new()
	@warning_ignore("int_as_enum_without_cast")
	button_input.button_index = button_indices[button_index]
	button_input.pressed = state
	button_input.pressure = 1.0
	button_input.device = client_index
	Input.parse_input_event(button_input)
