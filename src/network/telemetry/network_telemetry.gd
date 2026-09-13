class_name NetworkTelemetry
extends RefCounted

const CENTER_HALF_LENGTH := 12.0

var round_number: int = 0
var peak_roster: int = 0
var peak_projectiles: int = 0
var team_a_roster: int = 0
var team_b_roster: int = 0
var team_a_throws: int = 0
var team_b_throws: int = 0
var terminal_counts: Dictionary = {}
var max_rejected_inputs: int = 0
var position_samples: int = 0
var team_a_center_samples: int = 0
var team_b_center_samples: int = 0
var team_a_enemy_half_samples: int = 0
var team_b_enemy_half_samples: int = 0

func reset_for_round(new_round_number: int) -> void:
	round_number = new_round_number
	peak_roster = 0
	peak_projectiles = 0
	team_a_roster = 0
	team_b_roster = 0
	team_a_throws = 0
	team_b_throws = 0
	terminal_counts.clear()
	max_rejected_inputs = 0
	position_samples = 0
	team_a_center_samples = 0
	team_b_center_samples = 0
	team_a_enemy_half_samples = 0
	team_b_enemy_half_samples = 0

func note_roster(roster: Dictionary) -> void:
	var count_a := 0
	var count_b := 0
	for raw_state in roster.values():
		var state_data := raw_state as Dictionary
		if state_data == null:
			continue
		if int(state_data.get("team", -1)) == 0:
			count_a += 1
		elif int(state_data.get("team", -1)) == 1:
			count_b += 1
	team_a_roster = count_a
	team_b_roster = count_b
	peak_roster = maxi(peak_roster, count_a + count_b)

func note_throw(team: int, concurrent_projectiles: int) -> void:
	if team == 0:
		team_a_throws += 1
	elif team == 1:
		team_b_throws += 1
	note_projectile_count(concurrent_projectiles)

func note_projectile_count(concurrent_projectiles: int) -> void:
	peak_projectiles = maxi(peak_projectiles, concurrent_projectiles)

func note_terminal(kind: StringName) -> void:
	terminal_counts[kind] = int(terminal_counts.get(kind, 0)) + 1

func note_rejected_inputs(total_rejected_inputs: int) -> void:
	max_rejected_inputs = maxi(max_rejected_inputs, total_rejected_inputs)

func sample_players(players: Array[Node]) -> void:
	if players.is_empty():
		return
	position_samples += 1
	for node in players:
		var player_node := node as Node3D
		if player_node == null:
			continue
		var raw_team := player_node.get("team_index")
		if raw_team == null:
			continue
		var team := int(raw_team)
		var z := player_node.global_position.z
		if absf(z) <= CENTER_HALF_LENGTH:
			if team == 0:
				team_a_center_samples += 1
			elif team == 1:
				team_b_center_samples += 1
		elif team == 0 and z < -CENTER_HALF_LENGTH:
			team_a_enemy_half_samples += 1
		elif team == 1 and z > CENTER_HALF_LENGTH:
			team_b_enemy_half_samples += 1

func get_snapshot() -> Dictionary:
	return {
		"round": round_number,
		"peak_roster": peak_roster,
		"peak_projectiles": peak_projectiles,
		"team_a_roster": team_a_roster,
		"team_b_roster": team_b_roster,
		"team_a_throws": team_a_throws,
		"team_b_throws": team_b_throws,
		"terminals": terminal_counts.duplicate(true),
		"max_rejected_inputs": max_rejected_inputs,
		"position_samples": position_samples,
		"team_a_center_samples": team_a_center_samples,
		"team_b_center_samples": team_b_center_samples,
		"team_a_enemy_half_samples": team_a_enemy_half_samples,
		"team_b_enemy_half_samples": team_b_enemy_half_samples,
	}

func summary(score_a: int, score_b: int) -> String:
	return "round=%d roster_peak=%d teams=%d-%d score=%d-%d throws=%d-%d projectile_peak=%d terminals=%s rejected=%d center_samples=%d-%d enemy_half=%d-%d samples=%d" % [
		round_number,
		peak_roster,
		team_a_roster,
		team_b_roster,
		score_a,
		score_b,
		team_a_throws,
		team_b_throws,
		peak_projectiles,
		str(terminal_counts),
		max_rejected_inputs,
		team_a_center_samples,
		team_b_center_samples,
		team_a_enemy_half_samples,
		team_b_enemy_half_samples,
		position_samples,
	]
