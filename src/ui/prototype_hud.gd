class_name PrototypeHud
extends CanvasLayer

@onready var score_label: Label = $Score
@onready var state_label: Label = $State
@onready var feedback_label: Label = $Feedback
@onready var charge_bar: ProgressBar = $Charge

func _process(_delta: float) -> void:
	var gameplay_world := get_tree().get_first_node_in_group("prototype_gameplay_world")
	var player := get_tree().get_first_node_in_group("local_player") as SnowdownPlayer
	if gameplay_world != null:
		score_label.text = "PRACTICE  %d" % int(gameplay_world.get("practice_score"))
		feedback_label.text = String(gameplay_world.get("last_feedback"))
	if player == null:
		return
	var snapshot := player.get_debug_snapshot()
	state_label.text = "SNOWBALLS %d/%d   %s%s" % [
		snapshot["inventory"],
		snapshot["inventory_capacity"],
		String(snapshot["hand_state"]).replace("_", " ").to_upper(),
		"   PACK SNOW [E]" if snapshot["can_pack"] and snapshot["inventory"] < snapshot["inventory_capacity"] else "",
	]
	charge_bar.value = float(snapshot["charge"]) * 100.0
	charge_bar.visible = snapshot["hand_state"] == SnowballActionComponent.THROW_CHARGING
