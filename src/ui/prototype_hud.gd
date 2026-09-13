class_name PrototypeHud
extends CanvasLayer

@onready var score_label: Label = $Score
@onready var state_label: Label = $State
@onready var feedback_label: Label = $Feedback
@onready var charge_bar: ProgressBar = $Charge

func _process(_delta: float) -> void:
	var gameplay_world := get_tree().get_first_node_in_group("prototype_gameplay_world")
	var player := get_tree().get_first_node_in_group("local_player") as SnowdownPlayer
	if player != null:
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
	if network_session != null:
		var net := network_session.get_debug_snapshot()
		score_label.text = "TEAM A  %d     %d  TEAM B" % [net["team_a_score"], net["team_b_score"]]
		state_label.text = "SNOWBALLS %d/%d   %s   RTT %.0f ms" % [net["inventory"], GameConfig.snowball.inventory_capacity, String(net["hand_state"]).replace("_", " ").to_upper(), net["rtt_ms"]]
		feedback_label.text = String(net["last_event"])
		charge_bar.visible = false
