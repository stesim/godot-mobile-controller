extends Node2D


@export var player_scene : PackedScene


@onready var _mobile_controller : MobileControllerServer = $mobile_controller

@onready var _players := $players


func _ready() -> void:
	_mobile_controller.client_added.connect(_on_client_added)
	_mobile_controller.client_removed.connect(_on_client_added)


func _on_client_added(id : int) -> void:
	var position_rect := get_viewport_rect()

	var player_instance := player_scene.instantiate()
	player_instance.name = str(id)
	player_instance.position = position_rect.position + Vector2(
		randf() * position_rect.size.x,
		randf() * position_rect.size.y,
	)
	player_instance.input_device = id
	#player_instance.launched.connect(_cycle_player.bind(player_instance))
	#player_instance.active = _players.get_child_count() == 0
	_players.add_child(player_instance)


func _on_client_removed(id : int) -> void:
	var player := _players.get_node(str(id))
	player.queue_free()

	#if player.active:
	#	_cycle_player(player)


func _cycle_player(player : Node) -> void:
	if _players.get_child_count() <= 1:
		return

	player.active = false
	var player_index := player.get_index()
	var next_player_index := (player_index + 1) % _players.get_child_count()
	var next_player := _players.get_child(next_player_index)
	next_player.active = true
