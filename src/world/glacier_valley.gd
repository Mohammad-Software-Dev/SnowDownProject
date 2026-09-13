class_name GlacierValley
extends Node3D

const PLAYER_SCENE := preload("res://scenes/players/player.tscn")
const PRACTICE_TARGET_SCENE := preload("res://scenes/world/practice_target.tscn")
const MAP01_LAYOUT := preload("res://src/world/glacier_valley_layout.gd")

const COLOR_SNOW := Color(0.78, 0.87, 0.94, 1.0)
const COLOR_ICE := Color(0.35, 0.72, 0.88, 1.0)
const COLOR_DEEP_ICE := Color(0.12, 0.46, 0.68, 1.0)
const COLOR_ROCK := Color(0.26, 0.31, 0.36, 1.0)
const COLOR_WOOD := Color(0.38, 0.24, 0.16, 1.0)
const COLOR_TEAM_A := Color(0.88, 0.36, 0.20, 1.0)
const COLOR_TEAM_B := Color(0.20, 0.48, 0.90, 1.0)

var local_player: SnowdownPlayer
var practice_score: int = 0
var last_feedback: String = ""
var _feedback_remaining: float = 0.0
var _spawn_marker: Marker3D
var _scenario_label: Label3D

func _ready() -> void:
	add_to_group("glacier_valley")
	add_to_group("prototype_gameplay_world")
	_build_graybox()
	if not App.is_server_runtime() and DisplayServer.get_name() != "headless":
		_build_visual_identity_pass()
	_build_scenario_marker()
	_apply_scenario(App.active_scenario)
	if not App.is_server_runtime():
		_spawn_practice_targets()
		if not App.is_network_runtime():
			_spawn_local_player()
		_spawn_dummy_layout_if_requested()
	print("[Snowdown] Glacier Valley graybox ready. scenario=%s spawn=%s" % [App.active_scenario, _spawn_marker.global_position])

func _process(delta: float) -> void:
	_feedback_remaining = maxf(0.0, _feedback_remaining - delta)
	if _feedback_remaining <= 0.0:
		last_feedback = ""
	if local_player != null and MAP01_LAYOUT.is_out_of_bounds(GameConfig.glacier_valley, local_player.global_position):
		_recover_from_out_of_bounds()

func _unhandled_input(event: InputEvent) -> void:
	if local_player != null and event.is_action_pressed("reset_test"):
		reset_active_scenario()
		get_viewport().set_input_as_handled()

func reset_active_scenario() -> void:
	practice_score = 0
	last_feedback = "RESET"
	_feedback_remaining = 0.75
	for projectile in get_tree().get_nodes_in_group("snowball_projectile"):
		projectile.queue_free()
	_apply_scenario(App.active_scenario)
	if local_player != null:
		_place_player_at_active_scenario()

func get_world_debug_snapshot() -> Dictionary:
	var nearest_snow := -1.0
	if local_player != null:
		nearest_snow = MAP01_LAYOUT.nearest_snow_distance(GameConfig.glacier_valley, local_player.global_position)
	return {"name": "Glacier Valley graybox", "nearest_snow_distance": nearest_snow}

func _build_graybox() -> void:
	var config := GameConfig.glacier_valley
	var width := config.playable_half_width * 2.0
	var length := config.playable_half_length * 2.0
	_add_block("ValleyFloor", Vector3(width, 1.0, length), Vector3(0.0, -0.5, 0.0), Vector3.ZERO, COLOR_SNOW)
	_add_block("FrozenRiver", Vector3(config.river_half_width * 2.0, 0.32, length - 12.0), Vector3(0.0, 0.16, 0.0), Vector3.ZERO, COLOR_ICE, &"fast_surface", 0.20)
	_add_block("WestGlacierWall", Vector3(2.0, 18.0, length), Vector3(-config.playable_half_width - 1.0, 8.5, 0.0), Vector3.ZERO, COLOR_DEEP_ICE, &"", 0.48)
	_add_block("EastGlacierWall", Vector3(2.0, 18.0, length), Vector3(config.playable_half_width + 1.0, 8.5, 0.0), Vector3.ZERO, COLOR_DEEP_ICE, &"", 0.48)
	_add_block("NorthGlacierWall", Vector3(width, 18.0, 2.0), Vector3(0.0, 8.5, config.playable_half_length + 1.0), Vector3.ZERO, COLOR_ROCK)
	_add_block("SouthGlacierWall", Vector3(width, 18.0, 2.0), Vector3(0.0, 8.5, -config.playable_half_length - 1.0), Vector3.ZERO, COLOR_ROCK)
	_build_outpost("TeamAOutpost", 1.0, COLOR_TEAM_A)
	_build_outpost("TeamBOutpost", -1.0, COLOR_TEAM_B)
	_build_glacier_arch()
	_build_cave_route()
	_build_high_shelf()
	_build_cover_rhythm()
	var snow_positions := MAP01_LAYOUT.snow_source_positions(config)
	for index in range(snow_positions.size()):
		_add_snow_source("SnowSource%02d" % index, snow_positions[index])
	if not App.is_server_runtime():
		_add_sun()
		if App.has_explicit_launch_arguments():
			_add_landmark_labels()

