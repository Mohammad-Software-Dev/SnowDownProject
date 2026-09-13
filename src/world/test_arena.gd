class_name TestArena
extends Node3D

const PLAYER_SCENE := preload("res://scenes/players/player.tscn")
const SNOWBALL_SCENE := preload("res://scenes/projectiles/snowball.tscn")

@onready var scenario_registry: TestScenarioRegistry = $TestScenarioRegistry
@onready var spawn_marker: Marker3D = $ScenarioSpawn
@onready var scenario_label: Label3D = $ScenarioSpawn/ScenarioLabel

var local_player: SnowdownPlayer
var practice_score: int = 0
var last_feedback: String = ""
var _feedback_remaining: float = 0.0
var _fixture_projectile_id: int = 100000

func _ready() -> void:
	add_to_group("test_arena")
	add_to_group("prototype_gameplay_world")
	_apply_scenario_marker(App.active_scenario)
	if not App.is_server_runtime():
		_spawn_local_player()
		_spawn_scenario_fixture()
	print("[Snowdown] TestArena ready. scenario=%s spawn=%s" % [App.active_scenario, spawn_marker.global_position])

func _process(delta: float) -> void:
	_feedback_remaining = maxf(0.0, _feedback_remaining - delta)
	if _feedback_remaining <= 0.0:
		last_feedback = ""

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("reset_test"):
		reset_active_scenario()
		get_viewport().set_input_as_handled()

func reset_active_scenario() -> void:
	practice_score = 0
	last_feedback = "RESET"
	_feedback_remaining = 0.75
	for projectile in get_tree().get_nodes_in_group("snowball_projectile"):
		projectile.queue_free()
	_apply_scenario_marker(App.active_scenario)
	if local_player != null:
		local_player.teleport_to(spawn_marker.global_position)
	_spawn_scenario_fixture()

func get_world_debug_snapshot() -> Dictionary:
	return {"name": "TestArena", "nearest_snow_distance": -1.0}

func _spawn_local_player() -> void:
	local_player = PLAYER_SCENE.instantiate() as SnowdownPlayer
	add_child(local_player)
	local_player.projectile_spawned.connect(_on_projectile_spawned)
	local_player.teleport_to(spawn_marker.global_position)

func _spawn_scenario_fixture() -> void:
	if App.active_scenario != &"catch_lane" or App.is_server_runtime():
		return
	var projectile := SNOWBALL_SCENE.instantiate() as SnowballProjectile
	projectile.setup(null, Vector3(12.0, 1.4, 0.0), Vector3(0.0, 6.0, 12.0), _fixture_projectile_id)
	_fixture_projectile_id += 1
	add_child(projectile)
	_on_projectile_spawned(projectile)

func _on_projectile_spawned(projectile: SnowballProjectile) -> void:
	projectile.add_to_group("snowball_projectile")
	projectile.terminal_resolved.connect(_on_projectile_terminal)

func _on_projectile_terminal(kind: StringName, _collider: Node, _world_position: Vector3) -> void:
	match kind:
		SnowballProjectile.RESULT_CAUGHT:
			last_feedback = "CATCH"
			_feedback_remaining = 1.0
		SnowballProjectile.RESULT_HEAD:
			practice_score += GameConfig.match_rules.head_hit_score
			last_feedback = "HEAD HIT +%d" % GameConfig.match_rules.head_hit_score
			_feedback_remaining = 1.0
		SnowballProjectile.RESULT_BODY:
			practice_score += GameConfig.match_rules.body_hit_score
			last_feedback = "BODY HIT +%d" % GameConfig.match_rules.body_hit_score
			_feedback_remaining = 1.0
		_:
			last_feedback = "SNOW IMPACT"
			_feedback_remaining = 0.35

func _apply_scenario_marker(scenario_id: StringName) -> void:
	spawn_marker.position = scenario_registry.get_spawn_position(scenario_id)
	scenario_label.text = String(scenario_id)
