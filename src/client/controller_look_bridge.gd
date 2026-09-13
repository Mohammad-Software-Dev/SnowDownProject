class_name ControllerLookBridge
extends Node

func _process(delta: float) -> void:
	if DisplayServer.get_name() == "headless" or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	var devices := Input.get_connected_joypads()
	if devices.is_empty():
		return
	var device := int(devices[0])
	var raw := Vector2(
		Input.get_joy_axis(device, JOY_AXIS_RIGHT_X),
		Input.get_joy_axis(device, JOY_AXIS_RIGHT_Y)
	)
	var shaped := shape_stick(raw, GameConfig.player_movement.controller_look_deadzone)
	if shaped.is_zero_approx():
		return
	var mouse_sensitivity := maxf(0.0001, GameConfig.player_movement.mouse_sensitivity)
	var equivalent_pixels_per_second := GameConfig.player_movement.controller_look_radians_per_second / mouse_sensitivity
	var motion := InputEventMouseMotion.new()
	motion.relative = shaped * equivalent_pixels_per_second * delta
	Input.parse_input_event(motion)

static func shape_stick(raw: Vector2, deadzone: float) -> Vector2:
	var clamped_deadzone := clampf(deadzone, 0.0, 0.95)
	var magnitude := minf(raw.length(), 1.0)
	if magnitude <= clamped_deadzone:
		return Vector2.ZERO
	var normalized := (magnitude - clamped_deadzone) / (1.0 - clamped_deadzone)
	var curved := normalized * normalized * (3.0 - 2.0 * normalized)
	return raw.normalized() * curved
