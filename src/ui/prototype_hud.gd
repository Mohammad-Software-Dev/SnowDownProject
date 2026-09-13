class_name PrototypeHud
extends CanvasLayer

@onready var reaction_flash: ColorRect = $ReactionFlash
@onready var crosshair_label: Label = $Crosshair
@onready var score_label: Label = $Score
@onready var phase_label: Label = $Phase
@onready var connection_label: Label = $Connection
@onready var state_label: Label = $State
@onready var feedback_label: Label = $Feedback
@onready var protection_label: Label = $Protection
@onready var charge_bar: ProgressBar = $Charge

var _last_network_event: String = ""
var _network_feedback_text: String = ""
var _event_feedback_remaining: float = 0.0
var _reaction_remaining: float = 0.0
var _reaction_duration: float = 0.0

func _process(delta: float) -> void:
	_event_feedback_remaining = maxf(0.0, _event_feedback_remaining - delta)
	_reaction_remaining = maxf(0.0, _reaction_remaining - delta)
	_update_reaction_flash()

	var gameplay_world := get_tree().get_first_node_in_group("prototype_gameplay_world")
	var player := get_tree().get_first_node_in_group("local_player") as SnowdownPlayer
	if player != null:
		reaction_flash.visible = false
		phase_label.visible = false
		connection_label.visible = false
		protection_label.visible = false
		crosshair_label.visible = true
		if gameplay_world != null:
			score_label.text = "PRACTICE  %d" % int(gameplay_world.get("practice_score"))
			feedback_label.text = String(gameplay_world.get("last_feedback"))
		var snapshot := player.get_debug_snapshot()
		state_label.text = "SNOWBALLS %d/%d   %s%s" % [
			snapshot["inventory"],
			snapshot["inventory_capacity"],
			String(snapshot["hand_state"]).replace("_", " ").to_upper(),
			"   PACK SNOW [E]" if snapshot["can_pack"] and snapshot["inventory"] < snapshot["inventory_capacity"] else "",
		]
		charge_bar.value = float(snapshot["charge"]) * 100.0
		charge_bar.visible = snapshot["hand_state"] == SnowballActionComponent.THROW_CHARGING
		return

	var network_session := get_tree().get_first_node_in_group("network_session") as NetworkSession
	if network_session == null:
		reaction_flash.visible = false
		return

	phase_label.visible = true
	connection_label.visible = true
	var net := network_session.get_debug_snapshot()
	var phase := StringName(net["match_phase"])
	var time_remaining := float(net["match_time_remaining"])
	var winner_team := int(net["match_winner_team"])
	var roster := int(net["roster"])
	var expected_players := GameConfig.match_rules.team_size * 2
	var spawn_protection := float(net["spawn_protection"])
	var local_peer_id := int(net["peer_id"])

	score_label.text = "TEAM A  %d     %d  TEAM B" % [net["team_a_score"], net["team_b_score"]]
	phase_label.text = _phase_text(phase, time_remaining, winner_team, roster, expected_players)
	connection_label.text = "%s   •   RTT %.0f ms   •   %d/%d PLAYERS" % [
		String(net["state"]).replace("_", " ").to_upper(),
		float(net["rtt_ms"]),
		roster,
		expected_players,
	]
	state_label.text = "SNOWBALLS %d/%d   %s" % [
		net["inventory"],
		GameConfig.snowball.inventory_capacity,
		String(net["hand_state"]).replace("_", " ").to_upper(),
	]
	_present_network_event(String(net["last_event"]), local_peer_id)
	feedback_label.text = _network_feedback_text if _event_feedback_remaining > 0.0 else ""
	protection_label.visible = spawn_protection > 0.01
	protection_label.text = "SPAWN PROTECTION  %.1fs" % spawn_protection
	crosshair_label.visible = phase == MatchFlow.PHASE_ACTIVE or phase == MatchFlow.PHASE_SUDDEN_SNOW
	charge_bar.visible = false

	if StringName(net["state"]) == &"connection_failed":
		feedback_label.text = "CONNECTION FAILED"
	elif StringName(net["state"]) == &"server_disconnected":
		feedback_label.text = "SERVER DISCONNECTED"

func _present_network_event(event_text: String, local_peer_id: int) -> void:
	if event_text == _last_network_event:
		return
	_last_network_event = event_text
	var profile := SnowballPresentation.feedback_for_event(event_text, local_peer_id)
	_network_feedback_text = String(profile["text"])
	if _network_feedback_text.is_empty():
		_event_feedback_remaining = 0.0
	else:
		_event_feedback_remaining = 1.0 + float(int(profile["emphasis"])) * 0.18
	if bool(profile["local_reaction"]):
		_reaction_duration = 0.16 + float(int(profile["emphasis"])) * 0.045
		_reaction_remaining = _reaction_duration

func _update_reaction_flash() -> void:
	if _reaction_remaining <= 0.0 or _reaction_duration <= 0.0:
		reaction_flash.visible = false
		return
	var normalized := clampf(_reaction_remaining / _reaction_duration, 0.0, 1.0)
	reaction_flash.visible = true
	reaction_flash.color = Color(0.72, 0.9, 1.0, 0.04 + normalized * 0.10)

func _phase_text(phase: StringName, time_remaining: float, winner_team: int, roster: int, expected_players: int) -> String:
	match phase:
		MatchFlow.PHASE_WAITING:
			return "WAITING FOR PLAYERS   %d/%d" % [roster, expected_players]
		MatchFlow.PHASE_COUNTDOWN:
			return "STARTING IN %d" % maxi(1, int(ceil(time_remaining)))
		MatchFlow.PHASE_ACTIVE:
			return _format_clock(time_remaining)
		MatchFlow.PHASE_SUDDEN_SNOW:
			return "SUDDEN SNOW   •   NEXT SCORE WINS"
		MatchFlow.PHASE_RESULTS:
			if winner_team == 0:
				return "TEAM A WINS"
			if winner_team == 1:
				return "TEAM B WINS"
			return "RESULTS"
		_:
			return String(phase).replace("_", " ").to_upper()

func _format_clock(seconds: float) -> String:
	var total_seconds := maxi(0, int(ceil(seconds)))
	var minutes := total_seconds / 60
	var remainder := total_seconds % 60
	return "%02d:%02d" % [minutes, remainder]
