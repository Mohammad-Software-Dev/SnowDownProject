extends SceneTree

const REQUIRED_ACTIONS := [
	"move_forward",
	"move_backward",
	"move_left",
	"move_right",
	"jump",
	"sprint",
	"crouch_slide",
	"pack_interact",
	"throw_primary",
	"catch",
	"scoreboard",
	"pause",
	"debug_overlay",
	"reset_test",
]

func _initialize() -> void:
	var failures: Array[String] = []
	for path in [
		"res://data/balance/player_movement.tres",
		"res://data/balance/snowball.tres",
		"res://data/balance/match_rules.tres",
	]:
		if load(path) == null:
			failures.append("config failed to load: %s" % path)

	for action in REQUIRED_ACTIONS:
		if not InputMap.has_action(action):
			failures.append("missing InputMap action: %s" % action)

	if failures.is_empty():
		print("SNOWDOWN_SMOKE_OK configs=%d actions=%d" % [3, REQUIRED_ACTIONS.size()])
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)
