class_name MatchFlow
extends RefCounted

const PHASE_WAITING := &"waiting"
const PHASE_COUNTDOWN := &"countdown"
const PHASE_ACTIVE := &"active"
const PHASE_SUDDEN_SNOW := &"sudden_snow"
const PHASE_RESULTS := &"results"

var phase: StringName = PHASE_WAITING
var phase_time_remaining: float = 0.0
var team_a_score: int = 0
var team_b_score: int = 0
var winner_team: int = -1
var round_number: int = 0

var _required_players: int = 8
var _countdown_seconds: float = 3.0
var _regulation_seconds: float = 360.0
var _results_seconds: float = 5.0
var _sudden_snow_enabled: bool = true

func configure(required_players: int, countdown_seconds: float, regulation_seconds: float, results_seconds: float, sudden_snow_enabled: bool) -> void:
	_required_players = maxi(2, required_players)
	_countdown_seconds = maxf(0.01, countdown_seconds)
	_regulation_seconds = maxf(0.01, regulation_seconds)
	_results_seconds = maxf(0.01, results_seconds)
	_sudden_snow_enabled = sudden_snow_enabled
	reset_waiting()

func reset_waiting() -> void:
	phase = PHASE_WAITING
	phase_time_remaining = 0.0
	team_a_score = 0
	team_b_score = 0
	winner_team = -1
	round_number = 0

func tick(delta: float, player_count: int) -> bool:
	var previous_phase := phase
	match phase:
		PHASE_WAITING:
			if player_count >= _required_players:
				_begin_countdown()
		PHASE_COUNTDOWN:
			if player_count < _required_players:
				phase = PHASE_WAITING
				phase_time_remaining = 0.0
			else:
				phase_time_remaining = maxf(0.0, phase_time_remaining - delta)
				if phase_time_remaining <= 0.0:
					phase = PHASE_ACTIVE
					phase_time_remaining = _regulation_seconds
		PHASE_ACTIVE:
			phase_time_remaining = maxf(0.0, phase_time_remaining - delta)
			if phase_time_remaining <= 0.0:
				if _sudden_snow_enabled and team_a_score == team_b_score:
					phase = PHASE_SUDDEN_SNOW
					phase_time_remaining = 0.0
				else:
					_enter_results(_current_leader())
		PHASE_SUDDEN_SNOW:
			pass
		PHASE_RESULTS:
			phase_time_remaining = maxf(0.0, phase_time_remaining - delta)
			if phase_time_remaining <= 0.0:
				if player_count >= _required_players:
					_begin_countdown()
				else:
					phase = PHASE_WAITING
					phase_time_remaining = 0.0
	return previous_phase != phase

func try_score(team: int, points: int) -> bool:
	if points <= 0 or (phase != PHASE_ACTIVE and phase != PHASE_SUDDEN_SNOW):
		return false
	if team == 0:
		team_a_score += points
	elif team == 1:
		team_b_score += points
	else:
		return false
	if phase == PHASE_SUDDEN_SNOW:
		_enter_results(team)
	return true

func is_scoring_active() -> bool:
	return phase == PHASE_ACTIVE or phase == PHASE_SUDDEN_SNOW

func snapshot() -> Dictionary:
	return {
		"phase": phase,
		"time_remaining": phase_time_remaining,
		"team_a_score": team_a_score,
		"team_b_score": team_b_score,
		"winner_team": winner_team,
		"round_number": round_number,
	}

func _begin_countdown() -> void:
	team_a_score = 0
	team_b_score = 0
	winner_team = -1
	round_number += 1
	phase = PHASE_COUNTDOWN
	phase_time_remaining = _countdown_seconds

func _enter_results(winner: int) -> void:
	phase = PHASE_RESULTS
	phase_time_remaining = _results_seconds
	winner_team = winner

func _current_leader() -> int:
	if team_a_score > team_b_score:
		return 0
	if team_b_score > team_a_score:
		return 1
	return -1
