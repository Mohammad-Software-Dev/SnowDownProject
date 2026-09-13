class_name GameplayInputGate
extends RefCounted

const BLOCKED_ACTIONS: Array[StringName] = [
	&"move_forward",
	&"move_backward",
	&"move_left",
	&"move_right",
	&"jump",
	&"sprint",
	&"crouch_slide",
	&"pack_interact",
	&"throw_primary",
	&"catch",
	&"scoreboard",
	&"debug_overlay",
	&"reset_test",
]

static func suppress() -> Dictionary:
	var snapshot: Dictionary = {}
	for action in BLOCKED_ACTIONS:
		if not InputMap.has_action(action):
			continue
		var events := InputMap.action_get_events(action)
		snapshot[action] = events.duplicate()
		InputMap.action_erase_events(action)
		Input.action_release(action)
	return snapshot

static func restore(snapshot: Dictionary) -> void:
	for action_key in snapshot.keys():
		var action := StringName(action_key)
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.2)
		InputMap.action_erase_events(action)
		for event in Array(snapshot[action_key]):
			if event is InputEvent:
				InputMap.action_add_event(action, event)

static func gameplay_events_are_suppressed() -> bool:
	for action in BLOCKED_ACTIONS:
		if InputMap.has_action(action) and not InputMap.action_get_events(action).is_empty():
			return false
	return true
