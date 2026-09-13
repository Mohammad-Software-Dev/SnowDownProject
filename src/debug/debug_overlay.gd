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

	var movement_config := GameConfig.player_movement
	var snowball := GameConfig.snowball
	var match_rules := GameConfig.match_rules
	var lines: Array[String] = [
		"Snowdown DEV",
		"role: %s" % App.runtime_role,
		"scenario: %s" % App.active_scenario,
		"fps: %d" % Engine.get_frames_per_second(),
		"",
		"walk/sprint: %.1f / %.1f" % [movement_config.walk_speed, movement_config.sprint_speed],
		"snowball capacity: %d" % snowball.inventory_capacity,
		"throw speed: %.1f -> %.1f m/s" % [snowball.minimum_launch_speed, snowball.maximum_launch_speed],
		"match: %dv%d / %.0fs" % [match_rules.team_size, match_rules.team_size, match_rules.regulation_seconds],
	]

	var player := get_tree().get_first_node_in_group("local_player")
	if player != null and player.has_method("get_debug_snapshot"):
		var snapshot: Dictionary = player.get_debug_snapshot()
		var velocity: Vector3 = snapshot["velocity"]
		var position: Vector3 = snapshot["position"]
		lines.append("")
		lines.append("locomotion: %s" % snapshot["locomotion"])
		lines.append("speed: %.2f m/s" % snapshot["speed"])
		lines.append("velocity: (%.2f, %.2f, %.2f)" % [velocity.x, velocity.y, velocity.z])
		lines.append("position: (%.1f, %.1f, %.1f)" % [position.x, position.y, position.z])
		lines.append("grounded: %s" % snapshot["on_floor"])

	label.text = "\n".join(lines)
