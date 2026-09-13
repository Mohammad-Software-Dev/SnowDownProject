extends SceneTree

class FakeTelemetryPlayer:
	extends Node3D
	var team_index: int = 0

func _init() -> void:
	var telemetry := NetworkTelemetry.new()
	telemetry.reset_for_round(3)
	telemetry.note_roster({
		10: {"team": 0}, 11: {"team": 0}, 12: {"team": 0}, 13: {"team": 0},
		20: {"team": 1}, 21: {"team": 1}, 22: {"team": 1}, 23: {"team": 1},
	})
	_assert_equal(telemetry.peak_roster, 8, "peak roster")
	_assert_equal(telemetry.team_a_roster, 4, "team A roster")
	_assert_equal(telemetry.team_b_roster, 4, "team B roster")

	telemetry.note_throw(0, 1)
	telemetry.note_throw(0, 2)
	telemetry.note_throw(1, 3)
	telemetry.note_throw(1, 4)
	telemetry.note_terminal(&"body_hit")
	telemetry.note_terminal(&"body_hit")
	telemetry.note_terminal(&"world_impact")
	telemetry.note_rejected_inputs(2)
	telemetry.note_rejected_inputs(1)

	var team_a := FakeTelemetryPlayer.new()
	team_a.team_index = 0
	team_a.position = Vector3(0.0, 1.0, 0.0)
	var team_b := FakeTelemetryPlayer.new()
	team_b.team_index = 1
	team_b.position = Vector3(0.0, 1.0, 20.0)
	var players: Array[Node] = [team_a, team_b]
	telemetry.sample_players(players)

	var snapshot := telemetry.get_snapshot()
	_assert_equal(int(snapshot["round"]), 3, "round")
	_assert_equal(int(snapshot["team_a_throws"]), 2, "team A throws")
	_assert_equal(int(snapshot["team_b_throws"]), 2, "team B throws")
	_assert_equal(int(snapshot["peak_projectiles"]), 4, "peak projectiles")
	_assert_equal(int(snapshot["max_rejected_inputs"]), 2, "rejected high-water")
	_assert_equal(int(snapshot["team_a_center_samples"]), 1, "team A center occupancy")
	_assert_equal(int(snapshot["team_b_enemy_half_samples"]), 1, "team B enemy-half occupancy")
	_assert_equal(int(Dictionary(snapshot["terminals"]).get(&"body_hit", 0)), 2, "body terminals")

	players.clear()
	team_a.free()
	team_b.free()
	print("SNOWDOWN_NETWORK_TELEMETRY_OK")
	quit(0)

func _assert_equal(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		push_error("%s expected=%s actual=%s" % [label, str(expected), str(actual)])
		quit(1)
