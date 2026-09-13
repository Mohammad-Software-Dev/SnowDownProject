class_name DebugOverlay
extends CanvasLayer

@onready var panel: PanelContainer = $Margin/Panel
@onready var label: Label = $Margin/Panel/Padding/Label

func _ready() -> void:
	visible = not App.is_server_runtime()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("debug_overlay"):
		panel.visible = not panel.visible
	if not panel.visible:
		return

	var lines: Array[String] = [
		"Snowdown DEV",
		"role: %s" % App.runtime_role,
		"scenario: %s" % App.active_scenario,
		"fps: %d" % Engine.get_frames_per_second(),
	]

	var arena := get_tree().get_first_node_in_group("test_arena") as TestArena
	if arena != null:
		lines.append("practice score: %d" % arena.practice_score)

	var player := get_tree().get_first_node_in_group("local_player") as SnowdownPlayer
	if player != null:
		var snapshot := player.get_debug_snapshot()
		var velocity: Vector3 = snapshot["velocity"]
		var position: Vector3 = snapshot["position"]
		lines.append("")
		lines.append("locomotion: %s" % snapshot["locomotion"])
		lines.append("hand state: %s" % snapshot["hand_state"])
		lines.append("inventory: %d/%d" % [snapshot["inventory"], snapshot["inventory_capacity"]])
		lines.append("pack: %.0f%%  charge: %.0f%%" % [float(snapshot["pack_progress"]) / GameConfig.snowball.pack_duration_seconds * 100.0, float(snapshot["charge"]) * 100.0])
		lines.append("catch active: %s  last success: %s" % [snapshot["catch_active"], snapshot["last_catch_succeeded"]])
		lines.append("packable snow: %s" % snapshot["can_pack"])
		lines.append("speed: %.2f m/s" % snapshot["speed"])
		lines.append("velocity: (%.2f, %.2f, %.2f)" % [velocity.x, velocity.y, velocity.z])
		lines.append("position: (%.1f, %.1f, %.1f)" % [position.x, position.y, position.z])
		lines.append("grounded: %s" % snapshot["on_floor"])

	label.text = "\n".join(lines)