func _build_visual_identity_pass() -> void:
	var presenter := GlacierValleyPresenter.new()
	presenter.name = "GlacierValleyPresentation"
	presenter.configure(GameConfig.glacier_valley, MAP01_LAYOUT.snow_source_positions(GameConfig.glacier_valley))
	add_child(presenter)

func _build_outpost(prefix: String, side: float, team_color: Color) -> void:
	var config := GameConfig.glacier_valley
	var spawn_z := (config.playable_half_length - config.team_spawn_inset) * side
	var front_z := spawn_z - 5.5 * side
	_add_block(prefix + "SpawnShield", Vector3(15.0, 3.8, 1.2), Vector3(0.0, 1.9, front_z), Vector3.ZERO, team_color)
	_add_block(prefix + "LeftShelter", Vector3(1.2, 3.2, 9.0), Vector3(-10.0, 1.6, spawn_z), Vector3.ZERO, COLOR_WOOD)
	_add_block(prefix + "RightShelter", Vector3(1.2, 3.2, 9.0), Vector3(10.0, 1.6, spawn_z), Vector3.ZERO, COLOR_WOOD)
	_add_block(prefix + "RearShelter", Vector3(12.0, 3.2, 1.2), Vector3(0.0, 1.6, spawn_z + 5.0 * side), Vector3.ZERO, COLOR_WOOD)

func _build_glacier_arch() -> void:
	_add_block("GlacierArchWestPillar", Vector3(4.5, 9.0, 6.0), Vector3(-9.0, 4.5, 0.0), Vector3(0.0, 0.0, 7.0), COLOR_DEEP_ICE, &"", 0.38)
	_add_block("GlacierArchEastPillar", Vector3(4.5, 9.0, 6.0), Vector3(9.0, 4.5, 0.0), Vector3(0.0, 0.0, -7.0), COLOR_DEEP_ICE, &"", 0.38)
	_add_block("GlacierArchCrown", Vector3(22.0, 3.2, 6.0), Vector3(0.0, 9.5, 0.0), Vector3.ZERO, COLOR_ICE, &"", 0.30)

func _build_cave_route() -> void:
	var config := GameConfig.glacier_valley
	var center_x := config.cave_center_x
	var route_length := config.cave_half_length * 2.0
	_add_block("CaveOuterWall", Vector3(1.8, 6.0, route_length), Vector3(center_x - config.cave_half_width, 3.0, 0.0), Vector3.ZERO, COLOR_ROCK)
	_add_block("CaveInnerWallNorth", Vector3(1.8, 6.0, 22.0), Vector3(center_x + config.cave_half_width, 3.0, 17.0), Vector3.ZERO, COLOR_DEEP_ICE, &"", 0.40)
	_add_block("CaveInnerWallSouth", Vector3(1.8, 6.0, 22.0), Vector3(center_x + config.cave_half_width, 3.0, -17.0), Vector3.ZERO, COLOR_DEEP_ICE, &"", 0.40)
	_add_block("CaveRoof", Vector3(config.cave_half_width * 2.0, 1.0, route_length), Vector3(center_x, 5.8, 0.0), Vector3.ZERO, COLOR_DEEP_ICE, &"", 0.36)
	_add_block("CaveBendNorth", Vector3(5.0, 3.0, 2.0), Vector3(center_x - 2.0, 1.5, 12.0), Vector3(0.0, 22.0, 0.0), COLOR_ROCK)
	_add_block("CaveBendSouth", Vector3(5.0, 3.0, 2.0), Vector3(center_x + 2.0, 1.5, -12.0), Vector3(0.0, -22.0, 0.0), COLOR_ROCK)

