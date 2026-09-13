extends SceneTree

const INPUT_DEFAULTS := preload("res://src/bootstrap/input_defaults.gd")

func _init() -> void:
	INPUT_DEFAULTS.install_if_missing()

	_assert_true(_has_axis(&"move_forward", JOY_AXIS_LEFT_Y, -1.0), "left stick up moves forward")
	_assert_true(_has_axis(&"move_right", JOY_AXIS_LEFT_X, 1.0), "left stick right moves right")
	_assert_true(_has_button(&"jump", JOY_BUTTON_A), "south face button jumps")
	_assert_true(_has_button(&"crouch_slide", JOY_BUTTON_B), "east face button crouches/slides")
	_assert_true(_has_button(&"pack_interact", JOY_BUTTON_X), "west face button packs")
	_assert_true(_has_button(&"sprint", JOY_BUTTON_LEFT_STICK), "left stick click sprints")
	_assert_true(_has_axis(&"throw_primary", JOY_AXIS_TRIGGER_RIGHT, 1.0), "right trigger throws")
	_assert_true(_has_axis(&"catch", JOY_AXIS_TRIGGER_LEFT, 1.0), "left trigger catches")
	_assert_true(_has_button(&"scoreboard", JOY_BUTTON_BACK), "view/back opens scoreboard")
	_assert_true(_has_button(&"pause", JOY_BUTTON_START), "menu/start opens pause")

	_assert_equal(ControllerInputMath.shape_stick(Vector2(0.05, 0.05), 0.18), Vector2.ZERO, "right stick deadzone")
	var full := ControllerInputMath.shape_stick(Vector2(1.0, 0.0), 0.18)
	_assert_true(full.x > 0.99 and absf(full.y) < 0.001, "right stick preserves full deflection")
	var medium := ControllerInputMath.shape_stick(Vector2(0.55, 0.0), 0.18)
	_assert_true(medium.x > 0.0 and medium.x < 0.55, "right stick response is smoothly shaped")

	var config := PlayerMovementConfig.new()
	_assert_true(config.controller_look_radians_per_second > 0.0, "controller look speed is configured")
	_assert_true(config.controller_look_deadzone > 0.0 and config.controller_look_deadzone < 0.5, "controller look deadzone is sane")

	print("SNOWDOWN_CONTROLLER_INPUT_OK")
	quit(0)

func _has_axis(action: StringName, axis: JoyAxis, sign_value: float) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadMotion and event.axis == axis and signf(event.axis_value) == signf(sign_value):
			return true
	return false

func _has_button(action: StringName, button: JoyButton) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton and event.button_index == button:
			return true
	return false

func _assert_true(value: bool, label: String) -> void:
	if not value:
		push_error(label)
		quit(1)

func _assert_equal(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		push_error("%s expected=%s actual=%s" % [label, str(expected), str(actual)])
		quit(1)
