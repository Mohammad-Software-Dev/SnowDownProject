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
		"world: %s" % App.active_world,
		"scenario: %s" % App.active_scenario,
		"fps: %d" % Engine.get_frames_per_second(),
	]

	var network_session := get_tree().get_first_node_in_group("network_session") as NetworkSession
	if network_session != null:
		var net := network_session.get_debug_snapshot()
		lines.append("net: %s peer=%d roster=%d" % [net["state"], net["peer_id"], net["roster"]])
		lines.append("rtt: %.1f ms  clock: %+.1f ms" % [net["rtt_ms"], net["clock_offset_ms"]])
		lines.append("reconciliations: %d  rejected: %d" % [net["reconciliations"], net["server_rejected_inputs"]])
		lines.append("network snowballs: %d predicted=%d merges=%d" % [net["projectiles"], net["predicted_projectiles"], net["prediction_merges"]])
		lines.append("server score: A %d — %d B" % [net["team_a_score"], net["team_b_score"]])
		if not String(net["last_event"]).is_empty():
			lines.append("last net event: %s" % net["last_event"])

	var gameplay_world := get_tree().get_first_node_in_group("prototype_gameplay_world")
	if gameplay_world != null:
		lines.append("practice score: %d" % int(gameplay_world.get("practice_score")))
		if gameplay_world.has_method("get_world_debug_snapshot"):
			var world_snapshot: Dictionary = gameplay_world.call("get_world_debug_snapshot")
			if world_snapshot.has("nearest_snow_distance") and float(world_snapshot["nearest_snow_distance"]) >= 0.0:
				lines.append("nearest snow: %.1f m" % float(world_snapshot["nearest_snow_distance"]))

	var player := get_tree().get_first_node_in_group("local_player") as SnowdownPlayer
	if player != null:
		var snapshot := player.get_debug_snapshot()
		var velocity: Vector3 = snapshot["velocity"]
		var position: Vector3 = snapshot["position"]
		lines.append("")
		lines.append("locomotion: %s" % snapshot["locomotion"])
		lines.append("surface: %s" % snapshot["surface"])
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