func _build_high_shelf() -> void:
	var config := GameConfig.glacier_valley
	var x := config.high_shelf_center_x
	_add_block("HighShelf", Vector3(config.shelf_half_width * 2.0, 2.0, config.shelf_half_length * 2.0), Vector3(x, config.high_shelf_height - 1.0, 0.0), Vector3.ZERO, COLOR_ROCK)
	_add_block("HighShelfNorthRamp", Vector3(config.shelf_half_width * 2.0, 1.0, 30.0), Vector3(x, 5.7, 30.0), Vector3(23.0, 0.0, 0.0), COLOR_SNOW)
	_add_block("HighShelfSouthRamp", Vector3(config.shelf_half_width * 2.0, 1.0, 30.0), Vector3(x, 5.7, -30.0), Vector3(-23.0, 0.0, 0.0), COLOR_SNOW)
	_add_block("HighShelfSparseCover", Vector3(4.0, 2.0, 3.0), Vector3(x + 3.0, config.high_shelf_height + 1.0, -5.0), Vector3.ZERO, COLOR_DEEP_ICE, &"", 0.44)

func _build_cover_rhythm() -> void:
	_add_block("RiverCoverNorth", Vector3(6.0, 2.0, 2.4), Vector3(4.0, 1.0, 20.0), Vector3(0.0, 18.0, 0.0), COLOR_DEEP_ICE, &"", 0.44)
	_add_block("RiverCoverSouth", Vector3(6.0, 2.0, 2.4), Vector3(-4.0, 1.0, -20.0), Vector3(0.0, -18.0, 0.0), COLOR_DEEP_ICE, &"", 0.44)
	_add_block("MidSnowbankNorthWest", Vector3(9.0, 1.8, 2.5), Vector3(-14.0, 0.9, 16.0), Vector3(0.0, 28.0, 0.0), COLOR_SNOW)
	_add_block("MidSnowbankSouthEast", Vector3(9.0, 1.8, 2.5), Vector3(14.0, 0.9, -16.0), Vector3(0.0, -28.0, 0.0), COLOR_SNOW)
	_add_block("ArchCounterNorthEast", Vector3(5.0, 3.0, 4.0), Vector3(17.0, 1.5, 10.0), Vector3(0.0, 15.0, 0.0), COLOR_ROCK)
	_add_block("ArchCounterSouthWest", Vector3(5.0, 3.0, 4.0), Vector3(-17.0, 1.5, -10.0), Vector3(0.0, -15.0, 0.0), COLOR_ROCK)
	_add_block("BrokenGlacierA", Vector3(5.0, 5.5, 5.0), Vector3(20.0, 2.75, 25.0), Vector3(0.0, 18.0, 5.0), COLOR_DEEP_ICE, &"", 0.42)
	_add_block("BrokenGlacierB", Vector3(4.0, 3.8, 7.0), Vector3(18.0, 1.9, -28.0), Vector3(0.0, -24.0, 0.0), COLOR_DEEP_ICE, &"", 0.42)

func _add_block(name: String, size: Vector3, position: Vector3, rotation: Vector3, color: Color, group_name: StringName = &"", roughness: float = 0.9) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = name
	body.position = position
	body.rotation_degrees = rotation
	body.collision_layer = 1
	body.collision_mask = 0
	if not group_name.is_empty():
		body.add_to_group(group_name)
	add_child(body)
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	if not App.is_server_runtime():
		var box := BoxMesh.new()
		box.size = size
		var mesh := MeshInstance3D.new()
		mesh.mesh = box
		mesh.material_override = _make_material(color, roughness)
		body.add_child(mesh)
	return body

func _add_snow_source(source_name: String, position: Vector3) -> void:
	var source := Area3D.new()
	source.name = source_name
	source.position = position
	source.collision_layer = 8
	source.collision_mask = 0
	source.add_to_group("snow_source")
	add_child(source)
	var shape := BoxShape3D.new()
	shape.size = Vector3(5.0, 0.8, 5.0)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	source.add_child(collision)
	if not App.is_server_runtime():
		var box := BoxMesh.new()
		box.size = Vector3(5.0, 0.25, 5.0)
		var mesh := MeshInstance3D.new()
		mesh.mesh = box
		mesh.material_override = _make_material(Color(0.94, 0.98, 1.0, 1.0), 1.0)
		source.add_child(mesh)

