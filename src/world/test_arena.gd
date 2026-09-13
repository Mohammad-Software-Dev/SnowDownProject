class_name TestArena
extends Node3D

const PLAYER_SCENE := preload("res://scenes/players/player.tscn")

@onready var scenario_registry: TestScenarioRegistry = $TestScenarioRegistry
@onready var spawn_marker: Marker3D = $ScenarioSpawn
@onready var scenario_label: Label3D = $ScenarioSpawn/ScenarioLabel

var local_player: SnowdownPlayer

func _ready() -> void:
	_apply_scenario_marker(App.active_scenario)
	if not App.is_server_runtime():
		_spawn_local_player()
	print("[Snowdown] TestArena ready. scenario=%s spawn=%s" % [App.active_scenario, spawn_marker.global_position])

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("reset_test"):
		reset_active_scenario()
		get_viewport().set_input_as_handled()

func reset_active_scenario() -> void:
	_apply_scenario_marker(App.active_scenario)
	if local_player != null:
		local_player.teleport_to(spawn_marker.global_position)

func _spawn_local_player() -> void:
	local_player = PLAYER_SCENE.instantiate() as SnowdownPlayer
	add_child(local_player)
	local_player.teleport_to(spawn_marker.global_position)

func _apply_scenario_marker(scenario_id: StringName) -> void:
	spawn_marker.position = scenario_registry.get_spawn_position(scenario_id)
	scenario_label.text = String(scenario_id)
