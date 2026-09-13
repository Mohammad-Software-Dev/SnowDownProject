class_name TestScenarioRegistry
extends Node

const MAP01_LAYOUT := preload("res://src/world/glacier_valley_layout.gd")
const BASE_SCENARIOS := {
	&"test_arena_origin": Vector3(0.0, 1.0, 8.0),
	&"movement_runway": Vector3(-12.0, 1.0, 8.0),
	&"projectile_lane": Vector3(0.0, 1.0, 20.0),
	&"catch_lane": Vector3(12.0, 1.0, 8.0),
}

func has_scenario(scenario_id: StringName) -> bool:
	return BASE_SCENARIOS.has(scenario_id) or MAP01_LAYOUT.has_scenario(GameConfig.glacier_valley, scenario_id)

func get_spawn_position(scenario_id: StringName) -> Vector3:
	if BASE_SCENARIOS.has(scenario_id):
		return BASE_SCENARIOS[scenario_id]
	if MAP01_LAYOUT.has_scenario(GameConfig.glacier_valley, scenario_id):
		return MAP01_LAYOUT.spawn_for(GameConfig.glacier_valley, scenario_id)
	push_warning("Unknown Snowdown test scenario '%s'; falling back to origin." % scenario_id)
	return BASE_SCENARIOS[&"test_arena_origin"]

func get_scenario_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for scenario_id in BASE_SCENARIOS.keys():
		ids.append(scenario_id)
	for scenario_id in MAP01_LAYOUT.REQUIRED_SCENARIOS:
		ids.append(scenario_id)
	ids.sort()
	return ids
