extends SceneTree

const MAP01 := preload("res://src/world/glacier_valley_layout.gd")

func _initialize() -> void:
	var failures: Array[String] = []
	var config := load("res://data/maps/glacier_valley.tres") as GlacierValleyConfig
	var movement := load("res://data/balance/player_movement.tres") as PlayerMovementConfig
	if config == null:
		failures.append("Glacier Valley config failed to load")
		_finish(failures)
		return
	if movement == null:
		failures.append("movement config failed to load")
		_finish(failures)
		return

	var long_axis := config.playable_half_length * 2.0
	var short_axis := config.playable_half_width * 2.0
	if long_axis < 100.0 or long_axis > 130.0:
		failures.append("map long axis outside locked prototype range: %.1f" % long_axis)
	if short_axis < 70.0 or short_axis > 100.0:
		failures.append("map short axis outside locked prototype range: %.1f" % short_axis)
	if config.high_shelf_height < 12.0 or config.high_shelf_height > 22.0:
		failures.append("high shelf does not provide required vertical band: %.1f" % config.high_shelf_height)

	var positions := MAP01.scenario_positions(config)
	for scenario_id in MAP01.REQUIRED_SCENARIOS:
		if not positions.has(scenario_id):
			failures.append("missing required Map 01 scenario: %s" % scenario_id)
			continue
		var scenario_position: Vector3 = positions[scenario_id]
		if MAP01.is_out_of_bounds(config, scenario_position):
			failures.append("Map 01 scenario starts out of bounds: %s" % scenario_id)

	var team_a: Vector3 = positions[&"map01_spawn_team_a"]
	var team_b: Vector3 = positions[&"map01_spawn_team_b"]
	var a_center_distance := Vector2(team_a.x, team_a.z).length()
	var b_center_distance := Vector2(team_b.x, team_b.z).length()
	if absf(a_center_distance - b_center_distance) > 0.01:
		failures.append("team spawn center distances are not symmetric")
	var center_time := a_center_distance / movement.walk_speed
	if center_time < 8.0 or center_time > 12.0:
		failures.append("normal outpost-to-center traversal estimate outside 8–12 s: %.2f" % center_time)

	if MAP01.nearest_snow_distance(config, team_a) > 15.0:
		failures.append("Team A spawn lacks nearby snow")
	if MAP01.nearest_snow_distance(config, team_b) > 15.0:
		failures.append("Team B spawn lacks nearby snow")
	var cave_deep := Vector3(config.cave_center_x, 1.0, 0.0)
	if MAP01.nearest_snow_distance(config, cave_deep) < 18.0:
		failures.append("deep cave has too-convenient snow for the locked flank tradeoff")

	_finish(failures)

func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("SNOWDOWN_MAP01_LAYOUT_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
