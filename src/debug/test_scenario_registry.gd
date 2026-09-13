class_name TestScenarioRegistry
extends Node

const SCENARIOS := {
	&"test_arena_origin": Vector3(0.0, 1.0, 8.0),
	&"movement_runway": Vector3(-12.0, 1.0, 8.0),
	&"projectile_lane": Vector3(0.0, 1.0, 20.0),
	&"catch_lane": Vector3(12.0, 1.0, 8.0),
}

func has_scenario(scenario_id: StringName) -> bool:
	return SCENARIOS.has(scenario_id)

func get_spawn_position(scenario_id: StringName) -> Vector3:
	if not has_scenario(scenario_id):
		push_warning("Unknown Snowdown test scenario '%s'; falling back to origin." % scenario_id)
		return SCENARIOS[&"test_arena_origin"]
	return SCENARIOS[scenario_id]

func get_scenario_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for scenario_id in SCENARIOS.keys():
		ids.append(scenario_id)
	ids.sort()
	return ids
