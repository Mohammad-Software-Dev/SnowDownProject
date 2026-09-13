class_name NetworkMatchCoordinator
extends Node

var phase: StringName = MatchFlow.PHASE_WAITING
var time_remaining: float = 0.0
var round_number: int = 0
var winner_team: int = -1
var team_a_score: int = 0
var team_b_score: int = 0

var _session: NetworkSession
var _flow: MatchFlow
var _sync_elapsed: float = 0.0
var _smoke_sudden_elapsed: float = 0.0
var _client_saw_sudden: bool = false
var _client_saw_results: bool = false

func configure(session: NetworkSession) -> void:
	_session = session
	add_to_group("network_match")
	if App.is_server_runtime():
		_flow = MatchFlow.new()
		var required_players := GameConfig.match_rules.team_size * 2
		var countdown := GameConfig.match_rules.countdown_seconds
		var regulation := GameConfig.match_rules.regulation_seconds
		var results := GameConfig.match_rules.results_seconds
		if App.match_smoke_enabled:
			required_players = 2
			countdown = 0.25
			regulation = 0.55
			results = 0.25
		_flow.configure(required_players, countdown, regulation, results, GameConfig.match_rules.sudden_snow_enabled)
		_copy_server_state()

func _process(delta: float) -> void:
	if not App.is_server_runtime() or _flow == null:
		return
	var previous_phase := _flow.phase
	var previous_round := _flow.round_number
	_flow.tick(delta, get_tree().get_nodes_in_group("network_server_player").size())
	if _flow.phase == MatchFlow.PHASE_SUDDEN_SNOW and App.match_smoke_enabled:
		_smoke_sudden_elapsed += delta
		if _smoke_sudden_elapsed >= 0.12:
			var before_score_phase := _flow.phase
			_flow.try_score(0, 1)
			if before_score_phase != _flow.phase:
				_handle_phase_transition(before_score_phase, _flow.phase)
	else:
		_smoke_sudden_elapsed = 0.0
	if previous_phase != _flow.phase:
		_handle_phase_transition(previous_phase, _flow.phase)
	elif previous_round != _flow.round_number:
		_handle_phase_transition(previous_phase, _flow.phase)
	_copy_server_state()
	_sync_elapsed += delta
	if _sync_elapsed >= 0.10:
		_sync_elapsed = 0.0
		_broadcast_state(false)

func server_resolve_scoring(owner_peer_id: int, target_peer_id: int, kind: StringName) -> StringName:
	if not App.is_server_runtime() or _flow == null:
		return kind
	if kind != NetworkSnowballProjectile.RESULT_BODY and kind != NetworkSnowballProjectile.RESULT_HEAD:
		return kind
	var owner := _session.server_get_player(owner_peer_id)
	var target := _session.server_get_player(target_peer_id)
	if owner == null or target == null:
		return kind
	if target.server_is_spawn_protected():
		return &"protected_impact"
	if owner.team_index == target.team_index or not _flow.is_scoring_active():
		return kind
	var points := GameConfig.match_rules.head_hit_score if kind == NetworkSnowballProjectile.RESULT_HEAD else GameConfig.match_rules.body_hit_score
	var previous_phase := _flow.phase
	if _flow.try_score(owner.team_index, points):
		_copy_server_state()
		if previous_phase != _flow.phase:
			_handle_phase_transition(previous_phase, _flow.phase)
		_broadcast_state(true)
	return kind

func server_note_offensive_action(player: NetworkPlayer) -> void:
	if App.is_server_runtime() and player != null:
		player.server_clear_spawn_protection()

func get_debug_snapshot() -> Dictionary:
	return {
		"phase": phase,
		"time_remaining": time_remaining,
		"round_number": round_number,
		"winner_team": winner_team,
		"team_a_score": team_a_score,
		"team_b_score": team_b_score,
	}

@rpc("authority", "call_remote", "unreliable")
func client_match_state(new_phase: StringName, new_time_remaining: float, new_round_number: int, new_winner_team: int, score_a: int, score_b: int) -> void:
	if App.is_server_runtime():
		return
	phase = new_phase
	time_remaining = maxf(0.0, new_time_remaining)
	round_number = new_round_number
	winner_team = new_winner_team
	team_a_score = score_a
	team_b_score = score_b
	if _session != null:
		_session.team_a_score = score_a
		_session.team_b_score = score_b
	if phase == MatchFlow.PHASE_SUDDEN_SNOW:
		_client_saw_sudden = true
	elif phase == MatchFlow.PHASE_RESULTS:
		_client_saw_results = true
	if App.network_smoke_action == &"match_observe" and round_number >= 2 and _client_saw_sudden and _client_saw_results:
		print("SNOWDOWN_MATCH_LOOP_OK name=%s round=%d phase=%s score_a=%d score_b=%d" % [App.network_smoke_name, round_number, phase, team_a_score, team_b_score])
		get_tree().quit(0)

func _handle_phase_transition(previous_phase: StringName, next_phase: StringName) -> void:
	if previous_phase == next_phase and next_phase != MatchFlow.PHASE_COUNTDOWN:
		return
	match next_phase:
		MatchFlow.PHASE_COUNTDOWN:
			_session.server_clear_all_projectiles(&"round_reset")
			_session.server_reset_roster_for_round()
		MatchFlow.PHASE_ACTIVE:
			_session.server_clear_all_projectiles(&"match_start")
			_session.server_grant_spawn_protection_all(GameConfig.match_rules.spawn_protection_seconds)
		MatchFlow.PHASE_SUDDEN_SNOW:
			_session.server_clear_all_projectiles(&"sudden_snow")
		MatchFlow.PHASE_RESULTS:
			_session.server_clear_all_projectiles(&"round_end")
	_copy_server_state()
	_broadcast_state(true)
	print("SNOWDOWN_MATCH_PHASE from=%s to=%s round=%d score=%d-%d winner=%d" % [previous_phase, next_phase, round_number, team_a_score, team_b_score, winner_team])

func _copy_server_state() -> void:
	if _flow == null:
		return
	phase = _flow.phase
	time_remaining = _flow.phase_time_remaining
	round_number = _flow.round_number
	winner_team = _flow.winner_team
	team_a_score = _flow.team_a_score
	team_b_score = _flow.team_b_score
	if _session != null:
		_session.team_a_score = team_a_score
		_session.team_b_score = team_b_score

func _broadcast_state(reliable: bool) -> void:
	if not App.is_server_runtime():
		return
	if reliable:
		client_match_state.rpc(phase, time_remaining, round_number, winner_team, team_a_score, team_b_score)
	else:
		client_match_state.rpc(phase, time_remaining, round_number, winner_team, team_a_score, team_b_score)
