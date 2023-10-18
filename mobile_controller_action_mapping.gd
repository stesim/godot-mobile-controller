class_name MobileControllerActionMapping
extends MobileControllerMapping


@export_subgroup("Stick", "stick_")

@export var stick_left := &"ui_left"

@export var stick_right := &"ui_right"

@export var stick_up := &"ui_up"

@export var stick_down := &"ui_down"


@export_subgroup("Action Buttons", "action_button_")

@export var action_button_bottom := &"ui_accept"

@export var action_button_right := &"ui_cancel"

@export var action_button_left := &"ui_focus_next"

@export var action_button_top := &"ui_select"


func handle_stick_input(client_index : int, state : Vector2) -> void:
	_emulate_direction_action(stick_left, -minf(state.x, 0.0), client_index)
	_emulate_direction_action(stick_right, maxf(0.0, state.x), client_index)
	_emulate_direction_action(stick_up, -minf(state.y, 0.0), client_index)
	_emulate_direction_action(stick_down, maxf(0.0, state.y), client_index)


func handle_button_input(client_index : int, button_index : int, state : bool) -> void:
	var action := StringName()
	match button_index:
		0: action = action_button_bottom
		1: action = action_button_right
		2: action = action_button_left
		3: action = action_button_top
		_: return

	if action.is_empty():
		return

	var event := InputEventAction.new()
	event.action = action
	event.pressed = state
	event.strength = 1.0 if state else 0.0
	event.device = client_index
	Input.parse_input_event(event)


func _emulate_direction_action(action : StringName, strength : float, device : int) -> void:
	if action.is_empty():
		return

	var event := InputEventAction.new()
	event.action = action
	event.pressed = not is_zero_approx(strength)
	event.strength = strength
	event.device = device
	Input.parse_input_event(event)
