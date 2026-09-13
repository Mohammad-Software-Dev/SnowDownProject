class_name GlacierValleyLayout
extends RefCounted

const REQUIRED_SCENARIOS: Array[StringName] = [
	&"map01_spawn_team_a",
	&"map01_spawn_team_b",
	&"map01_center_arch",
	&"map01_frozen_river",
	&"map01_cave_entry_a",
	&"map01_cave_entry_b",
	&"map01_high_shelf",
	&"map01_long_throw_lane",
	&"map01_snow_source_test",
	&"map01_out_of_bounds",
	&"map01_4v4_bot_or_dummy_layout_test",
]

static func scenario_positions(config: GlacierValleyConfig) -> Dictionary:
	var spawn_z := config.playable_half_length - config.team_spawn_inset
	return {
		&"map01_spawn_team_a": Vector3(0.0, 1.15, spawn_z),
		&"map01_spawn_team_b": Vector3(0.0, 1.15, -spawn_z),
		&"map01_center_arch": Vector3(0.0, 1.15, 7.0),
		&"map01_frozen_river": Vector3(0.0, 1.15, 20.0),
		&"map01_cave_entry_a": Vector3(config.cave_center_x, 1.15, config.cave_half_length - 3.0),
		&"map01_cave_entry_b": Vector3(config.cave_center_x, 1.15, -config.cave_half_length + 3.0),
		&"map01_high_shelf": Vector3(config.high_shelf_center_x, config.high_shelf_height + 1.15, 0.0),
		&"map01_long_throw_lane": Vector3(0.0, 1.15, 34.0),
		&"map01_snow_source_test": Vector3(14.0, 1.15, 0.0),
		&"map01_out_of_bounds": Vector3(config.playable_half_width - 2.0, 1.15, config.playable_half_length - 5.0),
		&"map01_4v4_bot_or_dummy_layout_test": Vector3(0.0, 1.15, 12.0),
	}

static func snow_source_positions(config: GlacierValleyConfig) -> Array[Vector3]:
	var spawn_z := config.playable_half_length - config.team_spawn_inset
	return [
		Vector3(-10.0, 0.35, spawn_z - 2.0),
		Vector3(10.0, 0.35, spawn_z - 2.0),
		Vector3(-10.0, 0.35, -spawn_z + 2.0),
		Vector3(10.0, 0.35, -spawn_z + 2.0),
		Vector3(0.0, 0.35, 14.0),
		Vector3(0.0, 0.35, -14.0),
		Vector3(16.0, 0.35, 0.0),
		Vector3(config.cave_center_x + 2.0, 0.35, config.cave_half_length + 2.0),
		Vector3(config.cave_center_x + 2.0, 0.35, -config.cave_half_length - 2.0),
		Vector3(config.high_shelf_center_x, config.high_shelf_height + 0.35, 8.0),
	]

static func has_scenario(config: GlacierValleyConfig, scenario_id: StringName) -> bool:
	return scenario_positions(config).has(scenario_id)

static func spawn_for(config: GlacierValleyConfig, scenario_id: StringName) -> Vector3:
	var positions := scenario_positions(config)
	if not positions.has(scenario_id):
		return positions[&"map01_spawn_team_a"]
	return positions[scenario_id]

static func spawn_yaw_degrees(scenario_id: StringName) -> float:
	match scenario_id:
		&"map01_spawn_team_b", &"map01_cave_entry_b":
			return 180.0
		&"map01_high_shelf":
			return 90.0
		_:
			return 0.0

static func is_out_of_bounds(config: GlacierValleyConfig, position: Vector3) -> bool:
	return absf(position.x) > config.playable_half_width \
		or absf(position.z) > config.playable_half_length \
		or position.y < config.out_of_bounds_floor_y \
		or position.y > config.high_shelf_height + 18.0

static func nearest_snow_distance(config: GlacierValleyConfig, position: Vector3) -> float:
	var nearest := INF
	for source_position in snow_source_positions(config):
		nearest = minf(nearest, position.distance_to(source_position))
	return nearest
