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
	var movement := load("res://data/balance/player_movement.tres") as PlayerMovementConfig
	var snowball := load("res://data/balance/snowball.tres") as SnowballConfig
	var match_rules := load("res://data/balance/match_rules.tres") as MatchRulesConfig

	if movement == null:
		failures.append("player movement config failed to load")
	elif movement.sprint_speed <= movement.walk_speed:
		failures.append("sprint speed must exceed walk speed")

	if snowball == null:
		failures.append("snowball config failed to load")
	elif snowball.maximum_launch_speed <= snowball.minimum_launch_speed:
		failures.append("maximum launch speed must exceed minimum launch speed")

	if match_rules == null:
		failures.append("match rules config failed to load")
	elif match_rules.team_size != 4:
		failures.append("locked vertical-slice team size must be 4")

	for action in REQUIRED_ACTIONS:
		if not InputMap.has_action(action):
			failures.append("missing InputMap action: %s" % action)

	if failures.is_empty():
		print("SNOWDOWN_SMOKE_OK configs=3 actions=%d" % REQUIRED_ACTIONS.size())
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)
