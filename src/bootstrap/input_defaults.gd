extends RefCounted

static func install_if_missing() -> void:
	_install_keys(&"move_forward", [KEY_W])
	_install_keys(&"move_backward", [KEY_S])
	_install_keys(&"move_left", [KEY_A])
	_install_keys(&"move_right", [KEY_D])
	_install_keys(&"jump", [KEY_SPACE])
	_install_keys(&"sprint", [KEY_SHIFT])
	_install_keys(&"crouch_slide", [KEY_CTRL, KEY_C])
	_install_keys(&"pack_interact", [KEY_E])
	_install_mouse_buttons(&"throw_primary", [MOUSE_BUTTON_LEFT])
	_install_mouse_buttons(&"catch", [MOUSE_BUTTON_RIGHT])
	_install_keys(&"scoreboard", [KEY_TAB])
	_install_keys(&"pause", [KEY_ESCAPE])
	_install_keys(&"debug_overlay", [KEY_F1])
	_install_keys(&"reset_test", [KEY_R])

static func _install_keys(action: StringName, keys: Array) -> void:
	_ensure_action(action)
	if not InputMap.action_get_events(action).is_empty():
		return
	for keycode in keys:
		var event := InputEventKey.new()
		event.physical_keycode = keycode
		InputMap.action_add_event(action, event)

static func _install_mouse_buttons(action: StringName, buttons: Array) -> void:
	_ensure_action(action)
	if not InputMap.action_get_events(action).is_empty():
		return
	for button_index in buttons:
		var event := InputEventMouseButton.new()
		event.button_index = button_index
		InputMap.action_add_event(action, event)

static func _ensure_action(action: StringName) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)
