class_name TestArena
extends Node3D

@onready var scenario_registry: TestScenarioRegistry = $TestScenarioRegistry
@onready var spawn_marker: Marker3D = $ScenarioSpawn
@onready var scenario_label: Label3D = $ScenarioSpawn/ScenarioLabel

func _ready() -> void:
	_apply_scenario(App.active_scenario)
	print("[Snowdown] TestArena ready. scenario=%s spawn=%s" % [App.active_scenario, spawn_marker.global_position])

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("reset_test"):
		_apply_scenario(App.active_scenario)
		get_viewport().set_input_as_handled()

func _apply_scenario(scenario_id: StringName) -> void:
	spawn_marker.position = scenario_registry.get_spawn_position(scenario_id)
	scenario_label.text = String(scenario_id)
