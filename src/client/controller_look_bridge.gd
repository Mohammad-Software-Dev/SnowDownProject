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
	var shaped := ControllerInputMath.shape_stick(raw, GameConfig.player_movement.controller_look_deadzone)
	if shaped.is_zero_approx():
		return
	var mouse_sensitivity := maxf(0.0001, GameConfig.player_movement.mouse_sensitivity)
	var equivalent_pixels_per_second := GameConfig.player_movement.controller_look_radians_per_second / mouse_sensitivity
	var motion := InputEventMouseMotion.new()
	motion.relative = shaped * equivalent_pixels_per_second * delta
	Input.parse_input_event(motion)
