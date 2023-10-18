extends RigidBody2D


signal launched()


@export var color := Color.WHITE_SMOKE

@export var launch_impulse := 256.0

@export var push_impulse := 256.0

@export var push_radius := 256.0

@export var active := true :
	set(value):
		active = value
		if is_inside_tree():
			set_process(active)
			set_physics_process(active)
			set_process_unhandled_input(active)
			_pivot.visible = active

@export var input_device := 0


var _strength := -1.0


@onready var _pivot : Node2D = $pivot

@onready var _strength_indicator : Line2D = $pivot/strength_indicator


func _ready() -> void:
	add_to_group(&"characters")
	active = active


func _process(_delta: float) -> void:
	var direction := Vector2(
		Input.get_joy_axis(input_device, JOY_AXIS_LEFT_X),
		Input.get_joy_axis(input_device, JOY_AXIS_LEFT_Y),
	).normalized()
	if not direction.is_zero_approx():
		_pivot.global_rotation = direction.angle()


func _physics_process(delta : float) -> void:
	if _strength >= 0.0:
		_strength = minf(_strength + delta, 1.0)
		_strength_indicator.set_point_position(1, Vector2(_strength * launch_impulse, 0.0))


func _unhandled_input(event : InputEvent) -> void:
	if not event is InputEventJoypadButton or event.device != input_device:
		return

	if event.button_index == JOY_BUTTON_A:
		if event.is_pressed():
			_start_charging()
		else:
			_launch()

	if event.button_index == JOY_BUTTON_B and event.pressed:
		_push()


func _start_charging() -> void:
	_strength_indicator.set_point_position(1, Vector2.ZERO)
	_strength_indicator.show()
	_strength = 0.0


func _launch() -> void:
	if _strength < 0.0:
		return

	_strength_indicator.hide()
	var direction := _pivot.global_transform.x
	apply_central_impulse(_strength * launch_impulse * direction)
	_strength = -1.0
	launched.emit()


func _push() -> void:
	for character in get_tree().get_nodes_in_group(&"characters"):
		var distance := global_position.distance_to(character.global_position)
		if character != self and distance < push_radius:
			var direction := global_position.direction_to(character.global_position)
			var fall_off := remap(distance, 0.0, push_radius, 1.0, 0.0)
			var impulse := fall_off * push_impulse * direction
			character.apply_central_impulse(impulse)


func _draw() -> void:
	draw_circle(Vector2.ZERO, $shape.shape.radius, color)
