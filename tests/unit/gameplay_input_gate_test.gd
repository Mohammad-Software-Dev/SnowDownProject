extends SceneTree

const INPUT_DEFAULTS := preload("res://src/bootstrap/input_defaults.gd")

func _init() -> void:
	INPUT_DEFAULTS.install_if_missing()
	var original_counts: Dictionary = {}
	for action in GameplayInputGate.BLOCKED_ACTIONS:
		original_counts[action] = InputMap.action_get_events(action).size()
		_assert_true(int(original_counts[action]) > 0, "gameplay action has a binding before suppression: %s" % action)

	var pause_count := InputMap.action_get_events(&"pause").size()
	_assert_true(pause_count > 0, "pause action remains available")
	var snapshot := GameplayInputGate.suppress()
	_assert_true(GameplayInputGate.gameplay_events_are_suppressed(), "all gameplay bindings are suppressed")
	_assert_equal(InputMap.action_get_events(&"pause").size(), pause_count, "pause binding is never suppressed")

	GameplayInputGate.restore(snapshot)
	for action in GameplayInputGate.BLOCKED_ACTIONS:
		_assert_equal(InputMap.action_get_events(action).size(), int(original_counts[action]), "gameplay binding count restored: %s" % action)

	print("SNOWDOWN_GAMEPLAY_INPUT_GATE_OK")
	quit(0)

func _assert_true(value: bool, label: String) -> void:
	if not value:
		push_error(label)
		quit(1)

func _assert_equal(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		push_error("%s expected=%s actual=%s" % [label, str(expected), str(actual)])
		quit(1)