func _build_scenario_marker() -> void:
	_spawn_marker = Marker3D.new()
	_spawn_marker.name = "ScenarioSpawn"
	add_child(_spawn_marker)
	if not App.is_server_runtime():
		_scenario_label = Label3D.new()
		_scenario_label.position = Vector3(0.0, 2.4, 0.0)
		_scenario_label.billboard = 1
		_scenario_label.font_size = 28
		_scenario_label.outline_size = 8
		_spawn_marker.add_child(_scenario_label)

func _apply_scenario(scenario_id: StringName) -> void:
	_spawn_marker.position = MAP01_LAYOUT.spawn_for(GameConfig.glacier_valley, scenario_id)
	if _scenario_label != null:
		_scenario_label.text = String(scenario_id)

func _spawn_local_player() -> void:
	local_player = PLAYER_SCENE.instantiate() as SnowdownPlayer
	add_child(local_player)
	local_player.projectile_spawned.connect(_on_projectile_spawned)
	_place_player_at_active_scenario()

func _place_player_at_active_scenario() -> void:
	local_player.teleport_to(_spawn_marker.global_position)
	local_player.orient_to_yaw_degrees(MAP01_LAYOUT.spawn_yaw_degrees(App.active_scenario))

func _spawn_practice_targets() -> void:
	var targets := [Vector3(0.0, 0.25, 0.0), Vector3(5.0, 0.25, -24.0), Vector3(-12.0, 0.25, 24.0)]
	for index in range(targets.size()):
		var target := PRACTICE_TARGET_SCENE.instantiate()
		target.name = "MapPracticeTarget%02d" % index
		target.position = targets[index]
		add_child(target)

func _spawn_dummy_layout_if_requested() -> void:
	if App.active_scenario != &"map01_4v4_bot_or_dummy_layout_test" or App.is_network_runtime():
		return
	var positions := [
		Vector3(-5.0, 0.9, 46.0), Vector3(5.0, 0.9, 46.0), Vector3(-13.0, 0.9, 30.0), Vector3(13.0, 0.9, 30.0),
		Vector3(-5.0, 0.9, -46.0), Vector3(5.0, 0.9, -46.0), Vector3(-13.0, 0.9, -30.0), Vector3(13.0, 0.9, -30.0),
	]
	for index in range(positions.size()):
		var dummy := MeshInstance3D.new()
		dummy.name = "TeamLayoutDummy%02d" % index
		dummy.position = positions[index]
		var mesh := CapsuleMesh.new()
		mesh.radius = 0.42
		mesh.height = 1.8
		dummy.mesh = mesh
		dummy.material_override = _make_material(COLOR_TEAM_A if index < 4 else COLOR_TEAM_B)
		add_child(dummy)

func _recover_from_out_of_bounds() -> void:
	_place_player_at_active_scenario()
	last_feedback = "OUT OF BOUNDS — RETURNED"
	_feedback_remaining = 1.25

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

func _add_sun() -> void:
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-52.0, -28.0, 0.0)
	sun.light_color = Color(0.88, 0.95, 1.0, 1.0)
	sun.light_energy = 1.28
	sun.shadow_enabled = true
	add_child(sun)

func _add_landmark_labels() -> void:
	_add_label("GLACIER ARCH", Vector3(0.0, 12.0, 0.0))
	_add_label("FROZEN RIVER", Vector3(0.0, 2.5, 25.0))
	_add_label("BLUE ICE CAVE", Vector3(GameConfig.glacier_valley.cave_center_x, 7.0, 0.0))
	_add_label("HIGH SHELF", Vector3(GameConfig.glacier_valley.high_shelf_center_x, GameConfig.glacier_valley.high_shelf_height + 4.0, 0.0))

func _add_label(text_value: String, position: Vector3) -> void:
	var label := Label3D.new()
	label.text = text_value
	label.position = position
	label.billboard = 1
	label.font_size = 28
	label.outline_size = 8
	add_child(label)

func _make_material(color: Color, roughness: float = 0.9) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material
