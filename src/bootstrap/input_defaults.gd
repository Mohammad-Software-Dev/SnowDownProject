extends RefCounted

static func install_if_missing() -> void:
	_install_key_and_axis(&"move_forward", [KEY_W], JOY_AXIS_LEFT_Y, -1.0)
	_install_key_and_axis(&"move_backward", [KEY_S], JOY_AXIS_LEFT_Y, 1.0)
	_install_key_and_axis(&"move_left", [KEY_A], JOY_AXIS_LEFT_X, -1.0)
	_install_key_and_axis(&"move_right", [KEY_D], JOY_AXIS_LEFT_X, 1.0)
	_install_key_and_button(&"jump", [KEY_SPACE], JOY_BUTTON_A)
	_install_key_and_button(&"sprint", [KEY_SHIFT], JOY_BUTTON_LEFT_STICK)
	_install_key_and_button(&"crouch_slide", [KEY_CTRL, KEY_C], JOY_BUTTON_B)
	_install_key_and_button(&"pack_interact", [KEY_E], JOY_BUTTON_X)
	_install_mouse_and_trigger(&"throw_primary", MOUSE_BUTTON_LEFT, JOY_AXIS_TRIGGER_RIGHT)
	_install_mouse_and_trigger(&"catch", MOUSE_BUTTON_RIGHT, JOY_AXIS_TRIGGER_LEFT)
	_install_key_and_button(&"scoreboard", [KEY_TAB], JOY_BUTTON_BACK)
	_install_key_and_button(&"pause", [KEY_ESCAPE], JOY_BUTTON_START)
	_install_keys_only(&"debug_overlay", [KEY_F1])
	_install_keys_only(&"reset_test", [KEY_R])

static func _install_key_and_axis(action: StringName, keys: Array, axis: JoyAxis, axis_value: float) -> void:
	_ensure_action(action)
	if not InputMap.action_get_events(action).is_empty():
		return
	_add_keys(action, keys)
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = axis_value
	InputMap.action_add_event(action, event)

static func _install_key_and_button(action: StringName, keys: Array, button: JoyButton) -> void:
	_ensure_action(action)
	if not InputMap.action_get_events(action).is_empty():
		return
	_add_keys(action, keys)
	var event := InputEventJoypadButton.new()
	event.button_index = button
	InputMap.action_add_event(action, event)

static func _install_mouse_and_trigger(action: StringName, mouse_button: MouseButton, trigger_axis: JoyAxis) -> void:
	_ensure_action(action)
	if not InputMap.action_get_events(action).is_empty():
		return
	var mouse_event := InputEventMouseButton.new()
	mouse_event.button_index = mouse_button
	InputMap.action_add_event(action, mouse_event)
	var trigger_event := InputEventJoypadMotion.new()
	trigger_event.axis = trigger_axis
	trigger_event.axis_value = 1.0
	InputMap.action_add_event(action, trigger_event)

static func _install_keys_only(action: StringName, keys: Array) -> void:
	_ensure_action(action)
	if not InputMap.action_get_events(action).is_empty():
		return
	_add_keys(action, keys)

static func _add_keys(action: StringName, keys: Array) -> void:
	for keycode in keys:
		var event := InputEventKey.new()
		event.physical_keycode = keycode
		InputMap.action_add_event(action, event)

static func _ensure_action(action: StringName) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)
